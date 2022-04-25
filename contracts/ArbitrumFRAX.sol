// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@rari-capital/solmate/src/tokens/ERC20.sol";

contract ArbitrumFRAX is ERC20 {
    address private owner;

    constructor() ERC20("ArbitrumFRAX", "ARBFRAX", 18) {
        owner = msg.sender;
    }

    function mint(address account, uint256 amount) public {
        require(msg.sender == owner, "Failed: not owner");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        require(msg.sender == owner, "Failed: not owner");
        _burn(account, amount);
    }
}