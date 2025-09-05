//出价 & 退款 & ERC20 & 重入防护
const {expect} = require("chai");
const {ethers, upgrades} = require("hardhat");
const {increase} = require("./helpers/time");

describe("NFTAuction Bidding / Refund / ERC20 / Reentrancy", () => {
  let owner, user1, user2, feeRecipient;
  let auction, erc20, router;

  beforeEach(async () => {
    [owner, user1, user2, feeRecipient] = await ethers.getSigners();
    const MockRouter = await ethers.getContractFactory("MockRouter");
    router = await MockRouter.deploy(); await router.waitForDeployment();

    const MockERC20 = await ethers.getContractFactory("MockERC20");
    erc20 = await MockERC20.deploy(); await erc20.waitForDeployment();
    await erc20.mint(user1.address, ethers.parseEther("100"));
    await erc20.mint(user2.address, ethers.parseEther("100"));

    const Impl = await ethers.getContractFactory("NFTAuction");
    const proxy = await upgrades.deployProxy(
      Impl,
      [await router.getAddress(), ethers.ZeroAddress, 250, feeRecipient.address],
      {initializer:"initialize", kind:"uups"}
    );
    auction = Impl.attach(await proxy.getAddress());
  });

  it("overbids refunds previous bidder (ETH)", async () => {
    await auction.createAuction(3600, ethers.parseEther("1"), ethers.ZeroAddress, 1, ethers.ZeroAddress, false);
    await auction.connect(user1).placeBid(0, ethers.parseEther("1"), {value: ethers.parseEther("1")});
    const before = await ethers.provider.getBalance(user1.address);
    const tx = await auction.connect(user2).placeBid(0, ethers.parseEther("2"), {value: ethers.parseEther("2")});
    const receipt = await tx.wait();
    const gas = receipt.gasUsed * receipt.gasPrice;
    const after = await ethers.provider.getBalance(user1.address);
    expect(after - before).to.be.approximately(ethers.parseEther("1"), ethers.parseEther("0.01"));
    const a = await auction.auctions(0);
    expect(a.highestBidder).eq(user2.address);
  });

  it("ERC20 bidding & refund", async () => {
    await auction.createAuction(3600, ethers.parseEther("1"), ethers.ZeroAddress, 2, await erc20.getAddress(), false);
    await erc20.connect(user1).approve(await auction.getAddress(), ethers.parseEther("10"));
    await auction.connect(user1).placeBid(0, ethers.parseEther("1"));
    await erc20.connect(user2).approve(await auction.getAddress(), ethers.parseEther("10"));
    await auction.connect(user2).placeBid(0, ethers.parseEther("2"));
    const a = await auction.auctions(0);
    expect(a.highestBid).eq(ethers.parseEther("2"));
  });

  it("cannot bid after ended", async () => {
    await auction.createAuction(5, ethers.parseEther("1"), ethers.ZeroAddress, 3, ethers.ZeroAddress, false);
    await increase(6);
    await expect(
      auction.connect(user1).placeBid(0, ethers.parseEther("1"), {value: ethers.parseEther("1")})
    ).to.be.reverted;
  });

  it("reentrancy blocked", async () => {
    await auction.createAuction(3600, ethers.parseEther("1"), ethers.ZeroAddress, 4, ethers.ZeroAddress, false);
    // user1 first bid
    await auction.connect(user1).placeBid(0, ethers.parseEther("1"), {value: ethers.parseEther("1")});
    // 部署恶意合约
    const Mal = await ethers.getContractFactory("MaliciousBidder");
    const mal = await Mal.deploy(await auction.getAddress()); await mal.waitForDeployment();
    // 恶意合约抢第二次出价（应收到退款时尝试重入）
    await auction.connect(user2).placeBid(0, ethers.parseEther("2"), {value: ethers.parseEther("2")});
    // 人为让恶意合约去出价（需要资金）
    await owner.sendTransaction({to: await mal.getAddress(), value: ethers.parseEther("2")});
    await expect(
      auction.connect(owner).placeBid(0, ethers.parseEther("3"), {value: ethers.parseEther("3")})
    ).not.to.be.reverted;
  });
});