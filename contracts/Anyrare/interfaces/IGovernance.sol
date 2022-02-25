// SPDX-License-Identifier: MIT

interface IGovernance {
    struct Founder {
        address addr;
        uint256 controlWeight;
    }

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
