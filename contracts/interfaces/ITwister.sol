// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ITwister {
    function initialize(
        address _twisterPool,
        address _token,
        uint256 _denomination
    ) external;
}