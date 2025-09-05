// 部署脚本（hardhat-deploy 风格）
// 命令：npx hardhat deploy --tags deployNftAuction --network <network>

const {deployments,updategrades} = require("hardhat");
const fs = require("fs");//file system
const path = require("path");
require("dotenv").config();

module.exports = async ({getNamedAccounts, deployments}) => {
   const {
    ROUTER_ADDRESS,
    ETH_PRICE_FEED,
    FEE_PERCENT = "250",
    FEE_RECIPIENT,
    ADMIN
  } = process.env;

  if (!ROUTER_ADDRESS || !ETH_PRICE_FEED || !FEE_RECIPIENT || !ADMIN) {
    throw new Error("缺少必要 env: ROUTER_ADDRESS / ETH_PRICE_FEED / FEE_RECIPIENT / ADMIN");
  }

  const {deployer} = await getNamedAccounts();
  console.log("部署用户地址:",deployer);

  //1.部署NFT
  const Nft = await ethers.getContractFactory("NFTContract");
  const nft = await Nft.deploy();
  await nft.waitForDeployment();
  const nftAddress = await nft.getAddress();
  console.log("NFT合约地址:",nftAddress);

  // 2. 部署NFTAuction实现合约 (UUPS 实现)
  const NFTAuction = await ethers.getContractFactory("NFTAuction");
  const auctionImpl = await NFTAuction.deploy();
  await auctionImpl.waitForDeployment();
  const auctionImplAddress = await auctionImpl.getAddress();
  console.log("NFTAuction实现合约地址:", auctionImplAddress);

  //部署NFT拍卖合约  工厂代理
  const NFTAuctionFactory = await ethers.getContractFactory("NftAuctionFactory");
  const nftAuctionFactory = await NFTAuctionFactory.deployProxy(NFTAuctionFactory,
    [auctionImplAddress,
      ADMIN,
      ROUTER_ADDRESS,
      ETH_PRICE_FEED,
      FEE_PERCENT,
      FEE_RECIPIENT
    ],
    {initializer:"initialize",kind:"uups"});
  await nftAuctionFactory.waitForDeployment();
  const nftAuctionFactoryAddress = await nftAuctionFactory.getAddress();
  console.log("NFT拍卖合约代理地址:",nftAuctionFactoryAddress);
  const nftAuctionFactoryImplAddress = await upgrades.erc1967.getImplementationAddress(nftAuctionFactoryAddress);
  console.log("NFT拍卖合约实现地址:",nftAuctionFactoryImplAddress);  

  //设置参数
  await nftAuctionFactory.setAdmin(deployer);


  const storePath = path.resolve(__dirname,"./.cache/proxyNftAuction.json");
  if (!fs.existsSync(storePath)) fs.mkdirSync(storePath, {recursive: true});
  const out = {
    networkChainId: (await ethers.provider.getNetwork()).chainId,
    deployer,
    nft: nftAddress,
    auctionImplementationV1: auctionImplAddress,
    factoryProxy: factoryProxyAddress,
    factoryImplementationV1: factoryImplAddress,
    timestamp: Date.now()
  };

  fs.writeFileSync(storePath, JSON.stringify(out, null, 2));
  console.log("更新写入:", storePath);

  await save("NftAuctionProxy", {
    abi:JSON.parse(nftAuctionFactory.interface.format("json")),
    address: nftAuctionFactoryAddress,
  })

};
module.exports.tags = ['deployNftAuction'];
main()
    .then(() => process.exit(0))
    .catch((error) => {
     console.error(error);
     process.exitCode = 1;
});