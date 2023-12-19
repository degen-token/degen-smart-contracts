// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract DegenToken is ERC20Burnable, ERC20Capped, ERC20Permit, Ownable {
    string internal constant TOKEN_NAME = "Degen";
    string internal constant TOKEN_TICKER = "DEGEN";
    uint256 private constant TOKEN_SUPPLY = 1_000_000_000;

    constructor()
        ERC20(TOKEN_NAME, TOKEN_TICKER)
        ERC20Permit(TOKEN_NAME)
        ERC20Capped(TOKEN_SUPPLY * 10 ** decimals())
        Ownable(msg.sender)
    {
        _mint(msg.sender, TOKEN_SUPPLY * 10 ** decimals());
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override(ERC20Capped, ERC20) {
        super._update(from, to, value);

        if (from == address(0)) {
            uint256 maxSupply = cap();
            uint256 supply = totalSupply();
            if (supply > maxSupply) {
                revert ERC20ExceededCap(supply, maxSupply);
            }
        }
    }
}
