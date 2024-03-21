// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IInitialDistributor {
    function setMinter(address _minter) external;
    function setStartPeriod(uint256 _start_period) external;
}
