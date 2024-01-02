// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice The Degen token
 * @custom:security-contact jacek@degen.tips
 */
contract DegenToken is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    /**
     * @dev EIP-20 token name for this token
     */
    string public constant TOKEN_NAME = "Degen";

    /**
     * @dev EIP-20 token symbol for this token
     */
    string public constant TOKEN_SYMBOL = "DEGEN";

    /**
     * @dev Total number of tokens in circulation
     */
    uint256 public constant TOKEN_SUPPLY = 7_000_000_000;

    /**
     * @dev The timestamp after which minting may occur
     */
    uint256 public mintingAllowedAfter;

    /**
     * @dev Minimum time between mints
     */
    uint32 public constant MINIMUM_TIME_BETWEEN_MINTS = 1 days * 365;

    /**
     * @dev Cap on the percentage of totalSupply that can be minted at each mint
     */
    uint8 public constant MINT_CAP = 1;

    /**
     * @dev Construct a new Degen token
     * @param mintingAllowedAfter_ The timestamp after which minting may occur
     */
    constructor(
        uint256 mintingAllowedAfter_
    )
        ERC20(TOKEN_NAME, TOKEN_SYMBOL)
        ERC20Permit("TOKEN_NAME")
        Ownable(msg.sender)
    {
        require(
            mintingAllowedAfter_ >= block.timestamp,
            "Degen::constructor: minting can only begin after deployment"
        );

        _mint(msg.sender, TOKEN_SUPPLY * 10 ** decimals());

        mintingAllowedAfter = mintingAllowedAfter_;
    }

    /**
     * @dev Mint new tokens
     * @param to The address of the target account
     * @param amount The number of tokens to be minted
     */
    function mint(address to, uint96 amount) public onlyOwner {
        require(
            block.timestamp >= mintingAllowedAfter,
            "Degen::mint: minting not allowed yet"
        );

        require(
            to != address(0),
            "Degen::mint: cannot transfer to the zero address"
        );

        // record the mint
        mintingAllowedAfter = block.timestamp + MINIMUM_TIME_BETWEEN_MINTS;

        // mint the amount
        require(
            amount <= (totalSupply() * MINT_CAP) / 100,
            "Degen::mint: exceeded mint cap"
        );

        _mint(to, amount);
    }
}
