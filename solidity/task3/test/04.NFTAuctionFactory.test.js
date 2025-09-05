//Factory 测试（创建 / 实现切换 / 跨链配置）
const {expect} = require("chai");
const {ethers} = require("hardhat");

describe("NFTAuctionFactory", () => {
  let owner, admin, feeRecipient;
  let impl, factory, router;

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

  it("only owner can set implementation", async () => {
    const Impl2 = await ethers.getContractFactory("NFTAuction");
    const impl2 = await Impl2.deploy(); await impl2.waitForDeployment();
    await expect(factory.connect(admin).setAuctionImplementation(await impl2.getAddress())).to.be.reverted;
    await expect(factory.setAuctionImplementation(await impl2.getAddress()))
      .to.emit(factory,"AuctionImplementationUpdated");
  });

  it("admin can create auction", async () => {
    await factory.connect(admin).setChainReceiver(9999, owner.address);
    await factory.connect(admin).createAuction(
      3600,
      ethers.parseEther("1"),
      ethers.ZeroAddress,
      10,
      ethers.ZeroAddress,
      250,
      feeRecipient.address,
      ethers.ZeroAddress,
      true
    );
    const list = await factory.getAuctions();
    expect(list.length).eq(1);
  });

  it("non-admin cannot create", async () => {
    await expect(factory.createAuction(
      3600,
      ethers.parseEther("1"),
      ethers.ZeroAddress,
      11,
      ethers.ZeroAddress,
      250,
      feeRecipient.address,
      ethers.ZeroAddress,
      false
    )).to.be.reverted;
  });

  it("updates implementation affects future deployments only", async () => {
    await factory.connect(admin).createAuction(3600, ethers.parseEther("1"), ethers.ZeroAddress, 12, ethers.ZeroAddress, 250, feeRecipient.address, ethers.ZeroAddress, false);
    const Impl2 = await ethers.getContractFactory("NFTAuction");
    const impl2 = await Impl2.deploy(); await impl2.waitForDeployment();
    await factory.setAuctionImplementation(await impl2.getAddress());
    await factory.connect(admin).createAuction(3600, ethers.parseEther("2"), ethers.ZeroAddress, 13, ethers.ZeroAddress, 250, feeRecipient.address, ethers.ZeroAddress, false);
    const all = await factory.getAuctions();
    expect(all.length).eq(2);
  });
});