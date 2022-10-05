// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HoBiToken is ERC20, Ownable {
    constructor() ERC20("HoBiToken", "HBT") {}

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }
}