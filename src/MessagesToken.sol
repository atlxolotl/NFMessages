// SPDX-License-Identifier:  GPL-3.0-only
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract MessagesToken is ERC20, ERC20Burnable, AccessControl, ERC20Permit, ERC20Votes {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public immutable mintingAndLockDeadline;

    constructor(uint256 _mintingAndLockDeadline)
        ERC20("MessagesToken", "NFMT")
        ERC20Permit("MessageToken")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        mintingAndLockDeadline = _mintingAndLockDeadline;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function clock() public view override returns (uint48) {
        return uint48(block.timestamp);
    }

    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=timestamp";
    }

    // The following functions are overrides required by Solidity.

    // Transfers a value amount of tokens from from to to, or alternatively 
    // mints (or burns) if from (or to) is the zero address. All customizations
    // to transfers, mints, and burns should be done by overriding this 
    //function.
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        //require(block.timestamp > mintingAndLockDeadline || 
        //        from == address(0) || to == address(0),
        //"Transfers not allowed before lock dead line");
        require(block.timestamp < mintingAndLockDeadline && from == address(0) ||
        block.timestamp > mintingAndLockDeadline && from != address(0),
        "Transfer or minting DeadLine Issue");
        //require(from != address(0) || to == address(0),
        //"Token is not mintable after lock dead line");
        super._update(from, to, value);
    }

    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}

