// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NFT is Ownable, ERC721Enumerable, Pausable {
    using Counters for Counters.Counter;
    
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

    function mintNfts(string[] memory tokenURIs_) public canMintToken onlyOwner returns (uint256[] memory) {
        uint256 totalTokenCount = tokenURIs_.length;
        uint256[] memory listTokenId = new uint256[](totalTokenCount);
        for (uint256 i = 0; i < totalTokenCount; i++) {
            uint256 tokenId = mintNft(tokenURIs_[i]);
            listTokenId[i] = tokenId;
        }
        return listTokenId;
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }
    // Override Pausable
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Modifier
    modifier canMintToken() {
        require(_tokenIds.current() + 1 <= limitToken, "Can't mint token");
        _;
    }
}