// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTTokenTask is ERC721,ERC721URIStorage,Ownable {
     uint256 private _tokenId = 1;
     string  private  _baseTokenURI;

     constructor(string memory name,string memory symbol) ERC721(name,symbol) Ownable(msg.sender){
     }

     function mintNFT(address recipient,string memory uri) external onlyOwner returns(uint256){
          uint256 tokenId = _tokenId++;
          _safeMint(recipient,tokenId);
          _setTokenURI(tokenId,uri);
          return tokenId;
     }

     function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721URIStorage) returns (bool) {
          return super.supportsInterface(interfaceId);
     }

     function getNextTokenId() public view returns(uint256) {
          return _tokenId;
     }

     function tokenURI(uint256 tokenId) public view override (ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
     }

     function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
     }

     function _baseURI() internal view override returns(string memory) {
          return _baseTokenURI;
     }
     
}

