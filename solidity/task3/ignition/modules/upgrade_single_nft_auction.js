// 升级单个拍卖实例 (该实例必须是 UUPS 代理)
// 用法：AUCTION_PROXY=0xProxy npx hardhat deploy --tags upgradeSingleAuction --network <net>
require("dotenv").config();

module.exports = async function (hre) {
  const {ethers, upgrades, deployments, getNamedAccounts} = hre;
  const {save} = deployments;

  const {deployer} = await getNamedAccounts();
  console.log("部署用户地址:", deployer);

  const auctionProxy = process.env.AUCTION_PROXY;
  if (!auctionProxy) throw new Error("请提供环境变量 AUCTION_PROXY");

  console.log("准备升级拍卖实例代理:", auctionProxy);

  const NFTAuctionV2 = await ethers.getContractFactory("NFTAuctionV2");
  const upgraded = await upgrades.upgradeProxy(auctionProxy, NFTAuctionV2, {kind: "uups"});
  await upgraded.waitForDeployment();
  const newImpl = await upgrades.erc1967.getImplementationAddress(auctionProxy);

  console.log("拍卖实例升级完成，新实现:", newImpl);

  await save("SingleAuctionProxy_" + auctionProxy.slice(0, 10), {
    abi: JSON.parse(upgraded.interface.format("json")),
    address: auctionProxy
  });
  await save("SingleAuctionImplementationV2_" + auctionProxy.slice(0, 10), {
    abi: JSON.parse(upgraded.interface.format("json")),
    address: newImpl
  });

  console.log("单实例升级保存点已记录");
};

module.exports.tags = ["upgradeSingleAuction"];