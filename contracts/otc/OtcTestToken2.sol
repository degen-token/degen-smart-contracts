//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title OtcTestToken2
 * @custom:security-contact jacek@degen.tips
 */
contract OtcTestToken2 is ERC20 {
    /**
     * @dev Total number of tokens in circulation
     */
    uint256 public constant TOKEN_INITIAL_SUPPLY = 36_965_935_954;

    constructor() ERC20("OtcTestToken2", "OtcTestToken2") {
        _mint(msg.sender, TOKEN_INITIAL_SUPPLY * 10 ** decimals());
    }
}
