// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @notice The  Degen token allows Farcaster community members to earn reputation tokens.
 */
contract DegenToken is ERC20Burnable, ERC20Permit, Ownable {
    string internal constant TOKEN_NAME = "Degen";
    string internal constant TOKEN_SYMBOL = "DEGEN";
    uint256 internal constant TOKEN_SUPPLY = 1_000_000_000;

    constructor()
        ERC20(TOKEN_NAME, TOKEN_SYMBOL)
        ERC20Permit(TOKEN_NAME)
        Ownable(msg.sender)
    {
        _mint(msg.sender, TOKEN_SUPPLY * 10 ** decimals());
    }
}
