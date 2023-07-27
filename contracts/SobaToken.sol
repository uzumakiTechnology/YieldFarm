// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SobaToken is ERC20, Ownable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1_000_000_000 * 10 ** 18);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function mint(address _to, uint256 _amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(_to, _amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function transferMinterRole(address newMinter) public onlyOwner {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        revokeRole(MINTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, newMinter);
    }
}
