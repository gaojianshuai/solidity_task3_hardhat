// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title PriceConverter
 * @dev 价格转换库，使用Chainlink预言机获取代币价格
 * 功能包括：
 * - 获取ETH/USD价格
 * - 获取ERC20/USD价格
 * - 转换代币金额为美元价值
 */
library PriceConverter {
    // Chainlink ETH/USD价格预言机地址（Sepolia测试网）
    address public constant ETH_USD_PRICE_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    
    // 常见ERC20代币的价格预言机映射
    mapping(address => address) public tokenPriceFeeds;
    
    // 精度常量
    uint256 private constant PRICE_DECIMALS = 8;
    uint256 private constant ETH_DECIMALS = 18;
    
    /**
     * @dev 设置代币价格预言机
     * @param token 代币地址
     * @param priceFeed 价格预言机地址
     */
    function setTokenPriceFeed(address token, address priceFeed) internal {
        tokenPriceFeeds[token] = priceFeed;
    }
    
    /**
     * @dev 获取最新价格
     * @param priceFeed 价格预言机地址
     * @return 最新价格
     */
    function getLatestPrice(address priceFeed) internal view returns (uint256) {
        AggregatorV3Interface priceFeedContract = AggregatorV3Interface(priceFeed);
        
        (, int256 price, , , ) = priceFeedContract.latestRoundData();
        require(price > 0, "Invalid price");
        
        return uint256(price);
    }
    
    /**
     * @dev 获取代币价格的美元价值
     * @param amount 代币数量
     * @param token 代币地址（address(0) 表示ETH）
     * @return 美元价值（带8位小数）
     */
    function getPriceInUSD(uint256 amount, address token) 
        internal 
        view 
        returns (uint256) 
    {
        if (amount == 0) return 0;
        
        address priceFeed;
        uint256 tokenDecimals;
        
        if (token == address(0)) {
            // ETH价格
            priceFeed = ETH_USD_PRICE_FEED;
            tokenDecimals = ETH_DECIMALS;
        } else {
            // ERC20代币价格
            priceFeed = tokenPriceFeeds[token];
            require(priceFeed != address(0), "Price feed not set");
            tokenDecimals = 18; // 假设大多数ERC20代币使用18位小数
        }
        
        uint256 price = getLatestPrice(priceFeed);
        
        // 计算美元价值：amount * price / (10^tokenDecimals)
        // 调整精度到8位小数
        return (amount * price) / (10 ** tokenDecimals);
    }
}