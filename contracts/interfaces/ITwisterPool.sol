// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ITwisterPool {
    function addTokenTwister(address tokenTwister) external;
    function deposit(address from, address token, uint amount) external;
    function initialize(address twisterFactory) external;
    function withdraw(address token, uint amount) external;
}