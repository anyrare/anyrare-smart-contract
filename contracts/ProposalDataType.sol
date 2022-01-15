pragma solidity ^0.8.0;
pragma abicoder v2;

contract ProposalDataType {
    struct Voter {
        bool voted;
        bool approve;
    }

    struct PolicyProposalIndex {
        bytes32 policyIndex;
        uint32 id;
        bool openVote;
        bool exists;
    }

    struct PolicyProposal {
        bool exists;
        PolicyProposalInfo info;
        mapping(uint32 => address) votersAddress;
        mapping(address => Voter) voters;
    }

    struct PolicyProposalInfo {
        bytes32 policyIndex;
        bool openVote;
        bool countVote;
        bool applyProposal;
        uint256 closeVoteTimestamp;
        uint256 policyWeight;
        uint256 maxWeight;
        uint32 voteDuration;
        uint32 effectiveDuration;
        uint256 minWeightOpenVote;
        uint256 minWeightValidVote;
        uint256 minWeightApproveVote;
        uint256 policyValue;
        uint8 decider;
        uint8 voteDecider;
        uint256 totalVoteToken;
        uint256 totalApproveToken;
        uint256 totalSupplyToken;
        bool voteResult;
        uint256 processResultTimestamp;
        uint32 totalVoter;
    }

    struct ListInfo {
        address addr;
        uint256 controlWeight;
        string dataURI;
    }

    struct ListProposalInfo {
        bytes32 policyIndex;
        bool openVote;
        bool countVote;
        bool applyProposal;
        bool voteValid;
        bool voteApprove;
        uint256 maxWeight;
        uint256 closeVoteTimestamp;
        uint256 totalVoteToken;
        uint256 totalApproveToken;
        uint256 totalSupplyToken;
        uint256 processResultTimestamp;
        uint32 totalVoter;
        uint16 totalList;
    }

    struct ListProposal {
        bool exists;
        ListProposalInfo info;
        mapping(uint32 => address) votersAddress;
        mapping(address => Voter) voters;
        mapping(uint16 => ListInfo) lists;
    }
}
