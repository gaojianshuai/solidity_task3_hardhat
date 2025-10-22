// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title AuctionNFT
 * @dev ERC721 NFT合约，支持铸造和转移，用于拍卖市场
 * 功能包括：
 * - NFT铸造
 * - NFT转移
 * - 元数据管理
 * - 枚举功能
 */
contract AuctionNFT is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIdCounter;
    string private _baseTokenURI;
    
    // 映射记录tokenId到元数据
    mapping(uint256 => string) private _tokenURIs;
    
    // 事件：NFT铸造事件
    event NFTMinted(address indexed to, uint256 indexed tokenId, string tokenURI);
    
    /**
     * @dev 构造函数，初始化NFT合约
     * @param name NFT集合名称
     * @param symbol NFT集合符号
     * @param baseTokenURI 基础元数据URI
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
    }
    
    /**
     * @dev 铸造新的NFT
     * @param to NFT接收者地址
     * @param tokenURI 该NFT的元数据URI
     * @return tokenId 返回铸造的NFT的tokenId
     */
    function mint(address to, string memory tokenURI) 
        external 
        returns (uint256) 
    {
        // 使用计数器生成唯一tokenId
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        
        // 铸造NFT
        _mint(to, tokenId);
        
        // 设置tokenURI
        _setTokenURI(tokenId, tokenURI);
        
        // 触发铸造事件
        emit NFTMinted(to, tokenId, tokenURI);
        
        return tokenId;
    }
    
    /**
     * @dev 批量铸造NFT
     * @param to NFT接收者地址
     * @param tokenURIs 多个NFT的元数据URI数组
     */
    function mintBatch(address to, string[] memory tokenURIs) 
        external 
    {
        for (uint256 i = 0; i < tokenURIs.length; i++) {
            mint(to, tokenURIs[i]);
        }
    }
    
    /**
     * @dev 设置单个NFT的元数据URI
     * @param tokenId NFT的tokenId
     * @param tokenURI 元数据URI
     */
    function _setTokenURI(uint256 tokenId, string memory tokenURI) 
        internal 
        virtual 
    {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = tokenURI;
    }
    
    /**
     * @dev 获取NFT的元数据URI
     * @param tokenId NFT的tokenId
     * @return 返回该NFT的完整元数据URI
     */
    function tokenURI(uint256 tokenId) 
        public 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseTokenURI;
        
        // 如果base URI为空，则返回tokenURI
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        
        // 如果tokenURI不为空，则直接返回
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }
        
        // 否则返回baseURI + tokenId
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }
    
    /**
     * @dev 设置基础URI
     * @param baseTokenURI 新的基础URI
     */
    function setBaseURI(string memory baseTokenURI) 
        external 
        onlyOwner 
    {
        _baseTokenURI = baseTokenURI;
    }
    
    /**
     * @dev 重写父类函数以支持枚举
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
    
    /**
     * @dev 重写支持接口函数
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    /**
     * @dev 获取当前tokenId计数器值
     * @return 返回下一个可用的tokenId
     */
    function getCurrentTokenId() 
        external 
        view 
        returns (uint256) 
    {
        return _tokenIdCounter.current();
    }
}