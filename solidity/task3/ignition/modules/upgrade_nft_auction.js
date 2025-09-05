//升级拍卖逻辑（部署 NFTAuctionV2 并让未来新实例使用；已创建实例若各自是代理需单独升级）
//前提：工厂合约内有 setAuctionImplementation(address) 或等价函数。
const {ethers,upgrades} = require("hardhat");
const fs = require("fs");//file system
const path = require("path");

module.exports = async function({getNamedAccounts,deployments}){
   const {save} = deployments;
   const {deployer} = await getNamedAccounts();
   console.log("部署用户地址:",deployer);


   // 读取 .cache/proxyNftAuction.json文件
   const storePath = path.resolve(__dirname,"./.cache/proxyNftAuction.json");
   if (!fs.existsSync(storePath)) throw new Error("缺少部署输出文件");
   const data = fs.readFileSync(storePath,"utf-8");
   const factoryProxy = data.factoryProxy;
   console.log("读取工厂代理:", factoryProxy);

  // 1. 部署新实现
  const NFTAuctionV2 = await ethers.getContractFactory("NFTAuctionV2");
  const implV2 = await NFTAuctionV2.deploy();
  await implV2.waitForDeployment();
  const implV2Addr = await implV2.getAddress();
  console.log("新 NFTAuction 实现:", implV2Addr);

    await save("NFTAuctionImplementationV2", {
    abi: JSON.parse(implV2.interface.format("json")),
    address: implV2Addr
  });

  // 2. 更新工厂引用
  const factory = await ethers.getContractAt("NftAuctionFactory", factoryProxy);
  if (!factory.setAuctionImplementation) {
    throw new Error("工厂缺少 setAuctionImplementation 函数");
  }
  const tx = await factory.setAuctionImplementation(implV2Addr);
  await tx.wait();
  console.log("工厂实现引用已更新为 V2");

  // 3. 更新缓存
  data.auctionImplementationV2 = implV2Addr;
  data.updatedAt = Date.now();
  fs.writeFileSync(storePath, JSON.stringify(data, null, 2));
  console.log("更新写入:", storePath);

  // 4. 额外保存点（再次保存工厂代理现状）
  await save("NftAuctionFactoryProxy", {
    abi: JSON.parse(factory.interface.format("json")),
    address: factoryProxy
  });

  // 5. 统一别名保存
  await save("NftAuctionProxy", {
    abi: JSON.parse(factory.interface.format("json")),
    address: factoryProxy
  });

  console.log("升级完成: 新逻辑实现已生效 (仅影响未来新拍卖，旧实例若是独立代理需单独升级)");
}

module.exports.tags = ['upgradeNftAuction'];

main().catch(e => {
  console.error(e);
  process.exit(1);
});