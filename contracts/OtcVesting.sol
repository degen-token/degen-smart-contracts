//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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
     *  @dev The vesting cliff date has not been reached yet
     */
    error DegenTokenCannotBeTransfered();

    /* ======== State Variables ======= */

    address public immutable DEGEN;
    address public recipient;

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
        recipient = recipient_;

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
        IERC20(DEGEN).transfer(recipient, amount);
    }

    function recoverToken(address token_) external onlyOwner {
        require(
            token_ != DEGEN,
            "TreasuryVester.recoverToken: only recover tokens accidentally sent to the contract"
        );
        uint256 amount = IERC20(token_).balanceOf(address(this));
        IERC20(token_).transfer(recipient, amount);
    }
}
