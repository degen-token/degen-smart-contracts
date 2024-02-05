//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title OtcTestToken1
 * @custom:security-contact jacek@degen.tips
 */
contract OtcTestToken1 is ERC20 {
    /**
     * @dev Total number of tokens in circulation
     */
    uint256 public constant TOKEN_INITIAL_SUPPLY = 1_000_000_000;

    constructor() ERC20("OtcTestToken1", "OtcTestToken1") {
        _mint(msg.sender, TOKEN_INITIAL_SUPPLY * 10 ** decimals());
    }
}
