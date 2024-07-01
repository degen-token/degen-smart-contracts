// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.20;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Lock Degen for a set amount of time after the deposit period ends.
 * @custom:security-contact jacek@degen.tips
 */
contract DegenToken is ERC20, Ownable {
    using SafeERC20 for IERC20;

    /**
     * @dev Name of the token representing the claim on the locked token
     */
    string public constant TOKEN_NAME = "Locked Degen";

    /**
     * @dev Symbol of the token representing the claim on the locked token
     */
    string public constant TOKEN_SYMBOL = "LDEGEN";

    /**
     * @dev The ERC20 token to be locked
     */
    address public immutable TOKEN;

    /**
     * @dev Unix timestamp (seconds) of the deposit deadline
     */
    uint256 public immutable DEPOSIT_DEADLINE;

    /**
     * @dev Lock duration in seconds, period starts after the deposit deadline
     */
    uint256 public immutable LOCK_DURATION;

    /**
     * @dev Deposit is not possible anymore because the deposit period is over
     */
    error DepositPeriodOver();

    /**
     * @dev Withdraw is not possible because the lock period is not over yet
     */
    error LockPeriodOngoing();

    /**
     * @dev ERC-20 function is not supported
     */
    error NotSupported();

    /**
     * @dev Construct a new Degen token
     * @param _token The timestamp after which minting may occur
     * @param _depositDeadline The timestamp after which minting may occur
     * @param _lockDuration The timestamp after which minting may occur
     */
    constructor(
        address _token,
        uint256 _depositDeadline,
        uint256 _lockDuration
    ) ERC20(TOKEN_NAME, TOKEN_SYMBOL) Ownable(msg.sender) {
        TOKEN = _token;
        DEPOSIT_DEADLINE = _depositDeadline;
        LOCK_DURATION = _lockDuration;
    }

    /**
     * @dev Deposit tokens to be locked until the end of the locking period
     * @param amount The amount of tokens to deposit
     */
    function deposit(uint256 amount) public {
        if (block.timestamp > DEPOSIT_DEADLINE) {
            revert DepositPeriodOver();
        }

        IERC20(TOKEN).safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
    }

    /**
     * @dev Withdraw tokens after the end of the locking period or during the deposit period
     * @param amount The amount of tokens to withdraw
     */
    function withdraw(uint256 amount) public {
        if (
            block.timestamp > DEPOSIT_DEADLINE &&
            block.timestamp < DEPOSIT_DEADLINE + LOCK_DURATION
        ) {
            revert LockPeriodOngoing();
        }

        _burn(msg.sender, amount);
        IERC20(TOKEN).safeTransfer(msg.sender, amount);
    }

    /**
     * @dev Lock claim tokens are non-transferrable: ERC-20 transfer is not supported
     */
    function transfer(address, uint256) public pure override returns (bool) {
        revert NotSupported();
    }

    /**
     * @dev Lock claim tokens are non-transferrable: ERC-20 allowance is not supported
     */
    function allowance(
        address,
        address
    ) public pure override returns (uint256) {
        revert NotSupported();
    }

    /**
     *
     * @dev Lock claim tokens are non-transferrable: ERC-20 approve is not supported
     */
    function approve(address, uint256) public pure override returns (bool) {
        revert NotSupported();
    }

    /**
     *  @dev Lock claim tokens are non-transferrable: ERC-20 transferFrom is not supported
     */
    function transferFrom(
        address,
        address,
        uint256
    ) public pure override returns (bool) {
        revert NotSupported();
    }
}
