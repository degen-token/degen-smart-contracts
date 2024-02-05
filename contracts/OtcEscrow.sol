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
    event VestingDeployed(address vesting);

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

    address public immutable weth;
    address public immutable degen;

    address public immutable buyer;
    address public immutable seller;

    uint256 public immutable vestingStart;
    uint256 public immutable vestingEnd;
    uint256 public immutable vestingCliff;

    uint256 public immutable wethAmount;
    uint256 public immutable degenAmount;

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
     * @param _wethAmount   Amount of WETH swapped for the sale
     * @param _degenAmount  Amount of DEGEN swapped for the sale
     * @param _wethAddress  Address of the WETH token
     * @param _degenAddress Address of the Degen token
     */
    constructor(
        address _buyer,
        address _seller,
        uint256 _vestingStart,
        uint256 _vestingCliff,
        uint256 _vestingEnd,
        uint256 _wethAmount,
        uint256 _degenAmount,
        address _wethAddress,
        address _degenAddress
    ) Ownable(msg.sender) {
        buyer = _buyer;
        seller = _seller;

        vestingStart = _vestingStart;
        vestingCliff = _vestingCliff;
        vestingEnd = _vestingEnd;

        wethAmount = _wethAmount;
        degenAmount = _degenAmount;

        weth = _wethAddress;
        degen = _degenAddress;
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

        if (IERC20(degen).balanceOf(address(this)) < degenAmount)
            revert InsufficientDegen();

        // Transfer expected WETH from buyer
        IERC20(weth).safeTransferFrom(buyer, address(this), wethAmount);

        // Create Vesting contract
        OtcVesting vesting = new OtcVesting(
            degen,
            buyer,
            degenAmount,
            vestingStart,
            vestingCliff,
            vestingEnd
        );

        // Transfer degen to vesting contract
        IERC20(degen).safeTransfer(address(vesting), degenAmount);

        // Transfer WETH to seller
        IERC20(weth).safeTransfer(seller, wethAmount);

        emit VestingDeployed(address(vesting));
    }

    /**
     * Return DEGEN to seller to revoke the deal
     */
    function revoke() external onlyOwner {
        uint256 degenBalance = IERC20(degen).balanceOf(address(this));
        IERC20(degen).safeTransfer(seller, degenBalance);
    }

    /**
     * Recovers WETH accidentally sent to the contract
     */
    function recoverWeth() external {
        uint256 wethBalance = IERC20(weth).balanceOf(address(this));
        IERC20(weth).safeTransfer(buyer, wethBalance);
    }
}
