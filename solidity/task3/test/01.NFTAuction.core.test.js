//核心单元测试：NFTAuction 基础

const {expect} = require("chai");
const {ethers, upgrades} = require("hardhat");
const {increase} = require("./helpers/time");

describe("NFTAuction Core", () => {
  let owner, user1, feeRecipient;
  let auctionProxy, auction, router;

  beforeEach(async () => {
    [owner, user1, feeRecipient] = await ethers.getSigners();
    const MockRouter = await ethers.getContractFactory("MockRouter");
    router = await MockRouter.deploy(); await router.waitForDeployment();

    const Impl = await ethers.getContractFactory("NFTAuction");
    auctionProxy = await upgrades.deployProxy(
      Impl,
      [
        await router.getAddress(), // router/或 price feed 视实现调整
        ethers.ZeroAddress,        // ethPriceFeed (mock)
        250,                       // default fee bps
        feeRecipient.address
      ],
      {initializer:"initialize", kind:"uups"}
    );
    await auctionProxy.waitForDeployment();
    auction = Impl.attach(await auctionProxy.getAddress());
  });

  it("initializes only once", async () => {
    await expect(
      auction.initialize(ethers.ZeroAddress, ethers.ZeroAddress, 100, feeRecipient.address)
    ).to.be.reverted;
  });

  it("creates auction (ETH)", async () => {
    await auction.createAuction(
      3600,
      ethers.parseEther("1"),
      ethers.ZeroAddress,
      1,
      ethers.ZeroAddress,
      false
    );
    const a = await auction.auctions(0);
    expect(a.startPrice).eq(ethers.parseEther("1"));
    expect(a.ended).eq(false);
  });

  it("rejects bid below startPrice", async () => {
    await auction.createAuction(3600, ethers.parseEther("1"), ethers.ZeroAddress, 2, ethers.ZeroAddress, false);
    await expect(
      auction.connect(user1).placeBid(0, ethers.parseEther("0.5"), {value: ethers.parseEther("0.5")})
    ).to.be.reverted;
  });

  it("accepts first bid", async () => {
    await auction.createAuction(3600, ethers.parseEther("1"), ethers.ZeroAddress, 3, ethers.ZeroAddress, false);
    await auction.connect(user1).placeBid(0, ethers.parseEther("1"), {value: ethers.parseEther("1")});
    const a = await auction.auctions(0);
    expect(a.highestBid).eq(ethers.parseEther("1"));
    expect(a.highestBidder).eq(user1.address);
  });

  it("cannot end before expiry", async () => {
    await auction.createAuction(1000, ethers.parseEther("1"), ethers.ZeroAddress, 4, ethers.ZeroAddress, false);
    await expect(auction.endAuction(0)).to.be.reverted;
  });

  it("ends after time & sends fee", async () => {
    await auction.createAuction(30, ethers.parseEther("2"), ethers.ZeroAddress, 5, ethers.ZeroAddress, false);
    await auction.connect(user1).placeBid(0, ethers.parseEther("2"), {value: ethers.parseEther("2")});
    await increase(40);
    const feeBefore = await ethers.provider.getBalance(feeRecipient.address);
    const sellerBefore = await ethers.provider.getBalance(owner.address);
    await auction.endAuction(0);
    const feeAfter = await ethers.provider.getBalance(feeRecipient.address);
    const sellerAfter = await ethers.provider.getBalance(owner.address);
    const fee = ethers.parseEther("2") * 250n / 10000n;
    expect(feeAfter - feeBefore).eq(fee);
    expect(sellerAfter - sellerBefore).to.be.approximately(ethers.parseEther("2") - fee, ethers.parseEther("0.01"));
  });

  it("no bids -> end returns NFT to seller (if NFT locked)", async () => {
    await auction.createAuction(10, ethers.parseEther("1"), ethers.ZeroAddress, 6, ethers.ZeroAddress, false);
    await increase(15);
    await auction.endAuction(0); // should not revert
    const a = await auction.auctions(0);
    expect(a.ended).eq(true);
  });
});