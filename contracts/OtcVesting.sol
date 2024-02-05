//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OtcVesting {
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
    ) {
        require(
            vestingBegin_ >= block.timestamp,
            "TreasuryVester.constructor: vesting begin too early"
        );
        require(
            vestingCliff_ >= vestingBegin_,
            "TreasuryVester.constructor: cliff is too early"
        );
        require(
            vestingEnd_ > vestingCliff_,
            "TreasuryVester.constructor: end is too early"
        );

        DEGEN = degen_;
        recipient = recipient_;

        VESTING_AMOUNT = vestingAmount_;
        VESTING_BEGIN = vestingBegin_;
        VESTING_CLIFF = vestingCliff_;
        VESTING_END = vestingEnd_;

        lastUpdate = VESTING_BEGIN;
    }

    function setRecipient(address recipient_) public {
        require(
            msg.sender == recipient,
            "TreasuryVester.setRecipient: unauthorized"
        );
        recipient = recipient_;
    }

    function claim() public {
        require(
            block.timestamp >= VESTING_CLIFF,
            "TreasuryVester.claim: not time yet"
        );
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

    function recoverToken(address token_) public {
        require(
            token_ != DEGEN,
            "TreasuryVester.recoverToken: only recover tokens accidentally sent to the contract"
        );
        uint256 amount = IERC20(token_).balanceOf(address(this));
        IERC20(token_).transfer(recipient, amount);
    }
}
