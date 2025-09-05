//升级测试
const {expect} = require("chai");
const {ethers, upgrades} = require("hardhat");

describe("NFTAuction Upgrade UUPS", () => {
  let owner, user, feeRecipient;
  let proxy, auction;

  beforeEach(async () => {
    [owner, user, feeRecipient] = await ethers.getSigners();
    const MockRouter = await ethers.getContractFactory("MockRouter");
    const router = await MockRouter.deploy(); await router.waitForDeployment();
    const Impl = await ethers.getContractFactory("NFTAuction");
    proxy = await upgrades.deployProxy(
      Impl,
      [await router.getAddress(), ethers.ZeroAddress, 250, feeRecipient.address],
      {initializer:"initialize", kind:"uups"}
    );
    auction = Impl.attach(await proxy.getAddress());
    await auction.createAuction(3600, ethers.parseEther("1"), ethers.ZeroAddress, 1, ethers.ZeroAddress, false);
    await auction.connect(user).placeBid(0, ethers.parseEther("1"), {value: ethers.parseEther("1")});
  });

  it("upgrades to V2 keeps state", async () => {
    const V2 = await ethers.getContractFactory("NFTAuctionV2");
    const upgraded = await upgrades.upgradeProxy(await proxy.getAddress(), V2, {kind:"uups"});
    await upgraded.setVersionTag("v2.0");
    const a = await upgraded.auctions(0);
    expect(a.highestBid).eq(ethers.parseEther("1"));
    expect(await upgraded.getVersionTag()).eq("v2.0");
  });
});