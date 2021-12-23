pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ARAToken.sol";
import "./Governance.sol";

contract Proposal {
    struct Voter {
        bool voted;
        bool approve;
    }

    struct PolicyProposal {
        bytes8 policyIndex;
        bool exists;
        bool openVote;
        uint256 closeVoteTimestamp;
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
        uint256 processResultTimestamp;
        uint256 totalVoter;
        mapping(uint256 => address) votersAddress;
        mapping(address => Voter) voters;
    }

    struct ManagerInfo {
        address addr;
        uint32 controlWeight;
        uint32 maxWeight;
    }

    struct ManagerProposal {
        bytes8 policyIndex;
        bool exists;
        bool openVote;
        uint256 closeVoteTimestamp;
        uint256 totalVoteToken;
        uint256 totalApproveToken;
        uint256 totalSupplyToken;
        bool voteResult;
        uint256 processResultTimestamp;
        uint256 totalVoter;
        uint16 totalManager;
        mapping(uint256 => address) votersAddress;
        mapping(address => Voter) voters;
        mapping(uint16 => ManagerInfo) managers;
    }
       
    address GovernanceContract;

    mapping(address => PolicyProposal) proposals;

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

        PolicyProposal storage p = proposals[addr];
        p.policyIndex = policyIndex;
        p.exists = true;
        p.openVote = true;
        p.closeVoteTimestamp =
            block.timestamp +
            g.getPolicy(policyName).voteDurationSecond;
        p.policyWeight = policyWeight;
        p.maxWeight = maxWeight;
        p.minWeightOpenVote = minWeightOpenVote;
        p.minWeightValidVote = minWeightValidVote;
        p.minWeightApproveVote = minWeightApproveVote;
        p.totalVoter = 0;
    }

    function voteProposal(address addr, bool approve) public {
        require(
            proposals[addr].exists && proposals[addr].openVote,
            "Error 4002: Proposal is closed or did not exists."
        );

        PolicyProposal storage p = proposals[addr];

        if (!p.voters[msg.sender].voted) {
            p.votersAddress[p.totalVoter] = msg.sender;
            p.totalVoter += 1;
            p.voters[msg.sender].voted = true;
            p.voters[msg.sender].approve = approve;
        } else {
            p.voters[msg.sender].approve = approve;
        }
    }

    function processProposal(address addr) public {
        PolicyProposal storage p = proposals[addr];
        require(p.openVote, "Error 4003: Proposal was proceed.");

        p.openVote = false;
        Governance g = Governance(GovernanceContract);
        ERC20 t = ERC20(g.getARATokenContract());
        p.totalVoteToken = 0;
        p.totalApproveToken = 0;
        p.totalSupplyToken = t.totalSupply();

        for (uint256 i = 0; i < p.totalVoter; i++) {
            uint256 voterToken = t.balanceOf(p.votersAddress[i]);
            p.totalVoteToken += voterToken;

            if (p.voters[p.votersAddress[i]].approve) {
                p.totalApproveToken += voterToken;
            }
        }

        bool isVoteValid = p.totalVoteToken >=
            (p.totalSupplyToken *
                g.getPolicyByIndex(p.policyIndex).minWeightOpenVote) /
                g.getPolicyByIndex(p.policyIndex).maxWeight;

        bool isVoteApprove = p.totalApproveToken >=
            (p.totalVoteToken *
                g.getPolicyByIndex(p.policyIndex).minWeightOpenVote) /
                g.getPolicyByIndex(p.policyIndex).maxWeight;

        p.voteResult = isVoteValid && isVoteApprove;

        if (isVoteValid && isVoteApprove) {
            g.setPolicyByProposal(
                p.policyIndex,
                addr,
                p.policyWeight,
                p.maxWeight,
                p.voteDurationSecond,
                p.minWeightOpenVote,
                p.minWeightValidVote,
                p.minWeightApproveVote
            );
        }

        p.processResultTimestamp = block.timestamp;
    }
}
