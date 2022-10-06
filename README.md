# NFT MarketPlace Guideline
This repository has 2 main contracts to be NFT and NFTMarketPlace
- **NFT**: Contract support created NFTs follow protocol [IEP-721](https://ethereum.org/vi/developers/docs/standards/tokens/erc-721/).
- **NFTMarketPlace**: Contract support buy, sell NFTs on Market.

*Note: This document just guide some function necessary in NFT and NFTMarketPlace*

------------

### 1.NFT
**Constructor of NFT**
```
constructor(string memory name, string memory symbol, uint256 _limitToken)
```

**After that is deploying the NFT Contract, you need approval for the NFTMarketPlace address which helps can use all NFT token**
```
function setApprovalForAll(address _operator, bool _approved) external
```

**Get all NFT token of address**
```
function ownerTokenIds(address owner) external view returns (uint256[] memory)
```

**Mint a NFT token**
```
function mint(string memory tokenURI_) public onlyOwner returns (uint256)
```

**Mint many NFT tokens**
```
function mints(string[] memory tokenURIs_) public returns (uint256[] memory)
```

**Burn NFT token**
```
function burn(uint256 tokenId) public virtual
```

### 2.NFTMarketPlace

**Add NFT Contract address that can buy and sell on the market**
```
function addNFTSupportAddress(address nftAddress_) external
```

**Assign a user address that can call l addNFTSupportAddress method**
```
function setApprover(address operator, bool approved) external
```

**Sale a NFT token on the market**
```
function createMarketItem(uint256 tokenId, address nftAddress, uint256 price) public payable
```

**Sale NFT tokens on the market**
```
function createMarketItems(uint256[] memory tokenIds, address nftAddress, uint256 price) external payable
```

**Change price NFT token**
```
function changeMarketItem(uint256 tokenId, address nftAddress, uint256 price) public
```

**Buy NFT token**
```
function buyMarketItem(uint256 tokenId, address nftAddress) external payable
```

**Cancel sale NFT token**
```
function cancelMarketItem(uint256 tokenId, address nftAddress) external
```

**Get all NFT token sale on the market**
```
 function fetchMarketItems(address nftAddress) public view
```

**Get all user's NFT tokens that were bought on the market**
```
function fetchMyNFTs(address sender, address nftAddress) public view
```

**Get all user's NFT tokens that are selling on the market**
```
function fetchItemsCreated(address sender, address nftAddress) public view
```