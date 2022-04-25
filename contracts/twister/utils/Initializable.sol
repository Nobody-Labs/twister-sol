// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Initializable {
    uint private isInitialized;

    function setIsInitialized() internal {
        isInitialized = 1;
    }

    modifier onlyUninitialized() {
        if (isInitialized == 1)
            revert AlreadyInitialized();
        isInitialized = 1;
        _;
    }

    error AlreadyInitialized();
}