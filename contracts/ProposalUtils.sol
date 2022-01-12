pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ARAToken.sol";
import "./ProposalDataType.sol";
import "./Governance.sol";
import "./Member.sol";

contract ProposalUtils is ProposalDataType {
    address private governanceContract;

    constructor(address _governanceContract) {
        governanceContract = _governanceContract;
    }

    function g() private view returns (Governance) {
        return Governance(governanceContract);
    }

    function m() private view returns (Member) {
        return Member(g().getMemberContract());
    }

    function t() public view returns (ARAToken) {
        return ARAToken(g().getARATokenContract());
    }

    function max(uint256 x, uint256 y) public view returns (uint256) {
        return x > y ? x : y;
    }

    function min(uint256 x, uint256 y) public view returns (uint256) {
        return x < y ? x : y;
    }

    function requireOpenPolicyProposal(
        PolicyProposalIndex memory policyProposalIndex,
        bool countVote,
        uint8 voteDecider,
        bytes32 policyIndex,
        uint256 minWeightOpenVote,
        uint256 maxWeight
    ) public view {
        require(
            (!policyProposalIndex.exists || !policyProposalIndex.openVote) &&
                !countVote &&
                (
                    voteDecider == 0
                        ? m().isMember(msg.sender)
                        : g().isManager(msg.sender)
                ) &&
                (
                    voteDecider == 0
                        ? t().balanceOf(msg.sender)
                        : g().getManagerByAddress(msg.sender).controlWeight
                ) >=
                ((
                    voteDecider == 0
                        ? t().totalSupply()
                        : g().getManagerMaxControlWeight()
                ) *
                    (
                        g().getPolicyByIndex(policyIndex).exists
                            ? (
                                g()
                                    .getPolicyByIndex(policyIndex)
                                    .minWeightOpenVote
                            )
                            : minWeightOpenVote
                    )) /
                    (
                        g().getPolicyByIndex(policyIndex).exists
                            ? g().getPolicyByIndex(policyIndex).maxWeight
                            : maxWeight
                    )
        );
    }

    function requireVotePolicyProposal(
        bool exists,
        PolicyProposalInfo memory info,
        address sender
    ) public view {
        require(
            exists &&
                info.openVote &&
                (
                    info.voteDecider == 0
                        ? m().isMember(sender)
                        : g().isManager(sender)
                ) &&
                block.timestamp < info.closeVoteTimestamp
        );
    }
}
