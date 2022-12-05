// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

contract URABlindBox is ERC721URIStorage, ERC721Enumerable, ERC721Burnable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address marketplaceAddress;
    string baseURI;
    uint256 private _rand = 1;

    uint256 public interval = 10;

    string[4] URI = [
        "Common",
        "Rare",
        "Epic",
        "Legend"
    ];

    //Mapping tokenIds to their opening time (iat)
    mapping(uint256 => uint256) private openTime;

    event BoxMinted(
        address owner,
        uint256 boxId,
        string uri
    );

    event BoxOpened(
        address owner,
        uint256 boxId,
        string uri
    );

    constructor(address _marketplaceAddress, string memory _baseURI) ERC721("URA Blind Box", "UBox") {
        marketplaceAddress = _marketplaceAddress;
        baseURI = _baseURI;
    }

    function _isNotOpened(uint256 _boxId) public view returns (bool) {
        // Compare string keccak256 hashes to check equality
        string memory _tokenURI = tokenURI(_boxId);
        if (keccak256(abi.encodePacked(baseURI)) == keccak256(abi.encodePacked(_tokenURI))) {
            return true;
        }
        return false;
    }

    function _getRandom(uint256 _start, uint256 _end) private returns(uint256){
        if (_start == _end) {
            return _start;
        }
        uint256 _length = _end - _start; 
        uint256 _random = uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty, _rand)));
        _random = _random % _length + _start;
        _rand++;
        return _random;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function remainingTime(uint256 _boxId) public view returns(uint256) {
        if (openTime[_boxId] < block.timestamp) {
            return 0;
        }
        return openTime[_boxId] - block.timestamp;
    }

    function mintBox() public returns (uint) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, baseURI);
        openTime[newItemId] = block.timestamp + interval;
        setApprovalForAll(marketplaceAddress, true);
        emit BoxMinted(msg.sender, newItemId, baseURI);
        return newItemId;
    }

    function openBox(uint256 _boxId) public returns (uint256) {
        require(ownerOf(_boxId) == msg.sender, "You are not the owner of this box");
        require(_isNotOpened(_boxId), "This box is already opened");
        require(block.timestamp >= openTime[_boxId], "You have to wait more");
        uint256 random = _getRandom(0, 100);
        uint256 indexURI = 0;
        // 74% Common
        if (random >= 98 && random < 100) {
            // 2% Legend
            indexURI = 3;
        }
        else if (random >= 92 && random < 98) {
            // 6% Epic
            indexURI = 2;
        }
        else if (random >= 74 && random < 92) {
            // 18% Rare
            indexURI = 1;
        }
        _setTokenURI(_boxId, URI[indexURI]);
        emit BoxOpened(msg.sender, _boxId, URI[indexURI]);
        return _boxId;
    }
}