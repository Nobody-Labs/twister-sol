// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.10;

contract Create2Deployer {

    function deploy(bytes memory code, address expected, bytes32 salt) 
        public
    {
        address actual;
        assembly {
            actual := create2(0, add(code, 0x20), mload(code), salt)
        }
        if (actual == address(0)) {
            revert ZeroAddress();
        } else if (actual != expected) {
            revert UnexpectedAddress();
        }
    }

    function deployAndCall(
        bytes memory code, bytes memory args,
        address expected, bytes32 salt
    )
        public
    {
        address actual;
        assembly {
            actual := create2(0, add(code, 0x20), mload(code), salt)
        }
        if (actual == address(0)) {
            revert ZeroAddress();
        } else if (actual != expected) {
            revert UnexpectedAddress();
        }

        (bool success,) = actual.call(args);
        if (!success)
            revert CallFailed();
    }

    error CallFailed();
    error UnexpectedAddress();
    error ZeroAddress();
}