// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IMarketItem {
    
    struct MarketItem {
        uint256 itemId;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        MarketItemStatus status;
    }

    enum MarketItemStatus {
        Active,
        Sold,
        Cancelled
    }
}

interface INFTSupport {
    function addNFTSupportAddress(address nftAddress_) external;
    function isNFTAddressSupported(address nftAddress_) external view returns (bool);
}

interface IMigration is INFTSupport, IMarketItem {
    function transferMarketItem(address nftAddress, MarketItem memory item) external returns (bool);
}