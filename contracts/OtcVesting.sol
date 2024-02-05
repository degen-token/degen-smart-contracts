//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OtcVesting {
    address public degen;
    address public recipient;

    uint256 public vestingAmount;
    uint256 public vestingBegin;
    uint256 public vestingCliff;
    uint256 public vestingEnd;

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

        degen = degen_;
        recipient = recipient_;

        vestingAmount = vestingAmount_;
        vestingBegin = vestingBegin_;
        vestingCliff = vestingCliff_;
        vestingEnd = vestingEnd_;

        lastUpdate = vestingBegin;
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
            block.timestamp >= vestingCliff,
            "TreasuryVester.claim: not time yet"
        );
        uint256 amount;
        if (block.timestamp >= vestingEnd) {
            amount = IERC20(degen).balanceOf(address(this));
        } else {
            amount =
                (vestingAmount * (block.timestamp - lastUpdate)) /
                (vestingEnd - vestingBegin);
            lastUpdate = block.timestamp;
        }
        IERC20(degen).transfer(recipient, amount);
    }

    function recoverToken(address token_) public {
        require(
            token_ != degen,
            "TreasuryVester.recoverToken: only recover tokens accidentally sent to the contract"
        );
        uint256 amount = IERC20(token_).balanceOf(address(this));
        IERC20(token_).transfer(recipient, amount);
    }
}
