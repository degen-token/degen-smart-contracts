//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.20;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OtcVesting
 * @dev Slightly modified version of: https://gist.github.com/rchen8/759d9c2fe9f244040678f852819079aa
 * Changes include:
 * - Upgrading the Solidity version
 * - Renaming variables
 * - Adding custom errors
 * @custom:security-contact jacek@degen.tips
 */
contract OtcVesting is Ownable {
    using SafeERC20 for IERC20;

    /* ====== Errors ======== */

    /**
     *  @dev The vesting start date is in the past
     */
    error VestingStartDateInPast();

    /**
     *  @dev The vesting cliff date is in the past
     */
    error VestingCliffDateInPast();

    /**
     *  @dev The vesting end date is before the cliff date
     */
    error VestingEndDateBeforeCliffDate();

    /**
     *  @dev The vesting cliff date has not been reached yet
     */
    error VestingCliffDateNotReached();

    /**
     *  @dev The DEGEN token cannot be transfered out of the contract
     */
    error DegenTokenCannotBeTransfered();

    /* ======== State Variables ======= */

    address public immutable DEGEN;
    address public immutable RECIPIENT;

    uint256 public immutable VESTING_AMOUNT;
    uint256 public immutable VESTING_BEGIN;
    uint256 public immutable VESTING_CLIFF;
    uint256 public immutable VESTING_END;

    uint256 public lastUpdate;

    constructor(
        address degen_,
        address recipient_,
        uint256 vestingAmount_,
        uint256 vestingBegin_,
        uint256 vestingCliff_,
        uint256 vestingEnd_
    ) Ownable(recipient_) {
        if (vestingBegin_ < block.timestamp) revert VestingStartDateInPast();
        if (vestingCliff_ < block.timestamp) revert VestingCliffDateInPast();
        if (vestingEnd_ <= vestingCliff_)
            revert VestingEndDateBeforeCliffDate();

        DEGEN = degen_;
        RECIPIENT = recipient_;

        VESTING_AMOUNT = vestingAmount_;
        VESTING_BEGIN = vestingBegin_;
        VESTING_CLIFF = vestingCliff_;
        VESTING_END = vestingEnd_;

        lastUpdate = VESTING_BEGIN;
    }

    function claim() external onlyOwner {
        if (block.timestamp < VESTING_CLIFF)
            revert VestingCliffDateNotReached();

        uint256 amount;
        if (block.timestamp >= VESTING_END) {
            amount = IERC20(DEGEN).balanceOf(address(this));
        } else {
            amount =
                (VESTING_AMOUNT * (block.timestamp - lastUpdate)) /
                (VESTING_END - VESTING_BEGIN);
            lastUpdate = block.timestamp;
        }
        IERC20(DEGEN).safeTransfer(RECIPIENT, amount);
    }

    function recoverToken(address token_) external onlyOwner {
        if (token_ == DEGEN) revert DegenTokenCannotBeTransfered();
        uint256 amount = IERC20(token_).balanceOf(address(this));
        IERC20(token_).safeTransfer(RECIPIENT, amount);
    }
}
