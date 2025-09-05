//跨链广播测试
const {expect} = require("chai");
const {ethers} = require("hardhat");

describe("Cross-chain broadcast via Factory + MockRouter", () => {
  let owner, admin, feeRecipient;
  let impl, factory, router, remote;

  beforeEach(async () => {
    [owner, admin, feeRecipient] = await ethers.getSigners();
    const MockRouter = await ethers.getContractFactory("MockRouter");
    router = await MockRouter.deploy(); await router.waitForDeployment();
    const Remote = await ethers.getContractFactory("MockRemoteFactory");
    remote = await Remote.deploy(); await remote.waitForDeployment();

    const Impl = await ethers.getContractFactory("NFTAuction");
    impl = await Impl.deploy(); await impl.waitForDeployment();

    const Factory = await ethers.getContractFactory("NFTAuctionFactory");
    factory = await Factory.deploy(); await factory.waitForDeployment();
    await factory.initialize(await impl.getAddress(), await router.getAddress());
    await factory.setAdmin(admin.address);
    await factory.setChainReceiver(5001, await remote.getAddress());
    await factory.setChainReceiver(7002, await remote.getAddress());
  });

  it("broadcast on create when crossChainEnabled", async () => {
    await factory.connect(admin).createAuction(
      3600,
      ethers.parseEther("1"),
      ethers.ZeroAddress,
      101,
      ethers.ZeroAddress,
      250,
      feeRecipient.address,
      ethers.ZeroAddress,
      true
    );
    const MockRouter = await ethers.getContractFactory("MockRouter");
    const messageIds = await router.getMessageIds();
    expect(messageIds.length).eq(2); // 两条链
    const first = await router.messages(messageIds[0]);
    const decoded = ethers.AbiCoder.defaultAbiCoder().decode(
      ["string","uint256","address","address"],
      first.data
    );
    expect(decoded[0]).eq("AUCTION_CREATED");
    expect(decoded[1]).eq(101n);
  });

  it("no broadcast if disabled", async () => {
    await factory.connect(admin).createAuction(
      3600,
      ethers.parseEther("1"),
      ethers.ZeroAddress,
      202,
      ethers.ZeroAddress,
      250,
      feeRecipient.address,
      ethers.ZeroAddress,
      false
    );
    const ids = await router.getMessageIds();
    expect(ids.length).eq(0);
  });
});