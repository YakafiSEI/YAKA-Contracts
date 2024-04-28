// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract ERC20Token is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}
    function mintFixed() external {
        _mint(msg.sender, 1000*1e18);
    }

    function mint(address account, uint256 amount) external returns (bool) {
        _mint(account, amount);
        return true;
    }


}