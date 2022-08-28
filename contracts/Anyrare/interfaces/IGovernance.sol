// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGovernance {
    struct InitPolicy {
        string policyName;
        uint256 policyWeight;
        uint256 maxWeight;
        uint32 voteDuration;
        uint32 effectiveDuration;
        uint256 minWeightOpenVote;
        uint256 minWeightValidVote;
        uint256 minWeightApproveVote;
        uint256 policyValue;
        uint8 decider;
    }
}
