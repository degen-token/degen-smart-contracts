/**
 *Submitted for verification at Etherscan.io on 2022-05-07
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
@title Vote Escrowed DEGEN
@author Gentlemen Labs, Curve Finance, Multichain, Loot
@notice Votes have a weight depending on time, so that users are
committed to the future of (whatever they are voting for)
@dev Vote weight decays linearly over time. Lock time cannot be
more than `MAXTIME` (4 years).

# Voting escrow to have time-weighted votes
# Votes have a weight depending on time, so that users are committed
# to the future of (whatever they are voting for).
# The weight in this implementation is linear, and lock cannot be more than maxtime:
# w ^
# 1 +        /
#   |      /
#   |    /
#   |  /
#   |/
# 0 +--------+------> time
#       maxtime (4 years?)
*/
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {FixedPointMathLib} from "../utils/FixedPointMathLib.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev Here we extend the ERC721Enumerable standard to enumerate delegated tokens as well.
 */
abstract contract ERC721DelegateEnumerable is ERC721, ERC721Enumerable {
    event Delegate(address from, address to, uint256 tokenId);

    // Mapping from token ID to delegate address
    mapping(uint256 => address) private _delegates;

    // Mapping delegated address to token count
    mapping(address => uint256) private _delegatedBalances;

    // Mapping from delegate to list of delegated token IDs
    mapping(address => mapping(uint256 => uint256)) private _delegatedTokens;

    // Mapping from token ID to index of the delegate tokens list
    mapping(uint256 => uint256) private _delegatedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allDelegatedTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allDelegatedTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function delegateOf(
        uint256 tokenId
    ) public view virtual returns (address) {
        address delegate = _delegates[tokenId];
        require(
            delegate != address(0),
            "ERC721DelegateEnumerable: delegate query for undelegated token"
        );
        return delegate;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function delegatedBalanceOf(
        address delegate
    ) public view virtual returns (uint256) {
        require(
            delegate != address(0),
            "ERC721DelegateEnumerable: delegated balance query for the zero address"
        );
        return _delegatedBalances[delegate];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function delegateFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721DelegateEnumerable: transfer caller is not owner nor approved"
        );

        _delegate(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeDelegateFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        safeDelegateFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeDelegateFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721DelegateEnumerable: delegate caller is not owner nor approved"
        );
        _safeDelegate(from, to, tokenId, _data);
    }

    /**
     * @dev Safely delegates `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeDelegateFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Delegate} event.
     */
    function _safeDelegate(
        address from,
        address to,
        uint256 tokenId,
        bytes memory /*_data*/
    ) internal virtual {
        _delegate(from, to, tokenId);
    }

    /**
     * @dev Delegates `tokenId` from `from` to `to`.
     *  As opposed to {delegateFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Delegate} event.
     */
    function _delegate(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721DelegateEnumerable: delegate to the zero address");

        _beforeTokenDelegation(from, to, tokenId);

        _delegatedBalances[from] -= 1;
        _delegatedBalances[to] += 1;
        _delegates[tokenId] = to;

        _afterTokenDelegation(from, to, tokenId);
        
        emit Delegate(from, to, tokenId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex} and replace owner with delegate.
     */
    function tokenOfDelegateByIndex(
        address delegate,
        uint256 index
    ) public view virtual returns (uint256) {
        require(
            index < delegatedBalanceOf(delegate),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _delegatedTokens[delegate][index];
    }

    /**
    /**
     * @dev Private function to add a token to this extension's delegation-tracking data structures.
     * @param to address representing the new delegate of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToDelegateEnumeration(address to, uint256 tokenId) private {
        uint256 length = delegatedBalanceOf(to);
        _delegatedTokens[to][length] = tokenId;
        _delegatedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToDelegatedTokensEnumeration(uint256 tokenId) private {
        _allDelegatedTokensIndex[tokenId] = _allDelegatedTokens.length;
        _allDelegatedTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's delegate-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_delegatedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _delegatedTokens array.
     * @param from address representing the previous delegate of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromDelegateEnumeration(
        address from,
        uint256 tokenId
    ) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = delegatedBalanceOf(from) - 1;
        uint256 tokenIndex = _delegatedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _delegatedTokens[from][lastTokenIndex];

            _delegatedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _delegatedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _delegatedTokensIndex[tokenId];
        delete _delegatedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allDelegatedTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromDelegatedTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allDelegatedTokens.length - 1;
        uint256 tokenIndex = _allDelegatedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allDelegatedTokens[lastTokenIndex];

        _allDelegatedTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allDelegatedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allDelegatedTokensIndex[tokenId];
        _allDelegatedTokens.pop();
    }

    /**
     * @dev Hook that is called before any token delegation.
     * 
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be delegated to `to`.
     * - When `to` is zero, delegation will be returned to the owner.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenDelegation(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (from == address(0)) {
            _addTokenToDelegatedTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromDelegateEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromDelegatedTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToDelegateEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Hook that is called after any token delegation.
     * 
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be delegated to `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be delegated to `from`.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenDelegation(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (from == address(0)) {
            _addTokenToDelegatedTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromDelegateEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromDelegatedTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToDelegateEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address /* from */,
        address to,
        uint256 tokenId,
        uint256 /* batchSize */
    ) internal virtual {
        _update(to, tokenId, _msgSender());
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        return super._isAuthorized(ownerOf(tokenId), spender, tokenId);
    }

    function _update(address to, uint256 tokenId, address auth) internal virtual override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 amount) internal virtual override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }
}

struct Point {
    int128 bias;
    int128 slope; // # -dweight / dt
    uint256 ts;
    uint256 blk; // block
}
/* We cannot really do block numbers per se b/c slope is per time, not per block
 * and per block could be fairly bad b/c Ethereum changes blocktimes.
 * What we can do is to extrapolate ***At functions */

struct LockedBalance {
    int128 amount;
    uint256 end;
}

abstract contract veDEGEN is ERC721DelegateEnumerable, Ownable, ReentrancyGuard {
    using Address for address;
    using FixedPointMathLib for uint256;
    using Strings for uint256;

    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME,
        MERGE_TYPE
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Lock(
        address indexed provider,
        uint256 tokenId,
        uint256 value,
        uint256 indexed locktime,
        DepositType deposit_type,
        uint256 ts
    );

    event Unlock(address indexed provider, uint256 tokenId, uint256 value, uint256 ts);

    event Supply(uint256 prevSupply, uint256 supply);

    // ERC4626 Events
    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WEEK = 1 weeks;
    uint256 internal constant MAXTIME = 4 * 365 * 86400;
    uint256 internal constant MULTIPLIER = 1 ether;

    ERC20 public immutable asset;

    /// @notice Contract constructor
    /// @param _asset `ERC20` token address of the vault asset
    /// @param _name The name of the token minted by the vault
    /// @param _symbol The symbol of the token minted by the vault
    constructor(ERC20 _asset, string memory _name, string memory _symbol) ERC721(_name, _symbol) Ownable(msg.sender) {
        asset = _asset;
        voter = _msgSender();
        point_history[0].blk = block.number;
        point_history[0].ts = block.timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    uint256 public supply;
    mapping(uint256 => LockedBalance) public locked;

    // Set the block of ownership transfer (for Flash NFT protection)
    mapping(uint256 => uint256) public ownership_change;
    mapping(uint256 => uint256) public delegation_change;

    uint256 public epoch;
    mapping(uint256 => Point) public point_history; // epoch -> unsigned point
    mapping(uint256 => Point[1000000000]) public user_point_history; // user -> Point[user_epoch]

    mapping(uint256 => uint256) public user_point_epoch;
    mapping(uint256 => int128) public slope_changes; // time -> signed slope change

    mapping(uint256 => uint256) public attachments;
    mapping(uint256 => bool) public voted;
    address public voter;

    /// @dev Current count of token
    uint256 internal tokenCount;

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 batchSize
    ) internal virtual override(ERC721DelegateEnumerable) {
        super._afterTokenTransfer(_from, _to, _tokenId, batchSize);
        ownership_change[_tokenId] = block.number;
    }

    /**
     * @dev Hook that is called before any token delegation. 
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * delegated to `to`.
     * - When `from` is zero, `tokenId` will be delegated to `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be delegated to self.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenDelegation(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenDelegation(from, to, tokenId);
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Hook that is called after any token delegation.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * delegated to `to`.
     * - When `from` is zero, `tokenId` will be delegated to `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be redelegated to owner.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenDelegation(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override {
        super._afterTokenDelegation(_from, _to, _tokenId);
        delegation_change[_tokenId] = block.number;
    }

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view returns (uint256) {
        return supply == 0 ? assets : assets.mulDiv(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        return supply == 0 ? shares : shares.mulDiv(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view returns (uint256) {
        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view returns (uint256) {
        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view returns (uint256) {
        return convertToAssets(shares);
    }

    function maxDeposit(address) public pure returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public pure returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view returns (uint256) {
        return convertToAssets(balanceOf(owner));
    }

    function maxRedeem(address owner) public view returns (uint256) {
        return balanceOf(owner);
    }

    /// @notice Get the most recently recorded rate of voting power decrease for `_tokenId`
    /// @param _tokenId token of the NFT
    /// @return Value of the slope
    function get_last_user_slope(uint256 _tokenId) external view returns (int128) {
        uint256 uepoch = user_point_epoch[_tokenId];
        return user_point_history[_tokenId][uepoch].slope;
    }

    /// @notice Get the timestamp for checkpoint `_idx` for `_tokenId`
    /// @param _tokenId token of the NFT
    /// @param _idx User epoch number
    /// @return Epoch time of the checkpoint
    function user_point_history__ts(
        uint256 _tokenId,
        uint256 _idx
    ) external view returns (uint) {
        return user_point_history[_tokenId][_idx].ts;
    }

    /// @notice Get timestamp when `_tokenId`'s lock finishes
    /// @param _tokenId User NFT
    /// @return Epoch time of the lock end
    function locked__end(uint256 _tokenId) external view returns (uint) {
        return locked[_tokenId].end;
    }

    /// @notice Record global and per-user data to checkpoint
    /// @param _tokenId NFT token ID. No user checkpoint if 0
    /// @param old_locked Pevious locked amount / end lock time for the user
    /// @param new_locked New locked amount / end lock time for the user
    function _checkpoint(
        uint256 _tokenId,
        LockedBalance memory old_locked,
        LockedBalance memory new_locked
    ) internal {
        Point memory u_old;
        Point memory u_new;
        int128 old_dslope = 0;
        int128 new_dslope = 0;
        uint256 _epoch = epoch;

        if (_tokenId != 0) {
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (old_locked.end > block.timestamp && old_locked.amount > 0) {
                u_old.slope = old_locked.amount / int128(int256(MAXTIME));
                u_old.bias =
                    u_old.slope *
                    int128(int256(old_locked.end - block.timestamp));
            }
            if (new_locked.end > block.timestamp && new_locked.amount > 0) {
                u_new.slope = new_locked.amount / int128(int256(MAXTIME));
                u_new.bias =
                    u_new.slope *
                    int128(int256(new_locked.end - block.timestamp));
            }

            // Read values of scheduled changes in the slope
            // old_locked.end can be in the past and in the future
            // new_locked.end can ONLY by in the FUTURE unless everything expired: than zeros
            old_dslope = slope_changes[old_locked.end];
            if (new_locked.end != 0) {
                if (new_locked.end == old_locked.end) {
                    new_dslope = old_dslope;
                } else {
                    new_dslope = slope_changes[new_locked.end];
                }
            }
        }

        Point memory last_point = Point({
            bias: 0,
            slope: 0,
            ts: block.timestamp,
            blk: block.number
        });
        if (_epoch > 0) {
            last_point = point_history[_epoch];
        }
        uint256 last_checkpoint = last_point.ts;
        // initial_last_point is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        Point memory initial_last_point = last_point;
        uint256 block_slope = 0; // dblock/dt
        if (block.timestamp > last_point.ts) {
            block_slope =
                (MULTIPLIER * (block.number - last_point.blk)) /
                (block.timestamp - last_point.ts);
        }
        // If last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case

        // Go over weeks to fill history and calculate what the current point is
        {
            uint256 t_i = (last_checkpoint / WEEK) * WEEK;
            for (uint256 i = 0; i < 255; ++i) {
                // Hopefully it won't happen that this won't get used in 5 years!
                // If it does, users will be able to withdraw but vote weight will be broken
                t_i += WEEK;
                int128 d_slope = 0;
                if (t_i > block.timestamp) {
                    t_i = block.timestamp;
                } else {
                    d_slope = slope_changes[t_i];
                }
                last_point.bias -=
                    last_point.slope *
                    int128(int256(t_i - last_checkpoint));
                last_point.slope += d_slope;
                if (last_point.bias < 0) {
                    // This can happen
                    last_point.bias = 0;
                }
                if (last_point.slope < 0) {
                    // This cannot happen - just in case
                    last_point.slope = 0;
                }
                last_checkpoint = t_i;
                last_point.ts = t_i;
                last_point.blk =
                    initial_last_point.blk +
                    (block_slope * (t_i - initial_last_point.ts)) /
                    MULTIPLIER;
                _epoch += 1;
                if (t_i == block.timestamp) {
                    last_point.blk = block.number;
                    break;
                } else {
                    point_history[_epoch] = last_point;
                }
            }
        }

        epoch = _epoch;
        // Now point_history is filled until t=now

        if (_tokenId != 0) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            last_point.slope += (u_new.slope - u_old.slope);
            last_point.bias += (u_new.bias - u_old.bias);
            if (last_point.slope < 0) {
                last_point.slope = 0;
            }
            if (last_point.bias < 0) {
                last_point.bias = 0;
            }
        }

        // Record the changed point into history
        point_history[_epoch] = last_point;

        if (_tokenId != 0) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [new_locked.end]
            // and add old_user_slope to [old_locked.end]
            if (old_locked.end > block.timestamp) {
                // old_dslope was <something> - u_old.slope, so we cancel that
                old_dslope += u_old.slope;
                if (new_locked.end == old_locked.end) {
                    old_dslope -= u_new.slope; // It was a new deposit, not extension
                }
                slope_changes[old_locked.end] = old_dslope;
            }

            if (new_locked.end > block.timestamp) {
                if (new_locked.end > old_locked.end) {
                    new_dslope -= u_new.slope; // old slope disappeared at this point
                    slope_changes[new_locked.end] = new_dslope;
                }
                // else: we recorded it already in old_dslope
            }
            // Now handle user history
            uint256 user_epoch = user_point_epoch[_tokenId] + 1;

            user_point_epoch[_tokenId] = user_epoch;
            u_new.ts = block.timestamp;
            u_new.blk = block.number;
            user_point_history[_tokenId][user_epoch] = u_new;
        }
    }

    /// @notice Deposit and lock tokens for a user
    /// @param _tokenId NFT that holds lock
    /// @param _value Amount to deposit
    /// @param unlock_time New time when to unlock the tokens, or 0 if unchanged
    /// @param locked_balance Previous locked amount / timestamp
    /// @param deposit_type The type of deposit
    function _deposit_for(
        uint256 _tokenId,
        uint256 _value,
        uint256 unlock_time,
        LockedBalance memory locked_balance,
        DepositType deposit_type
    ) internal {
        LockedBalance memory _locked = locked_balance;
        uint256 supply_before = supply;

        supply = supply_before + _value;
        LockedBalance memory old_locked;
        (old_locked.amount, old_locked.end) = (_locked.amount, _locked.end);
        // Adding to existing lock, or if a lock is expired - creating a new one
        _locked.amount += int128(int256(_value));
        if (unlock_time != 0) {
            _locked.end = unlock_time;
        }
        locked[_tokenId] = _locked;

        // Possibilities:
        // Both old_locked.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)
        _checkpoint(_tokenId, old_locked, _locked);

        address from = _msgSender();
        if (_value != 0 && deposit_type != DepositType.MERGE_TYPE) {
            assert(ERC20(asset).transferFrom(from, address(this), _value));
        }

        emit Deposit(from, ownerOf(_tokenId), _value, _value);
        emit Lock(
            from,
            _tokenId,
            _value,
            _locked.end,
            deposit_type,
            block.timestamp
        );
        emit Supply(supply_before, supply_before + _value);
    }

    function setVoter(address _voter) external {
        require(_msgSender() == voter);
        voter = _voter;
    }

    function voting(uint256 _tokenId) external {
        require(_msgSender() == voter);
        voted[_tokenId] = true;
    }

    function abstain(uint256 _tokenId) external {
        require(_msgSender() == voter);
        voted[_tokenId] = false;
    }

    function attach(uint256 _tokenId) external {
        require(_msgSender() == voter);
        attachments[_tokenId] = attachments[_tokenId] + 1;
    }

    function detach(uint256 _tokenId) external {
        require(_msgSender() == voter);
        attachments[_tokenId] = attachments[_tokenId] - 1;
    }

    function merge(uint256 _from, uint256 _to) external {
        require(attachments[_from] == 0 && !voted[_from], "attached");
        require(_from != _to);
        require(_isApprovedOrOwner(_msgSender(), _from));
        require(_isApprovedOrOwner(_msgSender(), _to));

        LockedBalance memory _locked0 = locked[_from];
        LockedBalance memory _locked1 = locked[_to];
        uint256 value0 = uint(int256(_locked0.amount));
        uint256 end = _locked0.end >= _locked1.end ? _locked0.end : _locked1.end;

        locked[_from] = LockedBalance(0, 0);
        _checkpoint(_from, _locked0, LockedBalance(0, 0));
        _burn(_from);
        _deposit_for(_to, value0, end, _locked1, DepositType.MERGE_TYPE);
    }

    function block_number() external view returns (uint) {
        return block.number;
    }

    /// @notice Record global data to checkpoint
    function checkpoint() external {
        _checkpoint(0, LockedBalance(0, 0), LockedBalance(0, 0));
    }

    /// @notice Deposit `_value` tokens for `_tokenId` and add to the lock
    /// @dev Anyone (even a smart contract) can deposit for someone else, but
    ///      cannot extend their locktime and deposit for a brand new user
    /// @param assets Amount to add to user's lock
    /// @param tokenId lock NFT
    function deposit(uint256 assets, uint256 tokenId) external nonReentrant {
        LockedBalance memory _locked = locked[tokenId];

        require(assets > 0, "Cannot deposit zero assets"); // dev: need non-zero value
        require(_locked.amount > 0, "No existing lock found");
        require(
            _locked.end > block.timestamp,
            "Cannot add to expired lock. Withdraw"
        );
        _deposit_for(
            tokenId,
            assets,
            0,
            _locked,
            DepositType.DEPOSIT_FOR_TYPE
        );
    }

    /// @notice Deposit `_value` tokens for `_to` and lock for `_lock_duration`
    /// @param _value Amount to deposit
    /// @param _lock_duration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @param _to Address to deposit
    function _create_lock(
        uint256 _value,
        uint256 _lock_duration,
        address _to
    ) internal returns (uint) {
        uint256 unlock_time = ((block.timestamp + _lock_duration) / WEEK) * WEEK; // Locktime is rounded down to weeks

        require(_value > 0); // dev: need non-zero value
        require(
            unlock_time > block.timestamp,
            "Can only lock until time in the future"
        );
        require(
            unlock_time <= block.timestamp + MAXTIME,
            "Voting lock can be 4 years max"
        );

        ++tokenCount;
        uint256 _tokenId = tokenCount;
        _mint(_to, _tokenId);

        _deposit_for(
            _tokenId,
            _value,
            unlock_time,
            locked[_tokenId],
            DepositType.CREATE_LOCK_TYPE
        );
        return _tokenId;
    }

    /// @notice Deposit `_value` tokens for `_to` and lock for `_lock_duration`
    /// @param value Amount to deposit
    /// @param lock_duration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @param to Address to deposit
    function mint(
        uint256 value,
        address to,
        uint256 lock_duration
    ) external nonReentrant returns (uint) {
        return _create_lock(value, lock_duration, to);
    }

    /// @notice Deposit `_value` tokens for `msg.sender` and lock for `_lock_duration`
    /// @param _value Amount to deposit
    /// @param _lock_duration Number of seconds to lock tokens for (rounded down to nearest week)
    function create_lock(
        uint256 _value,
        uint256 _lock_duration
    ) external nonReentrant returns (uint) {
        return _create_lock(_value, _lock_duration, _msgSender());
    }

    /// @notice Deposit `_value` additional tokens for `_tokenId` without modifying the unlock time
    /// @param _value Amount of tokens to deposit and add to the lock
    function increase_amount(uint256 _tokenId, uint256 _value) external nonReentrant {
        require(_isApprovedOrOwner(_msgSender(), _tokenId));

        LockedBalance memory _locked = locked[_tokenId];

        require(_value > 0); // dev: need non-zero value
        require(_locked.amount > 0, "No existing lock found");
        require(
            _locked.end > block.timestamp,
            "Cannot add to expired lock. Withdraw"
        );

        _deposit_for(
            _tokenId,
            _value,
            0,
            _locked,
            DepositType.INCREASE_LOCK_AMOUNT
        );
    }

    /// @notice Extend the unlock time for `_tokenId`
    /// @param _lock_duration New number of seconds until tokens unlock
    function increase_unlock_time(
        uint256 _tokenId,
        uint256 _lock_duration
    ) external nonReentrant {
        require(_isApprovedOrOwner(_msgSender(), _tokenId));

        LockedBalance memory _locked = locked[_tokenId];
        uint256 unlock_time = ((block.timestamp + _lock_duration) / WEEK) * WEEK; // Locktime is rounded down to weeks

        require(_locked.end > block.timestamp, "Lock expired");
        require(_locked.amount > 0, "Nothing is locked");
        require(unlock_time > _locked.end, "Can only increase lock duration");
        require(
            unlock_time <= block.timestamp + MAXTIME,
            "Voting lock can be 4 years max"
        );

        _deposit_for(
            _tokenId,
            0,
            unlock_time,
            _locked,
            DepositType.INCREASE_UNLOCK_TIME
        );
    }

    /// TODO: Figure out redeem function to redeem excess assets earned by the DEGEN vault
    /// @notice Withdraw all tokens for `_tokenId` and send them to receiver
    /// @dev Only possible if the lock has expired
    /// @param shares Amount of shares to redeem 
    /// @param receiver Address to receive the assets 
    /// @param owner Owner of the assets
    /// @param tokenId Token ID to withdraw from
    /// @return assets Amount of assets transferred
    function redeem(
        uint256 shares,
        address receiver,
        address owner,
        uint256 tokenId
    ) external nonReentrant returns (uint256 /* assets */) {
        this.withdraw(shares, receiver, owner, tokenId);
    }

    /// @notice Withdraw all tokens for `_tokenId` and send them to receiver
    /// @dev Only possible if the lock has expired
    /// @param assets Amount of assets to withdraw
    /// @param receiver Address to receive the assets 
    /// @param owner Owner of the assets
    /// @param tokenId Token ID to withdraw from
    /// @return shares Amount of shares burned
    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        uint256 tokenId
    ) external nonReentrant returns (uint256 shares) {
        require(ownerOf(tokenId) == owner, "Not token owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Not approved");
        require(attachments[tokenId] == 0 && !voted[tokenId], "Token attached");

        LockedBalance memory _locked = locked[tokenId];
        
        // Calculate decayed amount based on slope
        uint256 time_left;
        if (block.timestamp >= _locked.end) {
            time_left = 0;
        } else {
            time_left = _locked.end - block.timestamp;
        }
 
        uint256 decayed_amount = uint(int256(_locked.amount)) - _balanceOfNFT(tokenId, block.timestamp);
        
        require(assets <= decayed_amount, "Amount exceeds unlocked balance");

        shares = assets; // 1:1 ratio for veToken
        
        // Update locked balance
        int128 remaining = _locked.amount - int128(int256(assets));
        if (remaining == 0) {
            locked[tokenId] = LockedBalance(0, 0);
            _burn(tokenId); // Burn NFT if fully withdrawn
        } else {
            locked[tokenId] = LockedBalance(remaining, _locked.end);
        }

        uint256 supply_before = supply;
        supply = supply_before - assets;

        _checkpoint(tokenId, _locked, locked[tokenId]);

        assert(ERC20(asset).transfer(receiver, assets));

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
        emit Unlock(msg.sender, tokenId, assets, block.timestamp);
        emit Supply(supply_before, supply_before - assets);
    }

    /// @notice Set lock dates to current block for all tokens for `_tokenId`
    /// @dev Only usable by contract owner 
    function setLockEndToCurrentBlock() external onlyOwner {
        uint256 currentSupply = totalSupply();
        for (uint256 tokenId = 1; tokenId <= currentSupply; tokenId++) {
            if (_exists(tokenId)) {
                LockedBalance memory _locked = locked[tokenId];
                if (_locked.end > 0) { // Only modify active locks
                    // Create new lock with same amount but current block as end
                    LockedBalance memory newLock = LockedBalance(_locked.amount, block.timestamp);
                    // Checkpoint the change
                    _checkpoint(tokenId, _locked, newLock);
                    // Update storage
                    locked[tokenId] = newLock;
                }
            }
        }
    }

    // The following ERC20/minime-compatible methods are not real balanceOf and supply!
    // They measure the weights for the purpose of voting, so they don't represent
    // real coins.

    /// @notice Binary search to estimate timestamp for block number
    /// @param _block Block to find
    /// @param max_epoch Don't go beyond this epoch
    /// @return Approximate timestamp for block
    function _find_block_epoch(
        uint256 _block,
        uint256 max_epoch
    ) internal view returns (uint) {
        // Binary search
        uint256 _min = 0;
        uint256 _max = max_epoch;
        for (uint256 i = 0; i < 128; ++i) {
            // Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (point_history[_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    /// @notice Get the current voting power for `_tokenId`
    /// @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
    /// @param _tokenId NFT for lock
    /// @param _t Epoch time to return voting power at
    /// @return User voting power
    function _balanceOfNFT(
        uint256 _tokenId,
        uint256 _t
    ) internal view returns (uint) {
        uint256 _epoch = user_point_epoch[_tokenId];
        if (_epoch == 0) {
            return 0;
        } else {
            Point memory last_point = user_point_history[_tokenId][_epoch];
            last_point.bias -=
                last_point.slope *
                int128(int256(_t) - int256(last_point.ts));
            if (last_point.bias < 0) {
                last_point.bias = 0;
            }
            return uint(int256(last_point.bias));
        }
    }

    /// @dev Returns current token URI metadata
    /// @param tokenId Token ID to fetch URI for.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        LockedBalance memory _locked = locked[tokenId];
        return
            _tokenURI(
                tokenId,
                _balanceOfNFT(tokenId, block.timestamp),
                _locked.end,
                uint(int256(_locked.amount))
            );
    }

    function balanceOfNFT(uint256 _tokenId) external view returns (uint) {
        if (ownership_change[_tokenId] == block.number) return 0;
        return _balanceOfNFT(_tokenId, block.timestamp);
    }

    function balanceOfNFTAt(
        uint256 _tokenId,
        uint256 _t
    ) external view returns (uint) {
        return _balanceOfNFT(_tokenId, _t);
    }

    /// @notice Measure voting power of `_tokenId` at block height `_block`
    /// @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
    /// @param _tokenId User's wallet NFT
    /// @param _block Block to calculate the voting power at
    /// @return Voting power
    function _balanceOfAtNFT(
        uint256 _tokenId,
        uint256 _block
    ) internal view returns (uint) {
        // Copying and pasting totalSupply code because Vyper cannot pass by
        // reference yet
        assert(_block <= block.number);

        // Binary search
        uint256 _min = 0;
        uint256 _max = user_point_epoch[_tokenId];
        for (uint256 i = 0; i < 128; ++i) {
            // Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (user_point_history[_tokenId][_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        Point memory upoint = user_point_history[_tokenId][_min];

        uint256 max_epoch = epoch;
        uint256 _epoch = _find_block_epoch(_block, max_epoch);
        Point memory point_0 = point_history[_epoch];
        uint256 d_block = 0;
        uint256 d_t = 0;
        if (_epoch < max_epoch) {
            Point memory point_1 = point_history[_epoch + 1];
            d_block = point_1.blk - point_0.blk;
            d_t = point_1.ts - point_0.ts;
        } else {
            d_block = block.number - point_0.blk;
            d_t = block.timestamp - point_0.ts;
        }
        uint256 block_time = point_0.ts;
        if (d_block != 0) {
            block_time += (d_t * (_block - point_0.blk)) / d_block;
        }

        upoint.bias -= upoint.slope * int128(int256(block_time - upoint.ts));
        if (upoint.bias >= 0) {
            return uint(uint128(upoint.bias));
        } else {
            return 0;
        }
    }

    function balanceOfAtNFT(
        uint256 _tokenId,
        uint256 _block
    ) external view returns (uint) {
        return _balanceOfAtNFT(_tokenId, _block);
    }

    /// @notice Calculate total voting power at some point in the past
    /// @param point The point (bias/slope) to start search from
    /// @param t Time to calculate the total voting power at
    /// @return Total voting power at that time
    function _supply_at(
        Point memory point,
        uint256 t
    ) internal view returns (uint) {
        Point memory last_point = point;
        uint256 t_i = (last_point.ts / WEEK) * WEEK;
        for (uint256 i = 0; i < 255; ++i) {
            t_i += WEEK;
            int128 d_slope = 0;
            if (t_i > t) {
                t_i = t;
            } else {
                d_slope = slope_changes[t_i];
            }
            last_point.bias -=
                last_point.slope *
                int128(int256(t_i - last_point.ts));
            if (t_i == t) {
                break;
            }
            last_point.slope += d_slope;
            last_point.ts = t_i;
        }

        if (last_point.bias < 0) {
            last_point.bias = 0;
        }
        return uint(uint128(last_point.bias));
    }

    /// @notice Calculate total voting power
    /// @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
    /// @return Total voting power
    function totalSupplyAtT(uint256 t) public view returns (uint) {
        uint256 _epoch = epoch;
        Point memory last_point = point_history[_epoch];
        return _supply_at(last_point, t);
    }

    function totalSupply() public view virtual override returns (uint) {
        return totalSupplyAtT(block.timestamp);
    }

    /// @notice Calculate total voting power at some point in the past
    /// @param _block Block to calculate the total voting power at
    /// @return Total voting power at `_block`
    function totalSupplyAt(uint256 _block) external view returns (uint) {
        assert(_block <= block.number);
        uint256 _epoch = epoch;
        uint256 target_epoch = _find_block_epoch(_block, _epoch);

        Point memory point = point_history[target_epoch];
        uint256 dt = 0;
        if (target_epoch < _epoch) {
            Point memory point_next = point_history[target_epoch + 1];
            if (point.blk != point_next.blk) {
                dt =
                    ((_block - point.blk) * (point_next.ts - point.ts)) /
                    (point_next.blk - point.blk);
            }
        } else {
            if (point.blk != block.number) {
                dt =
                    ((_block - point.blk) * (block.timestamp - point.ts)) /
                    (block.number - point.blk);
            }
        }
        // Now dt contains info on how far are we beyond point
        return _supply_at(point, point.ts + dt);
    }

    string[] private weapons = [
        "Walking Cane",     // 0
        "Sword Cane",       // 1
        "Parasol",          // 2
        "Riding Crop",      // 3
        "Opera Glasses",    // 4
        "Lorgnette",        // 5
        "Spyglass",         // 6
        "Fountain Pen",     // 7
        "Pipe",             // 8
        "Snuff Box",        // 9
        "Pocket Watch",     // 10
        "Card Case",        // 11
        "Rifle"             // 12
        "Dueling Pistol",   // 13
        "Fan",              // 14
        "Gizmo",            // 15
        "Broadsheet",       // 16
        "Prayer Book"      // 17
    ];

    string[] private chestArmor = [
        "Shirt",                // 0
        "Linen Shirt",          // 1
        "Silk Shirt",           // 2
        "Morning Coat",         // 3
        "Velvet Tailcoat",      // 4
        "Tweed Jacket",         // 5
        "Embroidered Jacket",   // 6
        "Frock Coat",           // 7
        "Wool Overcoat",        // 8
        "Whalebone Corset",     // 9
        "Brocade Bodice",       // 10
        "Evening Gown",         // 11
        "Day Dress",            // 12
        "Ball Gown",            // 13
        "Shawl"                 // 14
    ];

    string[] private headArmor = [
        "Top Hat",      // 0
        "Bowler Hat",   // 1
        "Trilby",       // 2
        "Deerstalker",  // 3
        "Straw Hat",    // 4
        "Turban",       // 5
        "Cowl",         // 6
        "Skull Cap",    // 7
        "Pith Helmet"   // 8
        "Monocle",      // 9
        "Pince-nez",    // 10
        "Lace Cap",     // 11
        "Bonnet",       // 12
        "Fascinator",   // 13
        "Veil"         // 14
    ];

    string[] private waistArmor = [
        "Forager Belt",     // 0
        "Ornate Belt",      // 1
        "Pleated Belt",     // 2
        "Mesh Belt",        // 3
        "Bustle",           // 4
        "Leopard Hide",     // 5
        "Sword Belt",       // 6
        "Crocodile Belt",   // 7
        "Cowhide Belt",     // 8
        "Cumberbund",       // 9
        "Lifting Belt",     // 10
        "Silk Sash",        // 11
        "Wool Sash",        // 12
        "Linen Sash",       // 13
        "Sash"              // 14
    ];

    string[] private footArmor = [
        "Loafers",          // 0
        "Brogues",          // 1
        "Oxfords",          // 2
        "Monkstraps",       // 3
        "Riding Boots",     // 4
        "Combat Boots",     // 5
        "Buckskin Boots",   // 6
        "Pilgrim Boots",    // 7
        "Crocodile Boots",  // 8
        "Cowhide Boots",    // 9
        "Glass Slippers",   // 10
        "Silk Slippers",    // 11
        "Wool Slippers",    // 12
        "Linen Slippers",   // 13
        "Slippers"          // 14
    ];

    string[] private handArmor = [
        "Smudged Fingers",  // 0
        "Ornate Gloves",    // 1
        "Gauntlets",        // 2
        "Claws",            // 3
        "Boxing Gloves",    // 4
        "Bear Hands",       // 5
        "Fencing Gloves",   // 6
        "Bangles",          // 7
        "Crocodile Gloves", // 8
        "Cowhide Gloves",   // 9
        "Velvet Gloves",    // 10
        "Silk Gloves",      // 11
        "Wool Gloves",      // 12
        "Linen Gloves",     // 13
        "Gloves"            // 14
    ];

    string[] private necklaces = ["Necklace", "Amulet", "Pendant"];

    string[] private rings = [
        "Gold Ring",
        "Silver Ring",
        "Bronze Ring",
        "Platinum Ring",
        "Titanium Ring"
    ];

    string[] private suffixes = [
        "of Power",
        "of Giants",
        "of Titans",
        "of Skill",
        "of Perfection",
        "of Brilliance",
        "of Enlightenment",
        "of Protection",
        "of Anger",
        "of Rage",
        "of Fury",
        "of Vitriol",
        "of the Fox",
        "of Detection",
        "of Reflection",
        "of the Twins"
    ];

    string[] private namePrefixes = [
        "Agony",
        "Apocalypse",
        "Armageddon",
        "Beast",
        "Behemoth",
        "Blight",
        "Blood",
        "Bramble",
        "Brimstone",
        "Brood",
        "Carrion",
        "Cataclysm",
        "Chimeric",
        "Corpse",
        "Corruption",
        "Damnation",
        "Death",
        "Demon",
        "Dire",
        "Dragon",
        "Dread",
        "Doom",
        "Dusk",
        "Eagle",
        "Empyrean",
        "Fate",
        "Foe",
        "Gale",
        "Ghoul",
        "Gloom",
        "Glyph",
        "Golem",
        "Grim",
        "Hate",
        "Havoc",
        "Honour",
        "Horror",
        "Hypnotic",
        "Kraken",
        "Loath",
        "Maelstrom",
        "Mind",
        "Miracle",
        "Morbid",
        "Oblivion",
        "Onslaught",
        "Pain",
        "Pandemonium",
        "Phoenix",
        "Plague",
        "Rage",
        "Rapture",
        "Rune",
        "Skull",
        "Sol",
        "Soul",
        "Sorrow",
        "Spirit",
        "Storm",
        "Tempest",
        "Torment",
        "Vengeance",
        "Victory",
        "Viper",
        "Vortex",
        "Woe",
        "Wrath",
        "Light's",
        "Shimmering"
    ];

    string[] private nameSuffixes = [
        "Bane",
        "Root",
        "Bite",
        "Song",
        "Roar",
        "Grasp",
        "Instrument",
        "Glow",
        "Bender",
        "Shadow",
        "Whisper",
        "Shout",
        "Growl",
        "Tear",
        "Peak",
        "Form",
        "Sun",
        "Moon"
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getWeapon(uint256 _tokenId) public view returns (string memory) {
        return pluck(_tokenId, "WEAPON", weapons);
    }

    function getChest(uint256 _tokenId) public view returns (string memory) {
        return pluck(_tokenId, "CHEST", chestArmor);
    }

    function getHead(uint256 _tokenId) public view returns (string memory) {
        return pluck(_tokenId, "HEAD", headArmor);
    }

    function getWaist(uint256 _tokenId) public view returns (string memory) {
        return pluck(_tokenId, "WAIST", waistArmor);
    }

    function getFoot(uint256 _tokenId) public view returns (string memory) {
        return pluck(_tokenId, "FOOT", footArmor);
    }

    function getHand(uint256 _tokenId) public view returns (string memory) {
        return pluck(_tokenId, "HAND", handArmor);
    }

    function getNeck(uint256 _tokenId) public view returns (string memory) {
        return pluck(_tokenId, "NECK", necklaces);
    }

    function getRing(uint256 _tokenId) public view returns (string memory) {
        return pluck(_tokenId, "RING", rings);
    }

    function pluck(
        uint256 _tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal view returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, toString(_tokenId)))
        );
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 21;
        if (greatness > 14) {
            output = string(
                abi.encodePacked(output, " ", suffixes[rand % suffixes.length])
            );
        }
        if (greatness >= 19) {
            string[2] memory name;
            name[0] = namePrefixes[rand % namePrefixes.length];
            name[1] = nameSuffixes[rand % nameSuffixes.length];
            if (greatness == 19) {
                output = string(
                    abi.encodePacked('"', name[0], " ", name[1], '" ', output)
                );
            } else {
                output = string(
                    abi.encodePacked(
                        '"',
                        name[0],
                        " ",
                        name[1],
                        '" ',
                        output,
                        " +1"
                    )
                );
            }
        }
        return output;
    }

    function _tokenURI(
        uint256 _tokenId,
        uint256 _balanceOf,
        uint256 _locked_end,
        uint256 _value
    ) public view returns (string memory) {
        string[23] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: #A36EFD; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="#4C2897" /><text x="10" y="20" class="base">';

        parts[1] = getWeapon(_tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getChest(_tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getHead(_tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getWaist(_tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getFoot(_tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getHand(_tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getNeck(_tokenId);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getRing(_tokenId);

        parts[16] = '</text><text x="10" y="200" class="base">Vault Weight';

        parts[17] = toString(_balanceOf / totalSupply());

        parts[18] = '</text><text x="10" y="220" class="base">Locked Until Block';

        parts[19] = toString(_locked_end);

        parts[20] = '</text><text x="10" y="240" class="base">Redeemable for';

        parts[21] = toString(_value);

        parts[22] = 'DEGEN</text></svg>';
        
        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7],
                parts[8]
            )
        );

        output = string(
            abi.encodePacked(
                output,
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14],
                parts[15],
                parts[16]
            )
        );

        output = string(
            abi.encodePacked(
                output,
                parts[17],
                parts[18],
                parts[19],
                parts[20],
                parts[21],
                parts[22]
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Deposit #',
                        toString(_tokenId),
                        '", "description": "veDEGEN with dLoot is randomized gentleperson gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use dLoot in any way you want.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
