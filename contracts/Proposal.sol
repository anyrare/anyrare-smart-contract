pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ARAToken.sol";
import "./Governance.sol";

contract Proposal {
    struct Voter {
        bool voted;
        bool approve;
    }

    struct ProposalInfo {
        bytes8 policyIndex;
        bool exists;
        bool openVote;
        uint64 closeVoteUnixTimestamp;
        uint32 policyWeight;
        uint32 maxWeight;
        uint32 voteDurationSecond;
        uint32 minWeightOpenVote;
        uint32 minWeightValidVote;
        uint32 minWeightApproveVote;
        uint256 totalVoteToken;
        uint256 totalApproveToken;
        uint256 totalSupplyToken;
        bool voteResult;
        uint64 calculateResultTimestamp;
        mapping(address => Voter) voters;
    }

    address GovernanceContract;

    mapping(address => ProposalInfo) proposals;

    function openProposal(
        string memory policyName,
        address addr,
        uint32 policyWeight,
        uint32 maxWeight,
        uint32 voteDurationSecond,
        uint32 minWeightOpenVote,
        uint32 minWeightValidVote,
        uint32 minWeightApproveVote
    ) public {
        require(
            !proposals[addr].exists,
            "Error 4000: Proposal address already exists."
        );

        Governance g = Governance(GovernanceContract);
        ERC20 t = ERC20(g.getARATokenContract());
        bytes8 policyIndex = g.stringToBytes8(policyName);

        require(
            t.balanceOf(msg.sender) >=
                (t.totalSupply() * g.getPolicy(policyName).minWeightOpenVote) /
                    g.getPolicy(policyName).maxWeight,
            "Error 4001: Insufficient token to open proposal."
        );

        ProposalInfo storage p = proposals[addr];
        p.policyIndex = policyIndex;
        p.exists = true;
        p.openVote = true;
        p.policyWeight = policyWeight;
        p.maxWeight = maxWeight;
        p.minWeightOpenVote = minWeightOpenVote;
        p.minWeightValidVote = minWeightValidVote;
        p.minWeightApproveVote = minWeightApproveVote;
    }

    function voteProposal(address addr, bool approve) public {
        require(
            proposals[addr].exists && proposals[addr].openVote,
            "Error 4002: Proposal is closed or did not exists."
        );

        proposals[addr].voters[msg.sender].voted = true;
        proposals[addr].voters[msg.sender].approve = true;
    }
}
