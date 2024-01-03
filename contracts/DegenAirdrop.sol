// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error AlreadyClaimed();
error InvalidProof();

/**
 * @notice Distributes a balance of tokens according to a merkle root.
 * @dev Slightly modified version of: https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol
 * Changes include:
 * - remove "./interfaces/IMerkleDistributor.sol" inheritance
 * @custom:security-contact jacek@degen.tips
 */
contract DegenAirdrop {
    using SafeERC20 for IERC20;

    /**
     *  @dev The token to be distributed
     */
    address public immutable TOKEN;

    /**
     *  @dev The merkle root of the distribution
     */
    bytes32 public immutable MERKLE_ROOT;

    /**
     *  @dev This is a packed array of booleans
     */
    mapping(uint256 => uint256) private claimedBitMap;

    /**
     *  @dev This event is triggered whenever a call to #claim succeeds
     */
    event Claimed(uint256 index, address account, uint256 amount);

    constructor(address token_, bytes32 merkleRoot_) {
        TOKEN = token_;
        MERKLE_ROOT = merkleRoot_;
    }

    /**
     *  @dev Returns true if the index has been marked claimed
     *  @param index The index of the claimer in the merkle tree
     */
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /**
     *  @dev Marks the index as claimed
     *  @param index The index of the claimer in the merkle tree
     */
    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    /**
     *  @dev Claim the given amount of the token to the given address
     *  @param index The index of the claimer in the merkle tree
     *  @param account The account to receive the tokens
     *  @param amount The amount of tokens to claim
     *  @param merkleProof The merkle proof
     */
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external virtual {
        if (isClaimed(index)) revert AlreadyClaimed();

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        if (!MerkleProof.verify(merkleProof, MERKLE_ROOT, node))
            revert InvalidProof();

        // Mark it claimed and send the token.
        _setClaimed(index);
        IERC20(TOKEN).safeTransfer(account, amount);

        emit Claimed(index, account, amount);
    }
}
