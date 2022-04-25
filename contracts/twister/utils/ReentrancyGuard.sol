// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract ReentrancyGuard {
    uint private reentrancyGuard;

    function initReentrancyGuard() internal {
        reentrancyGuard = 1;
    }

    modifier nonReentrant() {
        if (reentrancyGuard != 1)
            revert Reentrancy();
        reentrancyGuard = 2;
        _;
        reentrancyGuard = 1;
    }

    error Reentrancy();
}