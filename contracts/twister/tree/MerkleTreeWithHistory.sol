// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library MerkleTreeWithHistory {
    function insert(bytes32 _leaf) public returns (uint32) {}
    function isKnownRoot(bytes32 _root) public view returns (bool) {}
    function getLastRoot() public view returns (bytes32) {}
    function initialize(uint32 levels) public {}
}