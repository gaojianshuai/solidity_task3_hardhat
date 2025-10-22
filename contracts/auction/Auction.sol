// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../oracles/PriceConverter.sol";

/**
 * @title Auction
 * @dev NFT拍卖合约，支持以太坊和ERC20代币出价
 * 功能包括：
 * - 创建拍卖
 * - 出价功能（ETH和ERC20）
 * - 结束拍卖
 * - 价格转换（使用Chainlink预言机）
 * - 动态手续费
 */
contract Auction is ReentrancyGuard {
    using Address for address payable;
    using PriceConverter for uint256;
    
    // 拍卖状态枚举
    enum AuctionStatus {
        ACTIVE,     // 拍卖进行中
        ENDED,      // 拍卖已结束
        CANCELLED   // 拍卖已取消
    }
    
    // 拍卖结构体
    struct AuctionInfo {
        address seller;             // 卖家地址
        address nftContract;        // NFT合约地址
        uint256 tokenId;            // NFT tokenId
        address paymentToken;       // 支付代币地址（address(0) 表示ETH）
        uint256 startPrice;         // 起拍价
        uint256 startTime;          // 开始时间
        uint256 endTime;            // 结束时间
        address highestBidder;      // 最高出价者
        uint256 highestBid;         // 最高出价金额
        AuctionStatus status;       // 拍卖状态
    }
    
    // 拍卖信息
    AuctionInfo public auction;
    
    // 出价记录映射
    mapping(address => uint256) public bids;
    
    // 事件定义
    event AuctionCreated(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        address paymentToken,
        uint256 startPrice,
        uint256 startTime,
        uint256 endTime
    );
    
    event BidPlaced(
        address indexed bidder,
        uint256 amount,
        uint256 amountInUSD
    );
    
    event AuctionEnded(
        address indexed winner,
        uint256 amount,
        address indexed seller
    );
    
    event AuctionCancelled(address indexed seller);
    
    // 修饰器：只有卖家可调用
    modifier onlySeller() {
        require(msg.sender == auction.seller, "Only seller");
        _;
    }
    
    // 修饰器：拍卖必须处于活跃状态
    modifier onlyActive() {
        require(auction.status == AuctionStatus.ACTIVE, "Auction not active");
        require(block.timestamp >= auction.startTime, "Auction not started");
        require(block.timestamp <= auction.endTime, "Auction ended");
        _;
    }
    
    /**
     * @dev 初始化拍卖
     * @param _seller 卖家地址
     * @param _nftContract NFT合约地址
     * @param _tokenId NFT tokenId
     * @param _paymentToken 支付代币地址
     * @param _startPrice 起拍价
     * @param _startTime 开始时间
     * @param _duration 拍卖持续时间（秒）
     */
    function initialize(
        address _seller,
        address _nftContract,
        uint256 _tokenId,
        address _paymentToken,
        uint256 _startPrice,
        uint256 _startTime,
        uint256 _duration
    ) external {
        require(auction.seller == address(0), "Already initialized");
        require(_seller != address(0), "Invalid seller");
        require(_nftContract != address(0), "Invalid NFT contract");
        require(_duration > 0, "Invalid duration");
        
        // 转移NFT到拍卖合约
        IERC721(_nftContract).transferFrom(_seller, address(this), _tokenId);
        
        auction = AuctionInfo({
            seller: _seller,
            nftContract: _nftContract,
            tokenId: _tokenId,
            paymentToken: _paymentToken,
            startPrice: _startPrice,
            startTime: _startTime,
            endTime: _startTime + _duration,
            highestBidder: address(0),
            highestBid: 0,
            status: AuctionStatus.ACTIVE
        });
        
        emit AuctionCreated(
            _seller,
            _nftContract,
            _tokenId,
            _paymentToken,
            _startPrice,
            _startTime,
            auction.endTime
        );
    }
    
    /**
     * @dev 出价函数（ETH）
     */
    function bid() external payable nonReentrant onlyActive {
        require(auction.paymentToken == address(0), "ETH not accepted");
        require(msg.value > auction.highestBid, "Bid too low");
        require(msg.value >= auction.startPrice, "Bid below start price");
        
        _placeBid(msg.value);
    }
    
    /**
     * @dev 出价函数（ERC20）
     * @param amount 出价金额
     */
    function bidWithERC20(uint256 amount) external nonReentrant onlyActive {
        require(auction.paymentToken != address(0), "ERC20 not accepted");
        require(amount > auction.highestBid, "Bid too low");
        require(amount >= auction.startPrice, "Bid below start price");
        
        // 转移ERC20代币到拍卖合约
        IERC20(auction.paymentToken).transferFrom(msg.sender, address(this), amount);
        
        _placeBid(amount);
    }
    
    /**
     * @dev 内部出价处理函数
     * @param amount 出价金额
     */
    function _placeBid(uint256 amount) internal {
        // 退还前一个最高出价者的资金
        if (auction.highestBidder != address(0)) {
            _refundBid(auction.highestBidder, auction.highestBid);
        }
        
        // 更新最高出价
        auction.highestBidder = msg.sender;
        auction.highestBid = amount;
        bids[msg.sender] = amount;
        
        // 计算美元价值
        uint256 amountInUSD = amount.getPriceInUSD(auction.paymentToken);
        
        emit BidPlaced(msg.sender, amount, amountInUSD);
    }
    
    /**
     * @dev 退还出价资金
     * @param bidder 出价者地址
     * @param amount 退还金额
     */
    function _refundBid(address bidder, uint256 amount) internal {
        if (auction.paymentToken == address(0)) {
            payable(bidder).sendValue(amount);
        } else {
            IERC20(auction.paymentToken).transfer(bidder, amount);
        }
    }
    
    /**
     * @dev 结束拍卖
     */
    function endAuction() external nonReentrant {
        require(
            msg.sender == auction.seller || block.timestamp > auction.endTime,
            "Cannot end auction"
        );
        require(auction.status == AuctionStatus.ACTIVE, "Auction not active");
        
        auction.status = AuctionStatus.ENDED;
        
        if (auction.highestBidder != address(0)) {
            // 转移NFT给获胜者
            IERC721(auction.nftContract).transferFrom(
                address(this),
                auction.highestBidder,
                auction.tokenId
            );
            
            // 计算动态手续费
            uint256 fee = _calculateFee(auction.highestBid);
            uint256 sellerAmount = auction.highestBid - fee;
            
            // 转移资金给卖家
            if (auction.paymentToken == address(0)) {
                payable(auction.seller).sendValue(sellerAmount);
            } else {
                IERC20(auction.paymentToken).transfer(auction.seller, sellerAmount);
            }
            
            emit AuctionEnded(auction.highestBidder, auction.highestBid, auction.seller);
        } else {
            // 无人出价，退还NFT给卖家
            IERC721(auction.nftContract).transferFrom(
                address(this),
                auction.seller,
                auction.tokenId
            );
            
            emit AuctionCancelled(auction.seller);
        }
    }
    
    /**
     * @dev 计算动态手续费
     * @param amount 拍卖金额
     * @return 手续费金额
     */
    function _calculateFee(uint256 amount) internal pure returns (uint256) {
        // 动态手续费逻辑：金额越大，手续费比例越低
        if (amount >= 100 ether) {
            return amount * 2 / 100; // 2%
        } else if (amount >= 10 ether) {
            return amount * 3 / 100; // 3%
        } else {
            return amount * 5 / 100; // 5%
        }
    }
    
    /**
     * @dev 获取拍卖信息
     * @return 拍卖信息结构体
     */
    function getAuctionInfo() external view returns (AuctionInfo memory) {
        return auction;
    }
    
    /**
     * @dev 获取当前最高出价的美元价值
     * @return 美元价值
     */
    function getHighestBidInUSD() external view returns (uint256) {
        return auction.highestBid.getPriceInUSD(auction.paymentToken);
    }
}