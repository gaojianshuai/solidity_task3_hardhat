const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("开始部署NFT拍卖市场合约...");
  
  const [deployer] = await ethers.getSigners();
  console.log("部署者地址:", deployer.address);
  
  // 1. 部署NFT合约
  console.log("正在部署NFT合约...");
  const AuctionNFT = await ethers.getContractFactory("AuctionNFT");
  const nft = await AuctionNFT.deploy(
    "Auction NFT",
    "ANFT",
    "https://api.example.com/nft/"
  );
  await nft.deployed();
  console.log("NFT合约部署完成，地址:", nft.address);
  
  // 2. 部署拍卖合约实现
  console.log("正在部署拍卖合约实现...");
  const Auction = await ethers.getContractFactory("Auction");
  const auctionImpl = await Auction.deploy();
  await auctionImpl.deployed();
  console.log("拍卖合约实现部署完成，地址:", auctionImpl.address);
  
  // 3. 部署工厂合约
  console.log("正在部署工厂合约...");
  const AuctionFactory = await ethers.getContractFactory("AuctionFactory");
  const factory = await AuctionFactory.deploy(auctionImpl.address);
  await factory.deployed();
  console.log("工厂合约部署完成，地址:", factory.address);
  
  // 4. 部署可升级拍卖合约
  console.log("正在部署可升级拍卖合约...");
  const UAuction = await ethers.getContractFactory("UAuction");
  const uAuction = await upgrades.deployProxy(UAuction, [], {
    initializer: "initialize",
  });
  await uAuction.deployed();
  console.log("可升级拍卖合约部署完成，地址:", uAuction.address);
  
  console.log("\n=== 部署总结 ===");
  console.log("NFT合约:", nft.address);
  console.log("拍卖合约实现:", auctionImpl.address);
  console.log("工厂合约:", factory.address);
  console.log("可升级拍卖合约:", uAuction.address);
  
  return {
    nft: nft.address,
    auctionImpl: auctionImpl.address,
    factory: factory.address,
    uAuction: uAuction.address
  };
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });