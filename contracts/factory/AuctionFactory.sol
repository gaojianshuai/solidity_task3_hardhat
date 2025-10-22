// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "../auction/Auction.sol";

/**
 * @title AuctionFactory
 * @dev 拍卖工厂合约，使用类似于Uniswap V2的工厂模式管理拍卖
 * 功能包括：
 * - 创建拍卖合约实例
 * - 管理所有拍卖
 * - 查询拍卖信息
 */
contract AuctionFactory {
    using Clones for address;
    
    // 拍卖模板合约地址
    address public auctionImplementation;
    
    // 所有创建的拍卖合约地址数组
    address[] public allAuctions;
    
    // 用户创建的拍卖映射
    mapping(address => address[]) public userAuctions;
    
    // 拍卖信息映射
    mapping(address => AuctionInfo) public auctionInfos;
    
    // 事件定义
    event AuctionCreated(
        address indexed auction,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        address paymentToken,
        uint256 startPrice,
        uint256 startTime,
        uint256 duration
    );
    
    /**
     * @dev 构造函数
     * @param _auctionImplementation 拍卖合约实现地址
     */
    constructor(address _auctionImplementation) {
        auctionImplementation = _auctionImplementation;
    }
    
    /**
     * @dev 创建新的拍卖
     * @param nftContract NFT合约地址
     * @param tokenId NFT tokenId
     * @param paymentToken 支付代币地址
     * @param startPrice 起拍价
     * @param startTime 开始时间
     * @param duration 拍卖持续时间
     * @return auctionAddr 新创建的拍卖合约地址
     */
    function createAuction(
        address nftContract,
        uint256 tokenId,
        address paymentToken,
        uint256 startPrice,
        uint256 startTime,
        uint256 duration
    ) external returns (address auctionAddr) {
        // 使用最小代理模式创建拍卖合约
        auctionAddr = Clones.clone(auctionImplementation);
        
        // 初始化拍卖合约
        Auction(auctionAddr).initialize(
            msg.sender,
            nftContract,
            tokenId,
            paymentToken,
            startPrice,
            startTime,
            duration
        );
        
        // 记录拍卖信息
        allAuctions.push(auctionAddr);
        userAuctions[msg.sender].push(auctionAddr);
        
        // 存储拍卖信息
        auctionInfos[auctionAddr] = AuctionInfo({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            paymentToken: paymentToken,
            startPrice: startPrice,
            startTime: startTime,
            endTime: startTime + duration,
            highestBidder: address(0),
            highestBid: 0,
            status: Auction.AuctionStatus.ACTIVE
        });
        
        emit AuctionCreated(
            auctionAddr,
            msg.sender,
            nftContract,
            tokenId,
            paymentToken,
            startPrice,
            startTime,
            duration
        );
    }
    
    /**
     * @dev 获取所有拍卖数量
     * @return 拍卖总数
     */
    function allAuctionsLength() external view returns (uint256) {
        return allAuctions.length;
    }
    
    /**
     * @dev 获取用户创建的拍卖数量
     * @param user 用户地址
     * @return 用户创建的拍卖数量
     */
    function userAuctionsLength(address user) external view returns (uint256) {
        return userAuctions[user].length;
    }
    
    /**
     * @dev 获取所有拍卖地址
     * @param start 起始索引
     * @param end 结束索引
     * @return 拍卖地址数组
     */
    function getAuctions(uint256 start, uint256 end) 
        external 
        view 
        returns (address[] memory) 
    {
        require(start <= end && end < allAuctions.length, "Invalid range");
        
        address[] memory auctions = new address[](end - start + 1);
        for (uint256 i = start; i <= end; i++) {
            auctions[i - start] = allAuctions[i];
        }
        return auctions;
    }
    
    /**
     * @dev 获取用户的所有拍卖地址
     * @param user 用户地址
     * @return 用户拍卖地址数组
     */
    function getUserAuctions(address user) 
        external 
        view 
        returns (address[] memory) 
    {
        return userAuctions[user];
    }
    
    /**
     * @dev 更新拍卖信息（由拍卖合约调用）
     * @param auctionAddr 拍卖合约地址
     * @param highestBidder 最高出价者
     * @param highestBid 最高出价
     * @param status 拍卖状态
     */
    function updateAuctionInfo(
        address auctionAddr,
        address highestBidder,
        uint256 highestBid,
        Auction.AuctionStatus status
    ) external {
        require(msg.sender == auctionAddr, "Only auction contract");
        
        AuctionInfo storage info = auctionInfos[auctionAddr];
        info.highestBidder = highestBidder;
        info.highestBid = highestBid;
        info.status = status;
    }
}