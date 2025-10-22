// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../auction/Auction.sol";

/**
 * @title UAuction
 * @dev 可升级的拍卖合约，使用UUPS升级模式
 * 继承基础拍卖合约的所有功能，并支持升级
 */
contract UAuction is 
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    // 初始化函数，替代构造函数
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
    }
    
    // UUPS升级授权函数
    function _authorizeUpgrade(address newImplementation) 
        internal 
        override 
        onlyOwner 
    {}
    
    // 添加版本信息以便识别
    function version() public pure returns (string memory) {
        return "v1.0.0";
    }
}