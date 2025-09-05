# NFT拍卖市场
## 1. 项目概述
- NFT 拍卖（ETH / ERC20 出价）
- Chainlink 价格预言机（ETH、ERC20 折算 USD）
- UUPS 可升级逻辑
- 工厂模式批量管理拍卖实例
- （扩展）跨链广播 / CCIP 集成（MockRouter 测试）
- 动态手续费（可扩展）
- 单实例或“未来实例”两类升级路径

---

## 2. 项目结构

```
task3/
  contracts/
    NFTAuction.sol                # 拍卖核心逻辑 (UUPS)
    NFTAuctionV2.sol              # 升级示例 (追加变量/函数)
    NftAuctionFactory.sol         # 工厂（创建 ERC1967Proxy 指向实现）
    mocks/
      MockERC20.sol
      MockRouter.sol
      MockRemoteFactory.sol
      MaliciousBidder.sol
  deploy/ or ignition/modules/
    deploy_nft_auction.js / 00_deploy_nft_auction.js   # 部署脚本（实现 + 工厂代理）
    upgrade_nft_auction.js / upgrade_auction_impl.js   # 升级逻辑实现引用（影响新实例）
    upgrade_factory.js                                 # 升级工厂自身(UUPS)
    upgrade_single_auction.js                          # 升级单个拍卖实例(若是代理)
  scripts/
    （可选辅助执行）
  test/
    helpers/time.js
    01.NFTAuction.core.test.js
    02.NFTAuction.bidding.test.js
    03.NFTAuction.upgrade.test.js
    04.NFTAuctionFactory.test.js
    05.CrossChainBroadcast.test.js
    06.SingleAuctionUpgrade.test.js (可选)
  .env.example
  hardhat.config.js
  README.md
```

---

## 3. 合约说明

### 3.1 NFTAuction.sol
- 角色：单场拍卖逻辑（可被代理）
- 主要状态：
  - auctions[id] (结构：seller/startPrice/duration/highestBid/最高出价者/是否结束/支付代币/跨链标志等)
  - nextAuctionId
  - feePercent / feeRecipient
  - 价格预言机映射（ETH/代币 -> USD）
- 主要函数：
  - initialize(router, ethPriceFeed, defaultFeePercent, feeRecipient)
  - createAuction(duration,startPrice,nftAddr,tokenId,paymentToken,crossChainEnabled)
  - placeBid(auctionId, amount) (ETH 或 ERC20)
  - endAuction(auctionId)
  - getUSDValue(amount, token)（依赖 Chainlink）
- 事件：AuctionCreated / BidPlaced / AuctionEnded / BidRefunded 等（视你当前版本）

### 3.2 NFTAuctionV2.sol
- 示例升级：追加 versionTag 变量 + setter/getter
- 存储布局保持：仅在末尾添加

### 3.3 NftAuctionFactory.sol
- 管理“拍卖合约（Proxy 实例）”地址列表
- 字段：
  - auctionImplementation：当前使用的逻辑实现地址
  - admin：创建权限
  - chainReceivers：跨链广播目标
  - s_router：CCIP Router（或 Mock）
- 核心：
  - initialize(impl, router)
  - setAuctionImplementation(newImpl) 仅 owner
  - setAdmin(addr)
  - setChainReceiver(selector, receiver)
  - createAuction(...) 内部 new ERC1967Proxy(auctionImplementation, initData)
  - _broadcastAuctionCreated(...) -> _sendMessage()
- 升级：UUPS `_authorizeUpgrade` 仅 owner

### 3.4 Mock 合约
- MockERC20：测试 ERC20
- MockRouter：记录跨链消息
- MockRemoteFactory：模拟另一条链接收广播
- MaliciousBidder：重入攻击模拟

---

## 4. 升级模式说明

| 场景 | 描述 | 方法 |
|------|------|------|
| 单个拍卖合约（代理）升级 | 每个拍卖是独立 UUPS proxy | upgrades.upgradeProxy(auctionProxy, NFTAuctionV2) |
| 未来新建拍卖使用新逻辑 | 旧实例保持旧逻辑，新实例指向新实现 | factory.setAuctionImplementation(newImpl) |
| 工厂自身升级 | 工厂为 UUPS proxy | upgrades.upgradeProxy(factoryProxy, FactoryV2) |

注意：  
- 不能改变已有变量顺序 / 删除结构字段  
- 仅在末尾追加新状态变量  

---

## 5. Chainlink/价格预言机

- ethPriceFeed: AggregatorV3Interface (ETH/USD)
- tokenPriceFeeds[token] → 对应 ERC20/USD 预言机
- getUSDValue(amount, token)：读取最新价格（需处理 8/18 decimals 差异）
- 测试中使用 ZeroAddress / Mock，不校验真实预言机

---

## 6. 跨链（模拟）

- 工厂创建拍卖时若 crossChainEnabled = true：
  - 遍历 supportedChains
  - encode("AUCTION_CREATED", tokenId, nftAddr, auctionProxy)
  - MockRouter.ccipSend 记录消息
- 测试读取 router.messageIds() + messages(messageId) 验证 payload

---

## 7. 手续费模型

- feePercent：bps（如 250 = 2.5%）
- endAuction：
  - fee = highestBid * feePercent / 10000
  - 向 feeRecipient 转账
  - 余款给卖家
- 可扩展：根据 USD 价格区间动态调整（挑战项）

---

## 8. 环境变量

示例 .env.example：
```
PRIVATE_KEY=0x...
RPC_SEPOLIA=https://sepolia.infura.io/v3/xxxxx
ROUTER_ADDRESS=0xMockOrRealRouter
ETH_PRICE_FEED=0xEthUsdAggregator
FEE_PERCENT=250
FEE_RECIPIENT=0xFeeRecipientAddress
ADMIN=0xAdminAddress
```

复制为 .env 并填充。

---

## 9. 安装与准备

```
npm install
npm install --save-dev @openzeppelin/hardhat-upgrades hardhat-deploy @nomicfoundation/hardhat-toolbox solidity-coverage dotenv
```

hardhat.config.js 需包含：
```
require("@openzeppelin/hardhat-upgrades");
require("hardhat-deploy");
require("solidity-coverage");
```

---

## 10. 部署流程（推荐顺序）

本地:
```
npx hardhat compile
npx hardhat deploy --tags deployNftAuction --network hardhat
```

测试网:
```
npx hardhat deploy --tags deployNftAuction --network sepolia
```

输出：cache / deploy-output JSON 中包括：
- auctionImplementationV1
- factoryProxy
- factoryImplementationV1

---

## 11. 升级操作

1) 升级逻辑实现（影响未来新实例）：
```
npx hardhat deploy --tags upgradeNftAuction --network sepolia
```

2) 升级工厂自身：
```
npx hardhat deploy --tags upgradeFactory --network sepolia
```

3) 升级单个拍卖（已知 proxy 地址）：
```
AUCTION_PROXY=0xAuctionProxy npx hardhat deploy --tags upgradeSingleAuction --network sepolia
```

---

## 12. 测试与覆盖率

运行所有测试：
```
npx hardhat test
```

生成覆盖率：
```
npx hardhat coverage
```

测试分类：
- 01 核心创建 & 结束
- 02 出价/退款/ERC20/重入
- 03 升级保持状态
- 04 工厂权限/实现切换
- 05 跨链广播
- 06 单实例升级（按需）

可根据 `coverage/` 输出查看函数/行/分支覆盖率。

---


