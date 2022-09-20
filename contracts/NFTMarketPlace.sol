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

    // Private properties
    mapping(address => Counters.Counter) private _contractItemId;
    mapping(address => Counters.Counter) private _contractItemsSold;
    mapping(address => Counters.Counter) private _contractItemsCancelled;
    mapping(address => mapping(uint256 => MarketItem)) private _mapNFTAddressToItem;

    EnumerableSet.AddressSet private _supportedNFTAddress;
    address private _newContract;
    address private _oldContract;

    // Events
    event MarketItemCreated(
        uint256 indexed itemId,
        uint256 indexed tokenId,
        address indexed nftAddress,
        address seller,
        address owner,
        uint256 price,
        MarketItemStatus status
    );

    event MarketItemCancelled(
        uint256 indexed itemId,
        uint256 indexed tokenId,
        address indexed nftAddress,
        address seller,
        address owner,
        uint256 price,
        MarketItemStatus status
    );

    event MarketItemSold(
        uint256 indexed itemId,
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

        _contractItemId[nftAddress].increment();

        uint256 itemId = _contractItemId[nftAddress].current();

        _mapNFTAddressToItem[nftAddress][itemId] = MarketItem(
            itemId,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            MarketItemStatus.Active
        );

        emit MarketItemCreated(
            itemId,
            tokenId,
            nftAddress,
            msg.sender,
            address(0),
            price,
            MarketItemStatus.Active
        );
    }

    function buyMarketItem(uint256 itemId, address nftAddress)
        external
        payable
        isSupportNFTAddress(nftAddress)
        isItemExists(itemId, nftAddress)
        nonReentrant {
        MarketItem storage idToMarketItem_ = _mapNFTAddressToItem[nftAddress][itemId];
        uint256 tokenId = idToMarketItem_.tokenId;
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
        _contractItemsSold[nftAddress].increment();

        emit MarketItemSold(
            itemId,
            tokenId,
            nftAddress,
            idToMarketItem_.seller,
            msg.sender,
            idToMarketItem_.price,
            idToMarketItem_.status
        );
    }

    function cancelMarketItem(uint256 itemId, address nftAddress)
        external
        isSupportNFTAddress(nftAddress)
        isItemExists(itemId, nftAddress)
        nonReentrant
    {
        
        MarketItem storage idToMarketItem_ = _mapNFTAddressToItem[nftAddress][itemId];
        require(msg.sender == idToMarketItem_.seller, "Only Seller can cancel");
        require(
            idToMarketItem_.status == MarketItemStatus.Active, "Item must be active"
        );
        idToMarketItem_.status = MarketItemStatus.Cancelled;
        _contractItemsCancelled[nftAddress].increment();
        IERC721 nft = IERC721(nftAddress);
        nft.transferFrom(address(this), msg.sender, idToMarketItem_.tokenId);

        emit MarketItemCancelled (
            itemId,
            idToMarketItem_.tokenId,
            nftAddress,
            idToMarketItem_.seller,
            msg.sender,
            idToMarketItem_.price,
            MarketItemStatus.Cancelled
        );
    }

    // Fetch NFT Item
    function fetchMarketItems(address nftAddress) 
        public 
        view 
        isSupportNFTAddress(nftAddress) 
        returns (MarketItem[] memory)  
    {
        uint256 itemCount = _contractItemId[nftAddress].current();
        uint256 unsoldItemCount = _contractItemId[nftAddress].current() -
            _contractItemsSold[nftAddress].current() -
            _contractItemsCancelled[nftAddress].current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (_mapNFTAddressToItem[nftAddress][i + 1].status == MarketItemStatus.Active) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = _mapNFTAddressToItem[nftAddress][currentId];
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
        uint256 totalItemCount = _contractItemId[nftAddress].current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (_mapNFTAddressToItem[nftAddress][i + 1].owner == sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (_mapNFTAddressToItem[nftAddress][i + 1].owner == sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = _mapNFTAddressToItem[nftAddress][currentId];
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
        uint256 totalItemCount = _contractItemId[nftAddress].current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (_mapNFTAddressToItem[nftAddress][i + 1].seller == sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (_mapNFTAddressToItem[nftAddress][i + 1].seller == sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = _mapNFTAddressToItem[nftAddress][currentId];
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
            uint256 nftTotalSupply = _contractItemId[nftAddress].current();

            IMigration _newMarketPlace = IMigration(_newContract);
            if (!_newMarketPlace.isNFTAddressSupported(nftAddress)) {
                _newMarketPlace.addNFTSupportAddress(nftAddress);  
            }

            for (uint256 j = 1; j <= nftTotalSupply; j++) {
                MarketItem storage item = _mapNFTAddressToItem[nftAddress][j];
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
        _contractItemId[nftAddress].increment();
        if (item.status == MarketItemStatus.Sold) {
            _contractItemsSold[nftAddress].increment();
        } else if (item.status == MarketItemStatus.Cancelled) {
            _contractItemsCancelled[nftAddress].increment();
        }
        _mapNFTAddressToItem[nftAddress][item.itemId] = item;
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

    modifier isItemExists(uint256 id, address nftAddress) {
        require(id <= _contractItemId[nftAddress].current() && id > 0, "Could not find item");
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