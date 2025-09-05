// 升级工厂自身 (UUPS 升级)
// 运行：npx hardhat deploy --tags upgradeFactory --network <net>
require("dotenv").config();
const fs = require("fs");
const path = require("path");

module.exports = async function (hre) {
  const {ethers, upgrades, deployments, getNamedAccounts} = hre;
  const {save} = deployments;

  const {deployer} = await getNamedAccounts();
  console.log("部署用户地址:", deployer);

  const cachePath = path.resolve(__dirname, ".cache", "proxyNftAuction.json");
  if (!fs.existsSync(cachePath)) throw new Error("缺少缓存文件: " + cachePath);
  const cache = JSON.parse(fs.readFileSync(cachePath, "utf-8"));
  const factoryProxy = cache.factoryProxy;
  if (!factoryProxy) throw new Error("缓存中缺少 factoryProxy");

  console.log("准备升级工厂代理:", factoryProxy);

  // 部署 / 升级到 V2
  const FactoryV2 = await ethers.getContractFactory("NftAuctionFactoryV2");
  const upgraded = await upgrades.upgradeProxy(factoryProxy, FactoryV2, {kind: "uups"});
  await upgraded.waitForDeployment();
  const newImpl = await upgrades.erc1967.getImplementationAddress(factoryProxy);
  console.log("工厂升级完成，新实现地址:", newImpl);

  cache.factoryImplementationV2 = newImpl;
  cache.factoryUpgradedAt = Date.now();
  fs.writeFileSync(cachePath, JSON.stringify(cache, null, 2));
  console.log("缓存更新:", cachePath);

  await save("NftAuctionFactoryProxy", {
    abi: JSON.parse(upgraded.interface.format("json")),
    address: factoryProxy
  });
  await save("NftAuctionFactoryImplementationV2", {
    abi: JSON.parse(upgraded.interface.format("json")),
    address: newImpl
  });
  await save("NftAuctionProxy", {
    abi: JSON.parse(upgraded.interface.format("json")),
    address: factoryProxy
  });

  console.log("工厂自身升级脚本执行完成");
};

module.exports.tags = ["upgradeFactory"];