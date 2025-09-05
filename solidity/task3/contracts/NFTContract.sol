// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

//NFT合约
contract NFTContract is ERC721,ERC721URIStorage,Ownable {
    string private _baseTokenURI;
    uint256 private _tokenId = 1;
    event NFTminted(address indexed to,uint256 indexed tokenId,string tokenURI);

    constructor() ERC721("myNFT", "MFT") Ownable(msg.sender) {
    }

    //铸造NFT
    function mintNFT(address to,string memory uri) external onlyOwner returns(uint256) {
        uint256 tokenId = _tokenId++;
        console.log("mintNFT(),tokenId:%d",tokenId);
        _safeMint(to,tokenId);
        _setTokenURI(tokenId,uri);
        emit NFTminted(to,tokenId,uri);
        return tokenId;
    }

    //检查NFT是否存在
    function exists(uint256 tokenId) external view returns(bool) {
        return _ownerOf(tokenId) != address(0);
    }

    //获取tokenId对应的URI
    function tokenURI(uint256 tokenId) public view  override(ERC721, ERC721URIStorage)  returns(string memory) {
        return super.tokenURI(tokenId);
    }

    //设置基础URI
    function setBaseURI(string memory baseURI) internal  onlyOwner {
        _baseTokenURI = baseURI;
    }

    //获取基础URI
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }


   function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721URIStorage) returns (bool) {
          return super.supportsInterface(interfaceId);
    }


}

