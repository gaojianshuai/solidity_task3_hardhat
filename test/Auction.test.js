const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("NFT拍卖市场", function () {
  let nft;
  let auction;
  let factory;
  let uAuction;
  let owner;
  let seller;
  let bidder1;
  let bidder2;
  
  const TOKEN_URI = "https://example.com/token/1";
  const START_PRICE = ethers.utils.parseEther("1.0");
  const DURATION = 24 * 60 * 60; // 24小时
  
  beforeEach(async function () {
    [owner, seller, bidder1, bidder2] = await ethers.getSigners();
    
    // 部署NFT合约
    const AuctionNFT = await ethers.getContractFactory("AuctionNFT");
    nft = await AuctionNFT.deploy("Auction NFT", "ANFT", "");
    await nft.deployed();
    
    // 部署拍卖合约
    const Auction = await ethers.getContractFactory("Auction");
    auction = await Auction.deploy();
    await auction.deployed();
    
    // 部署工厂合约
    const AuctionFactory = await ethers.getContractFactory("AuctionFactory");
    factory = await AuctionFactory.deploy(auction.address);
    await factory.deployed();
    
    // 部署可升级合约
    const UAuction = await ethers.getContractFactory("UAuction");
    uAuction = await upgrades.deployProxy(UAuction, [], {
      initializer: "initialize",
    });
    await uAuction.deployed();
  });
  
  describe("NFT合约", function () {
    it("应该正确铸造NFT", async function () {
      await nft.connect(seller).mint(seller.address, TOKEN_URI);
      
      expect(await nft.ownerOf(1)).to.equal(seller.address);
      expect(await nft.tokenURI(1)).to.equal(TOKEN_URI);
    });
    
    it("应该支持批量铸造", async function () {
      const tokenURIs = [TOKEN_URI, TOKEN_URI, TOKEN_URI];
      await nft.connect(seller).mintBatch(seller.address, tokenURIs);
      
      expect(await nft.ownerOf(1)).to.equal(seller.address);
      expect(await nft.ownerOf(2)).to.equal(seller.address);
      expect(await nft.ownerOf(3)).to.equal(seller.address);
    });
  });
  
  describe("拍卖合约", function () {
    let auctionAddr;
    let startTime;
    
    beforeEach(async function () {
      // 铸造NFT
      await nft.connect(seller).mint(seller.address, TOKEN_URI);
      
      // 授权工厂合约转移NFT
      await nft.connect(seller).approve(factory.address, 1);
      
      startTime = Math.floor(Date.now() / 1000) + 60; // 1分钟后开始
      
      // 创建拍卖
      await factory.connect(seller).createAuction(
        nft.address,
        1,
        ethers.constants.AddressZero, // ETH支付
        START_PRICE,
        startTime,
        DURATION
      );
      
      auctionAddr = (await factory.allAuctions(0));
    });
    
    it("应该正确创建拍卖", async function () {
      const auctionInfo = await factory.auctionInfos(auctionAddr);
      
      expect(auctionInfo.seller).to.equal(seller.address);
      expect(auctionInfo.nftContract).to.equal(nft.address);
      expect(auctionInfo.tokenId).to.equal(1);
      expect(auctionInfo.startPrice).to.equal(START_PRICE);
    });
    
    it("应该接受出价", async function () {
      // 增加时间到拍卖开始
      await ethers.provider.send("evm_increaseTime", [60]);
      await ethers.provider.send("evm_mine");
      
      const bidAmount = ethers.utils.parseEther("1.5");
      const auctionContract = await ethers.getContractAt("Auction", auctionAddr);
      
      await expect(
        auctionContract.connect(bidder1).bid({ value: bidAmount })
      ).to.emit(auctionContract, "BidPlaced");
      
      const auctionInfo = await auctionContract.getAuctionInfo();
      expect(auctionInfo.highestBidder).to.equal(bidder1.address);
      expect(auctionInfo.highestBid).to.equal(bidAmount);
    });
  });
  
  describe("工厂合约", function () {
    it("应该正确记录所有拍卖", async function () {
      await nft.connect(seller).mint(seller.address, TOKEN_URI);
      await nft.connect(seller).approve(factory.address, 1);
      
      const startTime = Math.floor(Date.now() / 1000) + 60;
      
      await factory.connect(seller).createAuction(
        nft.address,
        1,
        ethers.constants.AddressZero,
        START_PRICE,
        startTime,
        DURATION
      );
      
      expect(await factory.allAuctionsLength()).to.equal(1);
      expect(await factory.userAuctionsLength(seller.address)).to.equal(1);
    });
  });
  
  describe("可升级合约", function () {
    it("应该支持升级", async function () {
      expect(await uAuction.version()).to.equal("v1.0.0");
      
      // 部署新版本
      const UAuctionV2 = await ethers.getContractFactory("UAuction");
      const uAuctionV2 = await upgrades.upgradeProxy(uAuction.address, UAuctionV2);
      
      // 验证升级后地址不变
      expect(uAuctionV2.address).to.equal(uAuction.address);
    });
  });
});