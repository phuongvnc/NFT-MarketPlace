// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NFT is Ownable, ERC721Enumerable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    
    string public baseURI = "";
    uint256 public limitToken;
    Counters.Counter private _tokenIds;
    mapping(uint256 => string) private _urls;

    constructor(string memory name, string memory symbol, uint256 _limitToken) ERC721(name, symbol) {
        limitToken = _limitToken;
    }

    function ownerTokenIds(address owner) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        require(balance > 0, "Owner dont have tokens");
        uint256[] memory result = new uint256[](balance);
        for (uint256 i; i < balance; i++) {
            result[i] = tokenOfOwnerByIndex(owner, i);
        }
        return result;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, _urls[tokenId]));
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function mintNft(string memory tokenURI_) public canMintToken onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _urls[newItemId] = tokenURI_;
        return newItemId;
    }

    function mintNfts(string[] memory tokenURIs_) public canMintToken onlyOwner {
        uint256 totalTokenCount = tokenURIs_.length;
        for (uint256 i = 0; i < totalTokenCount; i++) { 
            mintNft(tokenURIs_[i]);
        }
    }

    // Modifier
    modifier canMintToken() {
        require(_tokenIds.current() + 1 <= limitToken, "Can't mint token");
        _;
    }
}