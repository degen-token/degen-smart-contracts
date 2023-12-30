// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice The Degen token allows Farcaster community members to earn reputation tokens.
 * @custom:security-contact jacek@degen.tips
 */
contract DegenToken is ERC20, ERC20Burnable, Ownable {
    string internal constant TOKEN_NAME = "Degen";
    string internal constant TOKEN_SYMBOL = "DEGEN";
    uint256 internal constant TOKEN_SUPPLY = 7_000_000_000;

    constructor() ERC20(TOKEN_NAME, TOKEN_SYMBOL) Ownable(msg.sender) {
        _mint(msg.sender, TOKEN_SUPPLY * 10 ** decimals());
    }
}
