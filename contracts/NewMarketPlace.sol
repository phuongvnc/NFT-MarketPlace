// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./InterfaceNFT.sol";

contract Marketplace is Ownable, ReentrancyGuard, IMigration {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    // Private properties
    mapping(address => mapping(uint256 => MarketItem)) private _mapNFTAddressToItem;
    mapping(address => EnumerableSet.UintSet) _saleTokenIds;

    EnumerableSet.AddressSet private _supportedNFTAddress;
    address private _newContract;
    address private _oldContract;

    // Events
    event MarketItemCreated(
        uint256 indexed tokenId,
        address indexed nftAddress,
        address seller,
        address owner,
        uint256 price,
        MarketItemStatus status
    );

    event MarketItemCancelled(
        uint256 indexed tokenId,
        address indexed nftAddress,
        address seller,
        address owner,
        uint256 price,
        MarketItemStatus status
    );

    event MarketItemSold(
        uint256 indexed tokenId,
        address indexed nftAddress,
        address seller,
        address owner,
        uint256 price,
        MarketItemStatus status
    );

    // Action NFT Item
    function createMarketItem(uint256 tokenId, address nftAddress, uint256 price)
        external
        payable
        isSupportNFTAddress(nftAddress)
        isOnlyItemOwner(tokenId, nftAddress)
        hasTransferApproval(tokenId, nftAddress)
    {
        require(price > 0, "Price must be at least 1 wei");

        IERC721 nft = IERC721(nftAddress);
        nft.transferFrom(msg.sender, address(this), tokenId);

        _mapNFTAddressToItem[nftAddress][tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            MarketItemStatus.Active
        );
        _saleTokenIds[nftAddress].add(tokenId);

        emit MarketItemCreated(
            tokenId,
            nftAddress,
            msg.sender,
            address(0),
            price,
            MarketItemStatus.Active
        );
    }

    function buyMarketItem(uint256 tokenId, address nftAddress)
        external
        payable
        isSupportNFTAddress(nftAddress)
        isItemExists(tokenId, nftAddress)
        nonReentrant {
        MarketItem storage idToMarketItem_ = _mapNFTAddressToItem[nftAddress][tokenId];
        require(
            idToMarketItem_.status == MarketItemStatus.Active, "Item is not active"
        );
        require(msg.sender != idToMarketItem_.seller, "Seller can't be buyer");
        require(
            msg.value == idToMarketItem_.price,
            "Please submit the asking price in order to complete the purchase"
        );

        IERC721 nft = IERC721(nftAddress);
        nft.transferFrom(address(this), msg.sender, tokenId);

        payable(idToMarketItem_.seller).transfer(msg.value);

        idToMarketItem_.owner = payable(msg.sender);
        idToMarketItem_.status = MarketItemStatus.Sold;

        emit MarketItemSold(
            tokenId,
            nftAddress,
            idToMarketItem_.seller,
            msg.sender,
            idToMarketItem_.price,
            idToMarketItem_.status
        );
    }

    function cancelMarketItem(uint256 tokenId, address nftAddress)
        external
        isSupportNFTAddress(nftAddress)
        isItemExists(tokenId, nftAddress)
        nonReentrant
    {
        
        MarketItem storage idToMarketItem_ = _mapNFTAddressToItem[nftAddress][tokenId];
        require(msg.sender == idToMarketItem_.seller, "Only Seller can cancel");
        require(
            idToMarketItem_.status == MarketItemStatus.Active, "Item must be active"
        );    
        IERC721 nft = IERC721(nftAddress);
        nft.transferFrom(address(this), msg.sender, idToMarketItem_.tokenId);

        emit MarketItemCancelled (
            idToMarketItem_.tokenId,
            nftAddress,
            idToMarketItem_.seller,
            msg.sender,
            idToMarketItem_.price,
            MarketItemStatus.Cancelled
        );
        _saleTokenIds[nftAddress].remove(tokenId);
        delete _mapNFTAddressToItem[nftAddress][tokenId];

    }

    // Fetch NFT Item
    function fetchMarketItems(address nftAddress) 
        public 
        view 
        isSupportNFTAddress(nftAddress) 
        returns (MarketItem[] memory)  
    {

        uint256 totalItemCount = _saleTokenIds[nftAddress].length();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            uint256 tokenId = _saleTokenIds[nftAddress].at(i);
            if (_mapNFTAddressToItem[nftAddress][tokenId].status == MarketItemStatus.Active) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            uint256 tokenId = _saleTokenIds[nftAddress].at(i);
            if (_mapNFTAddressToItem[nftAddress][tokenId].status == MarketItemStatus.Active) {
                MarketItem storage currentItem = _mapNFTAddressToItem[nftAddress][tokenId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchMyNFTs(address sender, address nftAddress) 
        public 
        view 
        isSupportNFTAddress(nftAddress) 
        returns (MarketItem[] memory) 
    {
        uint256 totalItemCount = _saleTokenIds[nftAddress].length();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            uint256 tokenId = _saleTokenIds[nftAddress].at(i);
            if (_mapNFTAddressToItem[nftAddress][tokenId].owner == sender) {
                itemCount += 1;
            }
        }
  
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            uint256 tokenId = _saleTokenIds[nftAddress].at(i);
            if (_mapNFTAddressToItem[nftAddress][tokenId].owner == sender) {
                MarketItem storage currentItem = _mapNFTAddressToItem[nftAddress][tokenId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchItemsCreated(address sender, address nftAddress) 
        public 
        view 
        isSupportNFTAddress(nftAddress) 
        returns (MarketItem[] memory) 
    {
        uint256 totalItemCount = _saleTokenIds[nftAddress].length();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            uint256 tokenId = _saleTokenIds[nftAddress].at(i);
            if (_mapNFTAddressToItem[nftAddress][tokenId].owner == sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            uint256 tokenId = _saleTokenIds[nftAddress].at(i);
            if (_mapNFTAddressToItem[nftAddress][i + 1].seller == sender) {
                MarketItem storage currentItem = _mapNFTAddressToItem[nftAddress][tokenId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    fallback() external payable {}

    receive() external payable {}

    // INFTSupport
    function addNFTSupportAddress(address nftAddress_) external {
        require(
            nftAddress_ != address(0),
            "NFTMarketplace: nftAddess is not zero"
        );
        require(
            _supportedNFTAddress.add(nftAddress_),
            "NFTMarketplace: already supported"
        );
    }

    function isNFTAddressSupported(address nftAddress_)
        external
        view
        returns (bool)
    {
        return _supportedNFTAddress.contains(nftAddress_);
    }

    // Migration contract
    function setOldContract(address oldContract) public onlyOwner {
        _oldContract = oldContract;
    }

    function setNewContract(address newContract) public onlyOwner {
        _newContract = newContract;
    }

    function migrate() public payable onlyOwner canMigrate { 
        for (uint256 i = 0; i < _supportedNFTAddress.length(); i++) {

            address nftAddress = _supportedNFTAddress.at(i);
            uint256 nftTotalSupply = _saleTokenIds[nftAddress].length();

            IMigration _newMarketPlace = IMigration(_newContract);
            if (!_newMarketPlace.isNFTAddressSupported(nftAddress)) {
                _newMarketPlace.addNFTSupportAddress(nftAddress);  
            }

            for (uint256 j = 0; j < nftTotalSupply; j++) {
                uint256 tokenId = _saleTokenIds[nftAddress].at(j);
                MarketItem storage item = _mapNFTAddressToItem[nftAddress][tokenId];
                if (_newMarketPlace.transferMarketItem(nftAddress, item)) {
                    if (item.status == MarketItemStatus.Active) {
                        IERC721 nft = IERC721(nftAddress);
                        nft.transferFrom(address(this), _newContract, item.tokenId);
                    }
                }
            }
        }

        uint256 amount = address(this).balance;
        if (amount > 0) {
            payable(_newContract).transfer(amount);
        }
    }

    function transferMarketItem(address nftAddress, MarketItem memory item) external onlyOldContract returns (bool) {
        _saleTokenIds[nftAddress].add(item.tokenId);
        _mapNFTAddressToItem[nftAddress][item.tokenId] = item;

        return true;
    }


    // Modifier
    modifier isSupportNFTAddress(address nftAddress) {
        require(_supportedNFTAddress.contains(nftAddress), "Market place is not support NFT");
        _;
    }

    modifier isOnlyItemOwner(uint256 tokenId, address nftAddress) {
        require(
            IERC721(nftAddress).ownerOf(tokenId) == msg.sender,
            "Sender does not own the item"
        );
        _;
    }

    modifier hasTransferApproval(uint256 tokenId, address nftAddress) {
        require(
            IERC721(nftAddress).isApprovedForAll(_msgSender(), address(this)),
            "Market is not approved"
        );
        _;
    }

    modifier isItemExists(uint256 tokenId, address nftAddress) {
        require(_saleTokenIds[nftAddress].contains(tokenId), "Could not find item");
        _;
    }

    modifier canMigrate() {
        require(_newContract != address(0), "Contract have been migrated");
        _;
    }

    modifier onlyOldContract() {
        require(_oldContract != address(0) && msg.sender == _oldContract, "Old Contract isn't correct");
        _;
    }

    modifier allPermission() {
        require((owner() == msg.sender) || (_newContract != address(0) && msg.sender == _newContract), "Address not enough permission");
        _;
    }

}