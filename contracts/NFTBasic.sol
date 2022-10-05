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

    mapping (address => uint256) private ownerToNFT;
    mapping (uint256 => address) private TokenIdToOwner;
    mapping (address => uint256) private balances;

    mapping (uint256 => bool) private tokenExist;
    mapping (uint256 => string) private idToName;

    mapping (uint256 => fungibleToken[]) private NFTToToken;

    mapping (address => bool) private contractExist;




    // Mint NFT
    function mintNFT(uint256 tokenId, string memory tokenName) 
        public 
        payable {
        _mint(msg.sender, tokenId, tokenName);
    }

    function _mint(
        address to, 
        uint256 tokenId, 
        string memory tokenName
    ) internal {
        require(to != address(0), "To address is zero address");
        require(!tokenExist[tokenId], "This NFT exist");

        ownerToNFT[to] = tokenId;
        TokenIdToOwner[tokenId] = to;
        idToName[tokenId] = tokenName;

        balances[to]++;
        tokenExist[tokenId] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "This is not Owner.");
        _;
    }


    // Transfer
    function transferToken(
        address to, 
        uint256 tokenId, 
        address contractToken,
        uint256 amountToken
    ) public {
        bool sendToken = ERC20(contractToken).transferFrom(msg.sender, to, amountToken);

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
                ERC20(contractToken).symbol(), amountToken
            )
        );
    }




























    // GET Function
    function getBalancesNFT() public view returns (uint256) {
        return balances[msg.sender];
    }

    function getInfoTokenChild(uint256 tokenId) public view returns (fungibleToken[] memory) {
        return NFTToToken[tokenId];
    }
}