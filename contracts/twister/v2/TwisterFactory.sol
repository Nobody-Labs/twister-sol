// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "../utils/Initializable.sol";
import "../../interfaces/ITwister.sol";
import "../../interfaces/ITwisterPool.sol";

contract TwisterFactory is Initializable {

    event NewTokenTwister(
        address indexed token,
        address tokenTwister,
        uint denomination
    );
    event NewTimelock(address timelock);

    address public timelock;
    address public tokenTwister;

    function initialize(
        address _timelock,
        address _tokenTwister
    ) external onlyUninitialized {
        timelock = _timelock;
        tokenTwister = _tokenTwister;
        setIsInitialized();
    }

    function deployTokenTwister(
        address twisterPool,
        address token,
        uint256 denomination,
        bytes32 salt
    )
        external
        onlyTimelock
        returns (address)
    {
        address twister = Clones.cloneDeterministic(tokenTwister, salt);
        ITwister(twister).initialize(
            twisterPool,
            token,
            denomination
        );
        ITwisterPool(twisterPool).addTokenTwister(twister);
        emit NewTokenTwister(token, twister, denomination);
        return twister;
    }

    function setTimelock(address newTimelock)
        external
        onlyTimelock
    {
        timelock = newTimelock;
        emit NewTimelock(newTimelock);
    }

    modifier onlyTimelock() {
        if (msg.sender != timelock)
            revert MsgSenderIsNotTimelock();
        _;
    }

    error MsgSenderIsNotTimelock();
}