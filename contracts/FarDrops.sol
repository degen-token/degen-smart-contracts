// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TokenDistributor
 * @dev A contract to distribute ERC20 tokens to recipients based on set percentages.
 */
contract TokenDistributor is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant PERCENTAGE_SCALE = 10000;
    mapping(address => bool) public approvedTokens;

    struct Recipient {
        address wallet;
        uint256 percentage; // 100% = 10000 (e.g., 0.25% = 25)
    }

    event TokenApproved(address token, bool approved);

    /**
     * @dev Constructor for TokenDistributor.
     */
    constructor() Ownable(msg.sender) ReentrancyGuard() {}

    /**
     * @dev Approves or disapproves a token for distribution.
     * @param _token Address of the token to approve/disapprove.
     * @param _status Boolean indicating approval status.
     */
    function approveToken(address _token, bool _status) external onlyOwner {
        require(_token != address(0), "Invalid token address");
        approvedTokens[_token] = _status;
        emit TokenApproved(_token, _status);
    }

    /**
     * @dev Retrieves the list of approved tokens with a balance in the contract.
     * @return An array of token addresses.
     */
    function getTokenList() public view returns (address[] memory) {
        uint256 tokenCount = 0;
        address[] memory tokens = new address[](256); // Arbitrary max size
        for (uint256 i = 0; i < 256; i++) {
            try IERC20(tokens[i]).balanceOf(address(this)) returns (
                uint256 balance
            ) {
                if (balance > 0 && approvedTokens[tokens[i]]) {
                    tokens[tokenCount] = tokens[i];
                    tokenCount++;
                }
            } catch {
                break;
            }
        }
        assembly {
            mstore(tokens, tokenCount)
        } // Resize array
        return tokens;
    }

    /**
     * @dev Distributes approved tokens to recipients based on their defined percentages.
     * @param _recipients Array of recipients and their corresponding percentages.
     */
    function distribute(Recipient[] memory _recipients) external nonReentrant {
        require(_recipients.length > 0, "Recipients required");
        address[] memory tokens = getTokenList();
        require(tokens.length > 0, "No approved tokens to distribute");

        for (uint256 t = 0; t < tokens.length; t++) {
            IERC20 token = IERC20(tokens[t]);
            uint256 balance = token.balanceOf(address(this));
            if (balance == 0) continue; // Skip empty tokens

            uint256 totalPercentage = 0;
            for (uint256 i = 0; i < _recipients.length; i++) {
                require(
                    _recipients[i].wallet != address(0),
                    "Invalid wallet address"
                );
                require(
                    _recipients[i].percentage > 0,
                    "Percentage must be greater than 0"
                );
                totalPercentage += _recipients[i].percentage;
            }
            require(totalPercentage == PERCENTAGE_SCALE, "Invalid percentages");

            for (uint256 i = 0; i < _recipients.length; i++) {
                uint256 amount = (balance * _recipients[i].percentage) /
                    PERCENTAGE_SCALE;
                token.safeTransfer(_recipients[i].wallet, amount);
            }
        }
    }

    /**
     * @dev Withdraws a specific approved token from the contract.
     * @param _token Address of the token to withdraw.
     * @param to Address to receive the withdrawn tokens.
     */
    function withdrawTokens(address _token, address to) external onlyOwner {
        require(_token != address(0), "Invalid token address");
        require(to != address(0), "Invalid recipient");
        require(approvedTokens[_token], "Token not approved");
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens");
        token.safeTransfer(to, balance);
    }

    /**
     * @dev Allows the contract to receive ETH payments.
     */
    receive() external payable {}
}
