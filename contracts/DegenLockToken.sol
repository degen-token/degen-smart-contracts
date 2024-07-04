// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @notice Lock Degen for a set amount of time.
 * @custom:security-contact jacek@degen.tips
 */
contract DegenLockToken is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(address account => uint256) private _depositTimestamps;

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
    IERC20 public constant TOKEN =
        IERC20(0xfee293840D23B0B2De8C55e1Cf7A9F01C157767c);

    /**
     * @dev Lock duration in seconds, period starts after the deposit timestamp
     */
    uint256 public lockDuration = 90 days;

    /**
     * @dev Minimum amount of tokens that have to be deposited
     */
    uint256 public minDepositAmount;

    /**
     * @dev Withdraw is not possible because the lock period is not over yet
     */
    error LockPeriodOngoing();

    /**
     * @dev ERC-20 function is not supported
     */
    error NotSupported();

    /**
     *  @dev The lock duration is longer than a year
     */
    error LockDurationIsTooLong();

    /**
     *  @dev Amount of tokens to be locked is zero
     */
    error ZeroAmount();

    /**
    /**
     * @dev Minimum deposit not met
     */
    error MinimumDepositNotMet();

    /**
     *  @dev The lock duration has been updated
     */
    event LockDurationUpdated(uint256 indexed duration);

    /**
     *  @dev The minimum deposit amount has been updated
     */
    event MinDepositAmountUpdated(uint256 indexed minDepositAmount);

    /**
     *  @dev The deposit timestamp has been set
     */
    event DepositTimestampUpdated(
        address indexed account,
        uint256 indexed depositTimestamp
    );

    /**
     * @dev Construct a new Degen token
     */
    constructor() ERC20(TOKEN_NAME, TOKEN_SYMBOL) Ownable(msg.sender) {
        minDepositAmount = 10000 * 10 ** decimals();
        emit MinDepositAmountUpdated(minDepositAmount);
    }

    /**
     * @dev Deposit tokens to be locked until the end of the locking period
     * @param amount The amount of tokens to deposit
     */
    function deposit(uint256 amount) external nonReentrant {
        if (amount < minDepositAmount) {
            revert MinimumDepositNotMet();
        }

        TOKEN.safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);

        _depositTimestamps[msg.sender] = block.timestamp;
        emit DepositTimestampUpdated(msg.sender, block.timestamp);
    }

    /**
     * @dev Withdraw tokens after the end of the locking period or during the deposit period
     * @param amount The amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external nonReentrant {
        if (amount == 0) {
            revert ZeroAmount();
        }

        if (block.timestamp <= _depositTimestamps[msg.sender] + lockDuration) {
            revert LockPeriodOngoing();
        }

        _burn(msg.sender, amount);
        TOKEN.safeTransfer(msg.sender, amount);
    }

    /**
     * @dev Update the lock duration
     * @param newDuration The new lock duration in seconds
     */
    function updateLockDuration(uint256 newDuration) external onlyOwner {
        if (newDuration <= 365 days) {
            revert LockDurationIsTooLong();
        }

        lockDuration = newDuration;
        emit LockDurationUpdated(lockDuration);
    }

    /**
     * @dev Update the minimum deposit amount
     * @param newMinDepositAmount The new minimum deposit amount
     */
    function updateMinDepositAmount(
        uint256 newMinDepositAmount
    ) external onlyOwner {
        minDepositAmount = newMinDepositAmount;
        emit MinDepositAmountUpdated(minDepositAmount);
    }

    /**
     * @dev Last deposit timestamp for the account
     */
    function depositTimestamp(address account) external view returns (uint256) {
        return _depositTimestamps[account];
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
