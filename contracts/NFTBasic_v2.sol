// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./HoBiToken.sol";

contract NFTBasic {
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    struct NFT {
        uint256 tokenId;
        string tokenName;
    }

    struct fungibleToken {
        string fTokenName;
        string fTokenSymbol;
        uint256 amountToken;
    }

    mapping (address => NFT[]) private ownerToListNFT;
    mapping (uint256 => address) private TokenIdToOwner;
    mapping (address => uint256) private balances;

    mapping (uint256 => bool) private tokenExist;
    mapping (uint256 => string) private idToName;

    mapping (uint256 => fungibleToken[]) private NFTToToken;


    // Mint NFT
    NFT[] private listNFTs;

    function mintNFT(
        uint256 tokenId, 
        string memory tokenName
    ) public payable {
        require(!tokenExist[tokenId], "NFT exist already!!!");
        
        _mint(tokenId, tokenName);
    }

    function _mint( 
        uint256 tokenId, 
        string memory tokenName
    ) internal {
        require(!tokenExist[tokenId], "This NFT exist");

        listNFTs.push(NFT(tokenId, tokenName));
        ownerToListNFT[msg.sender].push(NFT(tokenId, tokenName));
        TokenIdToOwner[tokenId] = msg.sender;
        idToName[tokenId] = tokenName;

        balances[msg.sender]++;
        tokenExist[tokenId] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "This is not Owner.");
        _;
    }

    // Mint multiple NFTs
    function mintNFTs(
        uint256[] memory tokenIds,
        string[] memory tokenNames
    ) public {
        require(tokenIds.length == tokenNames.length, "They do not match together");
        for(uint256 i = 0; i < tokenIds.length; i++) {
            mintNFT(tokenIds[i], tokenNames[i]);
        }
    }



    // Transfer
    function transferToken(
        address to, 
        uint256 tokenId, 
        address contractToken,
        uint256 amountToken
    ) public {
        require(to != address(0), "To address is zero address!!!");
        require(!tokenExist[tokenId], "NFT exist already!!!");

        ERC20(contractToken).transferFrom(msg.sender, to, amountToken);
        _addToken(tokenId, contractToken, amountToken);
    }

    function _addToken(
        uint256 tokenId, 
        address contractToken, 
        uint256 amountToken
    ) internal {
        NFTToToken[tokenId].push(
            fungibleToken(
                ERC20(contractToken).name(), 
                ERC20(contractToken).symbol(), 
                amountToken
            )
        );
    }


    // Transfer NFT





























    // GET Function
    function getBalancesNFT() public view returns (uint256) {
        return balances[msg.sender];
    }

    function getListNFTOfOwner() public view returns (NFT[] memory) {
        return ownerToListNFT[msg.sender];
    }

    function getInfoTokenChild(uint256 tokenId) public view returns (fungibleToken[] memory) {
        return NFTToToken[tokenId];
    }
}