//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.20;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {OtcVesting} from "./OtcVesting.sol";

/**
 * @title OtcEscrow
 * @dev Slightly modified version of: https://gist.github.com/rchen8/b7cbfefbcb0b3fa2a25c8f4bf9643064
 * Changes include:
 * - Upgrading the Solidity version
 * - Renaming variables
 * - Removed modifiers
 * A simple OTC swap contract allowing two users to set the parameters of an OTC
 * deal in the constructor arguments, and deposits the sold tokens into a vesting
 * contract when a swap is completed.
 * @custom:security-contact jacek@degen.tips
 */
contract OtcEscrow is Ownable {
    using SafeERC20 for IERC20;

    /* ========== Events =========== */

    /**
     *  @dev This event is called when the vesting contract is deployed
     */
    event VestingDeployed(address indexed vesting);

    /* ====== Errors ======== */

    /**
     *  @dev Insufficient DEGEN balance in the contract
     */
    error InsufficientDegen();

    /**
     *  @dev The contract has already been run
     */
    error SwapAlreadyExecuted();

    /* ======== State Variables ======= */

    address public immutable WETH;
    address public immutable DEGEN;

    address public immutable BUYER;
    address public immutable SELLER;

    uint256 public immutable VESTING_START;
    uint256 public immutable VESTING_END;
    uint256 public immutable VESTING_CLIFF;

    uint256 public immutable WETH_AMOUNT;
    uint256 public immutable DEGEN_AMOUNT;

    bool public hasRun;

    /* ====== Constructor ======== */

    /**
     * Sets the state variables that encode the terms of the OTC sale
     *
     * @param _buyer        Address that will purchase DEGEN
     * @param _seller       Address that will receive WETH
     * @param _vestingStart Timestamp of vesting start
     * @param _vestingCliff Timestamp of vesting cliff
     * @param _vestingEnd   Timestamp of vesting end
     * @param _weth_amount   Amount of WETH swapped for the sale
     * @param _degen_amount  Amount of DEGEN swapped for the sale
     * @param _wethAddress  Address of the WETH token
     * @param _degenAddress Address of the Degen token
     */
    constructor(
        address _buyer,
        address _seller,
        uint256 _vestingStart,
        uint256 _vestingCliff,
        uint256 _vestingEnd,
        uint256 _weth_amount,
        uint256 _degen_amount,
        address _wethAddress,
        address _degenAddress
    ) Ownable(msg.sender) {
        BUYER = _buyer;
        SELLER = _seller;

        VESTING_START = _vestingStart;
        VESTING_CLIFF = _vestingCliff;
        VESTING_END = _vestingEnd;

        WETH_AMOUNT = _weth_amount;
        DEGEN_AMOUNT = _degen_amount;

        WETH = _wethAddress;
        DEGEN = _degenAddress;
        hasRun = false;
    }

    /* ======= External Functions ======= */

    /**
     * Executes the OTC deal. Sends the WETH from the buyer to seller, and
     * locks the DEGEN in the vesting contract. Can only be called once.
     */
    function swap() external onlyOwner {
        if (hasRun) revert SwapAlreadyExecuted();
        hasRun = true;

        if (IERC20(DEGEN).balanceOf(address(this)) < DEGEN_AMOUNT)
            revert InsufficientDegen();

        // Transfer expected WETH from buyer
        IERC20(WETH).safeTransferFrom(BUYER, address(this), WETH_AMOUNT);

        // Create Vesting contract
        OtcVesting vesting = new OtcVesting(
            DEGEN,
            BUYER,
            DEGEN_AMOUNT,
            VESTING_START,
            VESTING_CLIFF,
            VESTING_END
        );

        // Transfer degen to vesting contract
        IERC20(DEGEN).safeTransfer(address(vesting), DEGEN_AMOUNT);

        // Transfer WETH to seller
        IERC20(WETH).safeTransfer(SELLER, WETH_AMOUNT);

        emit VestingDeployed(address(vesting));
    }

    /**
     * Return DEGEN to seller to revoke the deal
     */
    function revoke() external onlyOwner {
        uint256 degenBalance = IERC20(DEGEN).balanceOf(address(this));
        IERC20(DEGEN).safeTransfer(SELLER, degenBalance);
    }

    /**
     * Recovers WETH accidentally sent to the contract
     */
    function recoverWeth() external {
        uint256 wethBalance = IERC20(WETH).balanceOf(address(this));
        IERC20(WETH).safeTransfer(BUYER, wethBalance);
    }
}