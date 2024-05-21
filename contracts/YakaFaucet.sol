// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "./interfaces/IERC20.sol";

contract YakaFaucet is Ownable {

    struct ClaimRecord {
        uint256 claimTime;
        uint256 claimedAount;
        bool claimed;
    }

    address public yakaAddress;
    mapping(address => ClaimRecord) public claimRecordMap;
    uint256 public maxClaimAmount;
    // can claimable every day
    bool public dailyClaimable;


    constructor(address _yakaAddress, uint256 _maxClaimAmount) {
        yakaAddress = _yakaAddress;
        maxClaimAmount = _maxClaimAmount;
        dailyClaimable = false;
    }

    function setMaxClaimAmount(uint256 _maxClaimAmount) external onlyOwner {
        maxClaimAmount = _maxClaimAmount;
    }

    function setDailyClaimable(bool _dailyClaimable) external onlyOwner {
        dailyClaimable = _dailyClaimable;
    }


    function claim() external {
        ClaimRecord storage claimRecord = claimRecordMap[msg.sender];
        if(dailyClaimable) {
            require(block.timestamp - claimRecord.claimTime > 1 days, "has claimed in 24 hours");
            require(IERC20(yakaAddress).balanceOf(address(this)) >= maxClaimAmount, "not enough balance to claim");
            claimRecord.claimTime = block.timestamp;
            claimRecord.claimedAount = maxClaimAmount;
            claimRecord.claimed = true;
            IERC20(yakaAddress).transfer(msg.sender, maxClaimAmount);
        }else {
            require(claimRecord.claimed == false, "has claimed");
            require(IERC20(yakaAddress).balanceOf(address(this)) >= maxClaimAmount, "not enough balance to claim");
            claimRecord.claimTime = block.timestamp;
            claimRecord.claimedAount = maxClaimAmount;
            claimRecord.claimed = true;
            IERC20(yakaAddress).transfer(msg.sender, maxClaimAmount);
        }
        
    }

    function getClaimRecord(address _user) external view returns(uint256 claimTime, uint256 claimedAount, bool claimed) {
        ClaimRecord memory claimRecord = claimRecordMap[_user];
        return (claimRecord.claimTime, claimRecord.claimedAount, claimRecord.claimed);
    }


}