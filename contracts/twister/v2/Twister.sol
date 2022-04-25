// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "../utils/Initializable.sol";
import "../utils/ReentrancyGuard.sol";
import "../tree/MerkleTreeWithHistory.sol";
import "../verifiers/WithdrawVerifier.sol";
import "../../interfaces/ITwisterPool.sol";

contract Twister is Initializable, ReentrancyGuard, WithdrawVerifier {

    using MerkleTreeWithHistory for bytes32;
    using SafeTransferLib for ERC20;

    event Deposit(
        bytes32 indexed commitment,
        uint32 leafIndex,
        uint256 timestamp
    );
    event Withdrawal(
        address to,
        bytes32 nullifierHash,
        address indexed relayer,
        uint256 fee
    );

    uint256 public denomination;
    ERC20 public token;
    ITwisterPool public twisterPool;
    mapping(bytes32 => bool) public commitmentIsSeen;
    mapping(bytes32 => bool) public nullifierHashIsSpent;

    function initialize(
        address _twisterPool,
        address _token,
        uint256 _denomination
    ) external onlyUninitialized {
        if (_denomination == 0)
            revert DenominationZero();
        twisterPool = ITwisterPool(_twisterPool);
        token = ERC20(_token);
        denomination = _denomination;
        initReentrancyGuard();
        setIsInitialized();
        MerkleTreeWithHistory.initialize(uint32(20));
    }

    function deposit(bytes32 commitment)
        external
        nonReentrant
    {
        if (commitmentIsSeen[commitment])
            revert DuplicateCommitment();
        commitmentIsSeen[commitment] = true;
        uint32 insertedIndex = commitment.insert();

        twisterPool.deposit(msg.sender, address(token), denomination);
        emit Deposit(commitment, insertedIndex, block.timestamp);
    }

    function withdraw(
        uint[8] calldata proof,
        bytes32 root,
        bytes32 nullifierHash,
        address recipient,
        address relayer,
        uint256 fee,
        uint256 refund
    )
        external
        payable
        nonReentrant
    {
        if (fee > denomination) {
            revert FeeExceedsDenomination();
        } else if (msg.value != refund) {
            revert MsgValueDoesNotMatchRefund();
        } else if (nullifierHashIsSpent[nullifierHash]) {
            revert NullifierHashAlreadySpent();
        } else if (!root.isKnownRoot()) {
            revert UnknownMerkleTreeRoot();
        } else if (!verifyProof(
            proof,
            uint256(root),
            uint256(nullifierHash),
            uint256(uint160(recipient)),
            uint256(uint160(relayer)),
            fee,
            refund
        )) {
            revert InvalidWithdrawProof();
        }

        nullifierHashIsSpent[nullifierHash] = true;

        twisterPool.withdraw(address(token), denomination);
        if (fee > 0) {
            token.safeTransfer(recipient, denomination - fee);
            token.safeTransfer(relayer, fee);
        } else {
            token.safeTransfer(recipient, denomination);
        }

        if (refund > 0) {
            (bool success, ) = recipient.call{ value: refund }("");
            if (!success) {
                payable(relayer).transfer(refund);
            }
        }

        emit Withdrawal(recipient, nullifierHash, relayer, fee);
    }

    function isKnownRoot(bytes32 root)
        public
        view
        returns (bool)
    {
        return root.isKnownRoot();
    }

    error DenominationZero();
    error DuplicateCommitment();
    error FeeExceedsDenomination();
    error InvalidWithdrawProof();
    error MsgValueDoesNotMatchRefund();
    error NullifierHashAlreadySpent();
    error UnknownMerkleTreeRoot();
}