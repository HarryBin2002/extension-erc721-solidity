// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract NFTAndAssets {

    constructor() {}

    // NFT struct
    struct NFT {
        uint256 tokenId;
        string tokenName;
        uint256 tokenId_parents;
    }

    // controller variables
    // manage list NFTs of owner by address's owner
    mapping (address => NFT[]) private ownerToListNFT;
    // checking that NFT is owned by who
    mapping (uint256 => address) private tokenIdToOwner;
    // manage the balances of address's owner
    mapping (address => uint256) private balances;

    // linking token's ID and token's Name
    mapping (uint256 => string) private idToName;
    // checking a NFT does exist or not.
    mapping (uint256 => bool) private tokenExist;

    // manage list NFT children by token ID of NFT parents
    mapping (uint256 => NFT[]) private idParentToListNFTs;
    // checking that the NFT child is owned by who
    mapping (uint256 => uint256) private idChildToParents;

    // Token ERC20 
    mapping (uint256 => FT[]) private NFTToToken;



    // Array to store the list of NFTs
    NFT[] private listNFTs;
    // Mint 1 NFT
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

        listNFTs.push(NFT(tokenId, tokenName, 0));
        ownerToListNFT[msg.sender].push(NFT(tokenId, tokenName, 0));
        tokenIdToOwner[tokenId] = msg.sender;

        balances[msg.sender]++;
        tokenExist[tokenId] = true;
        idToName[tokenId] = tokenName;

        idChildToParents[tokenId] = 0;
        tokenExist[0] = true;
        tokenIdToOwner[0] = msg.sender;
    }

    // Mint multiple NFT
    function mintMultipleNFTs(
        uint256[] memory tokenIds, 
        string[] memory tokenNames
    ) public payable {
        require(tokenIds.length == tokenNames.length, "They do not match together");
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            mintNFT(tokenIds[i], tokenNames[i]);
        }
    }

    // Mint NFT children
    function mintNFTChild(
        uint256 tokenId,
        string memory tokenName,
        uint256 tokenId_parents
    ) public payable {
        require(!tokenExist[tokenId], "TokenId NFT children exist!!!");
        require(tokenExist[tokenId_parents], "TokenId NFT parent does not exist!!!");
        
        idParentToListNFTs[tokenId_parents].push(
            NFT(tokenId, tokenName, tokenId_parents)
        );
        idChildToParents[tokenId] = tokenId_parents;
        tokenIdToOwner[tokenId] = msg.sender;

        balances[msg.sender] += 1;
        tokenExist[tokenId] = true;
        idToName[tokenId] = tokenName;
    }

    // Mint multiple NFT children
    function mintMultipleNFTsChildren(
        uint256[] memory tokenIds, 
        string[] memory tokenNames, 
        uint256 tokenIds_parents
    ) public payable {
        require(tokenIds.length == tokenNames.length, "They do not match together");

        for (uint256 j = 0; j < tokenIds.length; j++) {
            mintNFTChild(tokenIds[j], tokenNames[j], tokenIds_parents);
        }

    }   

    // Remove NFT
    function removeNFT(
        uint256 tokenId
    ) public {
        require(tokenExist[tokenId], "NFT child does not exist!!!");
        require(tokenExist[idChildToParents[tokenId]], "NFT parent does not exist!!!");
        require(tokenIdToOwner[idChildToParents[tokenId]] == msg.sender, "This is not owner of NFT");

        uint256 tokenId_parents = idChildToParents[tokenId];
        if (tokenId_parents == 0) {
            // remove NFT parents
            _removeNFTParents(tokenId);
        } else {
            // remove NFT children
            _removeNFTChildren(tokenId, tokenId_parents);
        }
    }

    function _removeNFTParents(uint256 tokenId) internal {
        // remove all NFT children
        NFT[] memory listChild_exam = idParentToListNFTs[tokenId];
        for(uint256 i = 0; i < listChild_exam.length; i++) {
            _removeNFTChildren(listChild_exam[i].tokenId, tokenId);
        }
        

        // remove NFT in ListNFTs
        uint256 index = _findIndexNFTChild(tokenId, idChildToParents[tokenId]);
        for(uint256 i = index; i < listNFTs.length - 1; i++) {
            listNFTs[i] = listNFTs[i+1];
        }

        // remove NFT in List NFTs
        for(uint256 i = index; i < ownerToListNFT[msg.sender].length - 1; i++) {
            ownerToListNFT[msg.sender][i] = ownerToListNFT[msg.sender][i+1]; 
        }
        ownerToListNFT[msg.sender].pop();

        tokenExist[tokenId] = false;
        balances[msg.sender] -= 1;
        tokenIdToOwner[tokenId] = address(0);

    }

    function _removeNFTChildren(uint256 tokenId, uint256 tokenId_parents) internal {
        uint256 index = _findIndexNFTChild(tokenId, tokenId_parents);
        for(uint256 i = index; i < idParentToListNFTs[tokenId_parents].length - 1; i++) {
            idParentToListNFTs[tokenId_parents][i] = idParentToListNFTs[tokenId_parents][i + 1];
        }
        idParentToListNFTs[tokenId_parents].pop(); // remove one index 

        // Update 
        tokenExist[tokenId] = false;
        balances[msg.sender] -= 1;
    }

    function _findIndexNFTChild(uint256 tokenId, uint256 tokenId_parents) internal view returns (uint256 index) {
        NFT[] memory listChild_exam = idParentToListNFTs[tokenId_parents];
        for(uint256 i = 0; i < listChild_exam.length; i++) {
            if(listChild_exam[i].tokenId == tokenId) {
                return i;
            }
        }
    }

    // Transfer 
    function transfer(address to, uint256 tokenId) public {
        require(msg.sender != address(0), "msg.sender address is an empty address");
        require(to != address(0), "To address is an empty address");
        require(msg.sender != to, "msg.sender is not equal to To");
        require(tokenExist[tokenId], "This NFT does not exist!!!");
        
        NFT memory NFT_Parent_exam = ownerToListNFT[msg.sender][_findIndexNFTChild(tokenId, 0)];
        NFT[] memory ListNFT_Child_exam = idParentToListNFTs[tokenId];

        _removeNFTParents(tokenId);

        _addNFTParents(to, NFT_Parent_exam, ListNFT_Child_exam);
    }

    function _addNFTParents(
        address to,
        NFT memory NFT_Parent_exam,
        NFT[] memory ListNFT_Child_exam
    ) internal {
        // add NFT parent again
        listNFTs.push(NFT_Parent_exam);

        ownerToListNFT[to].push(NFT_Parent_exam);
        tokenIdToOwner[NFT_Parent_exam.tokenId] = to;

        balances[to] += 1;
        tokenExist[NFT_Parent_exam.tokenId] = true;
        idToName[NFT_Parent_exam.tokenId] = NFT_Parent_exam.tokenName;

        // add list NFT children again
        for(uint256 i = 0; i < ListNFT_Child_exam.length; i++) {
            idParentToListNFTs[NFT_Parent_exam.tokenId].push(
                NFT(
                    ListNFT_Child_exam[i].tokenId, 
                    ListNFT_Child_exam[i].tokenName, 
                    NFT_Parent_exam.tokenId
                )
            );
            idChildToParents[ListNFT_Child_exam[i].tokenId] = NFT_Parent_exam.tokenId;

            balances[to] += 1;
            tokenExist[ListNFT_Child_exam[i].tokenId] = true;
            idToName[ListNFT_Child_exam[i].tokenId] = ListNFT_Child_exam[i].tokenName;
        }
    }

    // Token ERC20
    struct FT {
        string ftName;
        string ftSymbol;
        uint256 amountToken;
    }

    function transferToken(
        uint256 tokenId, 
        address contractToken,
        uint256 amountToken
    ) public {
        address to = tokenIdToOwner[tokenId];
        require(to != address(0), "To address is zero address!!!");
        require(tokenExist[tokenId], "NFT exist already!!!");

        ERC20(contractToken).transferFrom(msg.sender, to, amountToken);
        _addToken(tokenId, contractToken, amountToken);
    }

    function _addToken(
        uint256 tokenId, 
        address contractToken, 
        uint256 amountToken
    ) internal {
        NFTToToken[tokenId].push(
            FT(
                ERC20(contractToken).name(), 
                ERC20(contractToken).symbol(), 
                amountToken
            )
        );
    }

    // Transfer Token ERC20
    function transferTokenToAddress (
        address to, 
        address contractToken, 
        uint256 amountToken
    ) public {
        ERC20(contractToken).transferFrom(msg.sender, to, amountToken);
    }






    



































    // GET FUNCTION

    // Common function
    function getBalanceOfOwner() public view returns (uint256) {
        return balances[msg.sender];
    }


    // Only Owner of NFT
    function getAmountNFT() public view returns (uint256 AmountNFT) {
        return ownerToListNFT[msg.sender].length;
    }

    function getNameNFT() public view returns (string memory NameNFT) {
        NFT[] memory listNFT_exam = ownerToListNFT[msg.sender];
        string memory result = "";
        for(uint256 i = 0; i < listNFT_exam.length; i++) {
            result = string(
                abi.encodePacked(
                    result,
                    listNFT_exam[i].tokenName,
                    "; "   
                )
            );
        }
        return result;
    }

    function getAmountNFTChildren(uint256 tokenId_parent) public view returns (uint256 AmountNFTChildren) {
        require(tokenIdToOwner[tokenId_parent] == msg.sender, "This address is not allowed to call this function");
        return idParentToListNFTs[tokenId_parent].length;
    }

    function getNameNFTChildren(uint256 tokenId_parent) public view returns (string memory NameNFTChildren) {
        // require(tokenIdToOwner[tokenId_parent] == msg.sender, "This address is not allowed to call this function");
        NFT[] memory listChild_exam = idParentToListNFTs[tokenId_parent];
        string memory result = "";
        for(uint256 i = 0; i < listChild_exam.length; i++) {
            result = string(
                abi.encodePacked(
                    result,
                    listChild_exam[i].tokenName,
                    "; "   
                )
            );
        }
        return result;
    }  

    function getTokenOfNFT(uint256 tokenId) public view returns (string memory ERC20TokenInfo) {
        FT[] memory listFT_exam = NFTToToken[tokenId];
        string memory result = "";
        for (uint256 i = 0; i < listFT_exam.length; i++) {
            result = string (
                abi.encodePacked(
                    result,
                    listFT_exam[i].ftName,
                    "-",
                    listFT_exam[i].ftSymbol,
                    "-",
                    Strings.toString(listFT_exam[i].amountToken),
                    "\n"  
                )
            );
        }
        return result;
    }
}