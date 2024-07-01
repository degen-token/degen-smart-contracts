// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice Lock Degen for a set amount of time after the deposit period ends.
 * @custom:security-contact jacek@degen.tips
 */
contract DegenLock is Ownable, IERC20 {
    /**
     * @dev The ERC20 token to be locked
     */
    ERC20 public token;

    /**
     * @dev Unix timestamp (seconds) of the deposit deadline
     */
    uint256 public depositDeadline;

    /**
     * @dev Lock duration in seconds, period starts after the deposit deadline
     */
    uint256 public lockDuration;

    /**
     * @dev Name of the token representing the claim on the locked token
     */
    string public constant name = "Locked Degen";

    /**
     * @dev Symbol of the token representing the claim on the locked token
     */
    string public constant symbol = "LDEGEN";

    /**
     * @dev Total number of tokens in circulation
     */
    uint256 public override totalSupply;

    /**
     * @dev Mapping from account to balance
     */
    mapping(address => uint256) public override balanceOf;

    /**
     * @dev Withdraw amount exceeds sender's balance of the locked token
     */
    error ExceedsBalance();

    /**
     * @dev Deposit is not possible anymore because the deposit period is over
     */
    error DepositPeriodOver();

    /**
     * @dev Withdraw is not possible because the lock period is not over yet
     */
    error LockPeriodOngoing();

    /**
     * @dev Could not transfer the designated ERC20 token
     */
    error TransferFailed();

    /**
     * @dev ERC-20 function is not supported
     */
    error NotSupported();

    constructor(
        address _token,
        uint256 _depositDeadline,
        uint256 _lockDuration
    ) Ownable(msg.sender) {
        token = ERC20(_token);
        depositDeadline = _depositDeadline;
        lockDuration = _lockDuration;
        totalSupply = 0;
    }

    /**
     * @dev Deposit tokens to be locked until the end of the locking period
     * @param amount The amount of tokens to deposit
     */
    function deposit(uint256 amount) public {
        if (block.timestamp > depositDeadline) {
            revert DepositPeriodOver();
        }

        balanceOf[msg.sender] += amount;
        totalSupply += amount;

        if (!token.transferFrom(msg.sender, address(this), amount)) {
            revert TransferFailed();
        }

        emit Transfer(msg.sender, address(this), amount);
    }

    /**
     * @dev Withdraw tokens after the end of the locking period or during the deposit period
     * @param amount The amount of tokens to withdraw
     */
    function withdraw(uint256 amount) public {
        if (
            block.timestamp > depositDeadline &&
            block.timestamp < depositDeadline + lockDuration
        ) {
            revert LockPeriodOngoing();
        }
        if (balanceOf[msg.sender] < amount) {
            revert ExceedsBalance();
        }

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;

        if (!token.transfer(msg.sender, amount)) {
            revert TransferFailed();
        }

        emit Transfer(address(this), msg.sender, amount);
    }

    /**
     * @dev Returns the number of decimals of the locked token
     */
    function decimals() public view returns (uint8) {
        return token.decimals();
    }

    /**
     * @dev Lock claim tokens are non-transferrable: ERC-20 transfer is not supported
     */
    function transfer(address, uint256) external pure override returns (bool) {
        revert NotSupported();
    }

    /**
     * @dev Lock claim tokens are non-transferrable: ERC-20 allowance is not supported
     */
    function allowance(
        address,
        address
    ) external pure override returns (uint256) {
        revert NotSupported();
    }

    /**
     *
     * @dev Lock claim tokens are non-transferrable: ERC-20 approve is not supported
     */
    function approve(address, uint256) external pure override returns (bool) {
        revert NotSupported();
    }

    /**
     *  @dev Lock claim tokens are non-transferrable: ERC-20 transferFrom is not supported
     */
    function transferFrom(
        address,
        address,
        uint256
    ) external pure override returns (bool) {
        revert NotSupported();
    }
}
