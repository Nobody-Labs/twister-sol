// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "../utils/Initializable.sol";
import "../utils/ReentrancyGuard.sol";
import "../../interfaces/IERC3156FlashBorrower.sol";
import "../../interfaces/IERC3156FlashLender.sol";

contract TwisterFlashPool is IERC3156FlashLender, Initializable, ReentrancyGuard {
    using SafeTransferLib for ERC20;

    event FlashLoan(
        address indexed recipient,
        address indexed token,
        uint amount,
        uint fee
    );
    event NewTimelock(address timelock);
    event NewFee(uint fee);
    event NewFlashLendability(address token, bool isFlashLendable);

    // required for ERC3156 flashloan standard compliance
    bytes32 private constant CALLBACK_SUCCESS = keccak256(
        "ERC3156FlashBorrower.onFlashLoan"
    );

    uint public baseFeePerTenThousand;
    address public timelock;
    address public twisterFactory;
    mapping (address => uint) public poolBalance;
    mapping (address => bool) public isTokenTwister;
    mapping (address => bool) public isFlashLendable;

    function initialize(
        address _timelock,
        address _twisterFactory
    ) external onlyUninitialized {
        initReentrancyGuard();
        setIsInitialized();
        timelock = _timelock;
        twisterFactory = _twisterFactory;
    }

    function deposit(address from, address token, uint amount)
        external
        onlyTokenTwister
    {
        poolBalance[token] += amount;
        ERC20(token).safeTransferFrom(from, address(this), amount);
    }

    function withdraw(address token, uint amount)
        external
        onlyTokenTwister
    {
        poolBalance[token] -= amount;
        ERC20(token).safeTransfer(msg.sender, amount);
    }

    function flashLoan(
        address recipient,
        address token,
        uint256 amount,
        bytes memory data
    )
        external
        virtual
        override
        nonReentrant
        onlyFlashLendable(token)
        returns (bool)
    {
        if (amount > _maxFlashLoan(token))
            revert AmountExceedsMaxFlashLoan();
        uint loanFee = _flashFee(amount);
        ERC20 t = ERC20(token);
        t.safeTransfer(recipient, amount);

        bytes32 response = IERC3156FlashBorrower(recipient).onFlashLoan(
            msg.sender, token, amount, loanFee, data
        );
        if (response != CALLBACK_SUCCESS)
            revert FlashBorrowerCallbackFailed();

        t.safeTransferFrom(
            recipient,
            address(this),
            amount + loanFee
        );
        emit FlashLoan(recipient, token, amount, loanFee);
        return true;
    }

    function maxFlashLoan(address token)
        external
        virtual
        override
        view
        returns (uint)
    {
        return isFlashLendable[token] ? _maxFlashLoan(token) : 0;
    }

    function _maxFlashLoan(address token)
        internal
        view
        returns (uint)
    {
        return ERC20(token).balanceOf(address(this));
    }

    function flashFee(address token , uint amount)
        external
        virtual
        override
        view
        onlyFlashLendable(token)
        returns (uint)
    {
        return _flashFee(amount);
    }

    function _flashFee(uint amount)
        internal
        view
        returns (uint)
    {
        return amount * baseFeePerTenThousand / 10000;
    }

    function withdrawFees(address token)
        external
        onlyTimelock
    {
        ERC20 t = ERC20(token);
        uint currentBalance = t.balanceOf(address(this));
        uint amount = currentBalance - poolBalance[token];
        if (amount > 0)
            t.safeTransfer(msg.sender, amount);
    }

    function addTokenTwister(address tokenTwister)
        external
        onlyTwisterFactory
    {
        isTokenTwister[tokenTwister] = true;
    }

    function setTimelock(address newTimelock)
        external
        onlyTimelock
    {
        timelock = newTimelock;
        emit NewTimelock(newTimelock);
    }

    function setFee(uint newFee)
        external
        onlyTimelock
    {
        baseFeePerTenThousand = newFee;
        emit NewFee(newFee);
    }

    function setFlashLendability(address token, bool isEnabled)
        external
        onlyTimelock
    {
        isFlashLendable[token] = isEnabled;
        emit NewFlashLendability(token, isEnabled);
    }

    modifier onlyFlashLendable(address token) {
        if (!isFlashLendable[token])
            revert TokenIsNotFlashLendable();
        _;
    }

    modifier onlyTimelock() {
        if (msg.sender != timelock)
            revert MsgSenderIsNotTimelock();
        _;
    }

    modifier onlyTokenTwister() {
        if (!isTokenTwister[msg.sender])
            revert MsgSenderIsNotTokenTwister();
        _;
    }

    modifier onlyTwisterFactory() {
        if (msg.sender != twisterFactory)
            revert MsgSenderIsNotTwisterFactory();
        _;
    }

    error AmountExceedsMaxFlashLoan();
    error ArrayLengthMismatch();
    error FlashBorrowerCallbackFailed();
    error InvalidMerkleTreeHeight();
    error MsgSenderIsNotTwisterFactory();
    error MsgSenderIsNotTokenTwister();
    error MsgSenderIsNotTimelock();
    error TokenIsNotFlashLendable();
    error VerifierIsImmutable();
    error VerifierNotSet();
}
