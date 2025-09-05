//单实例拍卖升级（如果每个拍卖是独立代理）
const {expect} = require("chai");
const {ethers} = require("hardhat");
const {increase} = require("./helpers/time");

describe("Single Auction Proxy Upgrade (if per-auction proxy pattern adopted)", () => {
  let owner, admin, feeRecipient;
  let factory, impl, router;

  beforeEach(async () => {
    [owner, admin, feeRecipient] = await ethers.getSigners();
    const MockRouter = await ethers.getContractFactory("MockRouter");
    router = await MockRouter.deploy(); await router.waitForDeployment();

    const Impl = await ethers.getContractFactory("NFTAuction");
    impl = await Impl.deploy(); await impl.waitForDeployment();

    const Factory = await ethers.getContractFactory("NFTAuctionFactory");
    factory = await Factory.deploy(); await factory.waitForDeployment();
    await factory.initialize(await impl.getAddress(), await router.getAddress());
    await factory.setAdmin(admin.address);
  });

  it("create auction & upgrade implementation for future ones", async () => {
    await factory.connect(admin).createAuction(
      3600,
      ethers.parseEther("1"),
      ethers.ZeroAddress,
      999,
      ethers.ZeroAddress,
      250,
      feeRecipient.address,
      ethers.ZeroAddress,
      false
    );
    const Impl2 = await ethers.getContractFactory("NFTAuction");
    const impl2 = await Impl2.deploy(); await impl2.waitForDeployment();
    await factory.setAuctionImplementation(await impl2.getAddress());
    await factory.connect(admin).createAuction(
      3600,
      ethers.parseEther("2"),
      ethers.ZeroAddress,
      1000,
      ethers.ZeroAddress,
      250,
      feeRecipient.address,
      ethers.ZeroAddress,
      false
    );
    const list = await factory.getAuctions();
    expect(list.length).eq(2);
  });
});