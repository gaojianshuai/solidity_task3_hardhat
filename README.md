markdown

# NFT 拍卖市场

一个基于 Hardhat 框架开发的去中心化 NFT 拍卖市场，集成了 Chainlink 预言机、UUPS 合约升级和工厂模式等高级功能。

## 🌟 项目特色

- **🖼️ NFT 拍卖**: 支持 ERC721 NFT 的创建和拍卖
- **💰 多币种支付**: 支持 ETH 和 ERC20 代币出价
- **🔗 Chainlink 集成**: 实时价格转换和跨链功能
- **🔄 合约升级**: UUPS 代理模式实现安全升级
- **🏭 工厂模式**: 类似 Uniswap V2 的拍卖管理
- **📊 动态手续费**: 根据拍卖金额智能调整费率
- **🧪 完整测试**: 全面的单元测试和集成测试

## 项目架构

### 核心功能

1. **AuctionNFT** - ERC721 NFT合约
   - NFT铸造和转移
   - 元数据管理
   - 批量铸造功能

2. **Auction** - 拍卖核心合约
   - 创建和管理拍卖
   - 支持ETH和ERC20出价
   - 动态手续费计算
   - 集成Chainlink价格预言机

3. **AuctionFactory** - 工厂合约
   - 使用最小代理模式创建拍卖
   - 管理所有拍卖实例
   - 提供查询接口

4. **PriceConverter** - 价格转换库
   - 集成Chainlink ETH/USD价格预言机
   - 支持ERC20代币价格转换
   - 实时美元价值计算

5. **UAuction** - 可升级拍卖合约
   - UUPS代理升级模式
   - 支持合约逻辑升级
   - 保持状态不变

### 技术特性

- **工厂模式**: 类似Uniswap V2的工厂合约管理
- **价格预言机**: Chainlink实时价格数据
- **合约升级**: UUPS透明代理升级
- **动态手续费**: 根据拍卖金额调整费率
- **安全机制**: 重入攻击防护、权限控制

## 文件目录结构
contracts/
├── interfaces/ # 接口定义
├── tokens/ # NFT代币合约
│ └── AuctionNFT.sol
├── auction/ # 拍卖核心逻辑
│ └── Auction.sol
├── factory/ # 工厂模式管理
│ └── AuctionFactory.sol
├── oracles/ # 预言机集成
│ └── PriceConverter.sol
└── upgrades/ # 可升级合约
└── UAuction.sol

scripts/
├── deploy.js # 部署脚本
└── upgrade.js # 升级脚本

test/ # 测试文件
hardhat.config.js # Hardhat配置

text

## 安装和运行

### 环境要求

- Node.js 16+
- npm 或 yarn
- Hardhat

### 安装步骤

```bash
cd nft-auction-market
```
## 安装依赖
```bash

npm install
```
## 配置环境变量

```bash
vi .env
# 编辑 .env 文件，填入你的私钥和API密钥
```
## 编译合约

```bash
npx hardhat compile
```
## 运行测试

```bash
npx hardhat test
```

## 部署到测试网
## 配置网络参数
```bash
在 hardhat.config.js 中配置测试网RPC URL和私钥
```
## 部署合约

```bash
npx hardhat run scripts/deploy.js --network sepolia
```
## 验证合约

```bash
npx hardhat verify --network sepolia <合约地址>
```
## 功能说明
## NFT铸造

## 用户可以通过NFT合约铸造自己的NFT：

```javascript
// 铸造单个NFT
await nft.mint(userAddress, tokenURI);

// 批量铸造
await nft.mintBatch(userAddress, [tokenURI1, tokenURI2]);
创建拍卖
NFT持有者可以创建拍卖：

javascript
await factory.createAuction(
  nftAddress,     // NFT合约地址
  tokenId,        // NFT tokenId
  paymentToken,   // 支付代币（address(0)表示ETH）
  startPrice,     // 起拍价
  startTime,      // 开始时间
  duration        // 拍卖时长
);
```

## 参与拍卖
用户可以使用ETH或ERC20代币出价：

```javascript
// ETH出价
await auction.bid({ value: bidAmount });

// ERC20出价
await auction.bidWithERC20(bidAmount);
```
## 价格计算
集成Chainlink预言机，实时计算美元价值：

```solidity
// 获取出价的美元价值
uint256 usdValue = amount.getPriceInUSD(paymentToken);
```
## 合约升级
支持UUPS模式的合约升级：

```javascript
// 部署新版本
const UAuctionV2 = await ethers.getContractFactory("UAuctionV2");
await upgrades.upgradeProxy(proxyAddress, UAuctionV2);
```
## 测试覆盖
```bash
项目包含完整的测试套件，覆盖：

NFT铸造和转移

拍卖创建和出价

工厂模式管理

价格预言机计算

合约升级功能

安全防护机制
```
## 运行测试：

```bash
npx hardhat test
```
## 部署地址
```bash
在Sepolia测试网的部署地址：

NFT合约: 0x...

拍卖实现: 0x...

工厂合约: 0x...

可升级拍卖: 0x...
```
## 安全考虑
```bash
使用ReentrancyGuard防护重入攻击

严格的权限控制

输入参数验证

安全的资金转移

升级模式的安全授权
```

## 运行说明

1. **安装依赖**:
```bash
npm install @openzeppelin/contracts @chainlink/contracts @nomiclabs/hardhat-ethers hardhat-deploy
```
## 配置环境:
创建 .env 文件并配置：

```bash
PRIVATE_KEY=你的私钥
SEPOLIA_RPC_URL=你的Sepolia RPC URL
ETHERSCAN_API_KEY=你的Etherscan API密钥
```
## 编译合约:

```bash
npx hardhat compile
```
## 运行测试:

```bash
npx hardhat test
```
## 部署到测试网:

```bash
npx hardhat run scripts/deploy.js --network sepolia
```
这个完整的NFT拍卖市场项目包含了所有要求的功能：

✅ NFT铸造和转移

✅ 拍卖创建、出价、结束

✅ 工厂模式管理

✅ Chainlink预言机价格计算

✅ UUPS合约升级

✅ 动态手续费

✅ 完整测试覆盖

✅ 详细文档