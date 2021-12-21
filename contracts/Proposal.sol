pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ARAToken.sol";
import "./Governance.sol";

contract Proposal {
    struct Voter {
        bool voted;
        bool approve;
    }

    bytes8 policyIndex;
    bool isOpenVote;
    uint64 closeVoteUnixTimestamp;
    uint32 policyWeight;
    uint32 maxWeight;
    uint32 voteDurationSecond;
    uint32 minimumWeightOpenVote;
    uint32 minimumWeightValidVote;
    uint32 minimumWeightApproveVote;
    uint256 totalVoteToken;
    uint256 totalApproveToken;
    uint256 totalSupplyToken;
    bool voteResult;
    uint64 calculateResultTimestamp;

    mapping(address => Voter) voters;

    function openProposal(
        string memory policyName,
        address addr,
        Policy memory v
    ) public {
        bytes8 policyIndex = stringToBytes8(policyName);
        Policy storage p = policies[policyIndex];

        require(
            ERC20(ARATokenContract).balanceOf(msg.sender) >=
                (ERC20(ARATokenContract).totalSupply() *
                    p.minimumWeightOpenVote) /
                    p.maxWeight,
            "Error 3002: Insufficient token to open proposal."
        );

        // Proposal storage ps = proposals[addr];
    }
}
