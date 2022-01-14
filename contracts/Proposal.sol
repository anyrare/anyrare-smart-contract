pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ARAToken.sol";
import "./Governance.sol";
import "./Member.sol";
import "./ProposalDataType.sol";

contract Proposal is ProposalDataType {
    address private governanceContract;
    uint32 public policyProposalId;
    uint32 public listProposalId;

    mapping(bytes32 => PolicyProposalIndex) public policyProposalIndexes;
    mapping(uint32 => PolicyProposal) public policyProposals;
    mapping(uint32 => ListProposal) public listProposals;

    constructor(address _governanceContract) {
        governanceContract = _governanceContract;
        listProposalId = 0;
    }

    function g() private view returns (Governance) {
        return Governance(governanceContract);
    }

    function m() private view returns (Member) {
        return Member(g().getMemberContract());
    }

    function t() private view returns (ARAToken) {
        return ARAToken(g().getARATokenContract());
    }

    function max(uint256 x, uint256 y) private view returns (uint256) {
        return x > y ? x : y;
    }

    function min(uint256 x, uint256 y) private view returns (uint256) {
        return x < y ? x : y;
    }

    function openPolicyProposal(
        string memory policyName,
        uint256 policyWeight,
        uint256 maxWeight,
        uint32 voteDuration,
        uint32 effectiveDuration,
        uint256 minWeightOpenVote,
        uint256 minWeightValidVote,
        uint256 minWeightApproveVote,
        uint256 policyValue,
        uint8 decider
    ) public {
        bytes32 policyIndex = g().stringToBytes32(policyName);
        uint8 voteDecider = (
            g().getPolicyByIndex(policyIndex).exists
                ? g().getPolicyByIndex(policyIndex).decider
                : decider
        );

        require(
            (!policyProposalIndexes[policyIndex].exists ||
                !policyProposalIndexes[policyIndex].openVote) &&
                !policyProposals[policyProposalIndexes[policyIndex].id]
                    .info
                    .countVote &&
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
                        ? t().totalFreeFloatSupply()
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
                    ) &&
                minWeightOpenVote <= maxWeight &&
                minWeightValidVote <= maxWeight &&
                minWeightApproveVote <= maxWeight
        );

        policyProposalId += 1;

        policyProposalIndexes[policyIndex] = PolicyProposalIndex({
            policyIndex: policyIndex,
            id: policyProposalId,
            openVote: true,
            exists: true
        });

        PolicyProposal storage p = policyProposals[policyProposalId];
        p.exists = true;
        p.info = PolicyProposalInfo({
            policyIndex: policyIndex,
            openVote: true,
            countVote: false,
            applyProposal: false,
            closeVoteTimestamp: block.timestamp +
                (
                    g().getPolicyByIndex(policyIndex).exists
                        ? g().getPolicyByIndex(policyIndex).voteDuration
                        : voteDuration
                ),
            policyWeight: policyWeight,
            maxWeight: maxWeight,
            voteDuration: voteDuration,
            effectiveDuration: effectiveDuration,
            minWeightOpenVote: minWeightOpenVote,
            minWeightValidVote: minWeightValidVote,
            minWeightApproveVote: minWeightApproveVote,
            policyValue: policyValue,
            decider: decider,
            voteDecider: (
                g().getPolicyByIndex(policyIndex).exists
                    ? g().getPolicyByIndex(policyIndex).decider
                    : decider
            ),
            totalVoteToken: 0,
            totalApproveToken: 0,
            totalSupplyToken: 0,
            voteResult: false,
            processResultTimestamp: 0,
            totalVoter: 0
        });
    }

    function votePolicyProposal(string memory policyName, bool approve) public {
        uint32 proposalId = policyProposalIndexes[
            g().stringToBytes32(policyName)
        ].id;

        PolicyProposal storage p = policyProposals[proposalId];

        require(
            p.exists &&
                p.info.openVote &&
                (
                    p.info.voteDecider == 0
                        ? m().isMember(msg.sender)
                        : g().isManager(msg.sender)
                ) &&
                block.timestamp < p.info.closeVoteTimestamp
        );

        if (!p.voters[msg.sender].voted) {
            p.votersAddress[p.info.totalVoter] = msg.sender;
            p.info.totalVoter += 1;
            p.voters[msg.sender].voted = true;
            p.voters[msg.sender].approve = approve;
        } else {
            p.voters[msg.sender].approve = approve;
        }
    }

    function countVotePolicyProposal(string memory policyName) public {
        bytes32 policyIndex = g().stringToBytes32(policyName);

        PolicyProposal storage p = policyProposals[
            policyProposalIndexes[policyIndex].id
        ];

        require(
            p.info.openVote && block.timestamp >= p.info.closeVoteTimestamp
        );

        p.info.openVote = false;
        policyProposalIndexes[policyIndex].openVote = false;
        p.info.totalVoteToken = 0;
        p.info.totalApproveToken = 0;
        p.info.totalSupplyToken = p.info.voteDecider == 0
            ? t().totalFreeFloatSupply()
            : g().getManagerMaxControlWeight();

        for (uint32 i = 0; i < p.info.totalVoter; i++) {
            uint256 voterToken = p.info.voteDecider == 0
                ? t().balanceOf(p.votersAddress[i])
                : g().getManagerByAddress(p.votersAddress[i]).controlWeight;
            p.info.totalVoteToken += voterToken;

            if (p.voters[p.votersAddress[i]].approve) {
                p.info.totalApproveToken += voterToken;
            }
        }

        uint256 currentMaxWeight = g().getPolicyByIndex(policyIndex).exists
            ? uint256(g().getPolicyByIndex(policyIndex).maxWeight)
            : uint256(p.info.maxWeight);

        bool isVoteValid = p.info.totalVoteToken >=
            (p.info.totalSupplyToken *
                (
                    g().getPolicyByIndex(policyIndex).exists
                        ? g().getPolicyByIndex(policyIndex).minWeightValidVote
                        : p.info.minWeightValidVote
                )) /
                currentMaxWeight;

        bool isVoteApprove = p.info.totalApproveToken >=
            (p.info.totalVoteToken *
                (
                    g().getPolicyByIndex(policyIndex).exists
                        ? g().getPolicyByIndex(policyIndex).minWeightApproveVote
                        : p.info.minWeightApproveVote
                )) /
                currentMaxWeight;

        p.info.voteResult = isVoteValid && isVoteApprove;
        p.info.countVote = true;

        p.info.processResultTimestamp = block.timestamp;
    }

    function applyPolicyProposal(string memory policyName) public {
        bytes32 policyIndex = g().stringToBytes32(policyName);

        PolicyProposal storage p = policyProposals[
            policyProposalIndexes[policyIndex].id
        ];

        require(
            p.info.countVote &&
                !p.info.applyProposal &&
                block.timestamp >=
                p.info.closeVoteTimestamp +
                    g().getPolicyByIndex(policyIndex).effectiveDuration
        );

        if (p.info.voteResult) {
            g().setPolicyByProposal(
                p.info.policyIndex,
                p.info.policyWeight,
                p.info.maxWeight,
                p.info.voteDuration,
                p.info.minWeightOpenVote,
                p.info.minWeightValidVote,
                p.info.minWeightApproveVote,
                p.info.policyValue,
                p.info.decider
            );
        }

        p.info.applyProposal = true;
        p.info.countVote = false;
    }

    function openListProposal(
        string memory policyName,
        uint256 maxWeight,
        ListInfo[] memory lists,
        uint16 totalList
    ) public {
        bytes32 policyIndex = g().stringToBytes32(policyName);
        uint8 decider = g().getPolicyByIndex(policyIndex).decider;

        require(
            (listProposalId == 0 ||
                !listProposals[listProposalId].info.openVote) &&
                !listProposals[listProposalId].info.countVote &&
                (
                    decider == 0
                        ? m().isMember(msg.sender)
                        : g().isManager(msg.sender)
                ) &&
                (
                    decider == 0
                        ? t().balanceOf(msg.sender) >=
                            (t().totalFreeFloatSupply() *
                                g()
                                    .getPolicyByIndex(policyIndex)
                                    .minWeightOpenVote) /
                                g().getPolicyByIndex(policyIndex).maxWeight
                        : g().getManagerByAddress(msg.sender).controlWeight >=
                            ((g().getManagerMaxControlWeight() *
                                g()
                                    .getPolicyByIndex(policyIndex)
                                    .minWeightOpenVote) /
                                g().getPolicyByIndex(policyIndex).maxWeight)
                )
        );

        uint256 sumWeight = 0;
        for (uint16 i = 0; i < totalList; i++) {
            require(
                m().isMember(lists[i].addr) &&
                    lists[i].addr != address(0x0) &&
                    lists[i].controlWeight > 0 &&
                    lists[i].controlWeight <= maxWeight
            );
            sumWeight += lists[i].controlWeight;
        }

        require(sumWeight <= maxWeight);

        ListProposal storage p = listProposals[listProposalId];
        p.exists = true;
        p.info.policyIndex = policyIndex;
        p.info.openVote = true;
        p.info.countVote = false;
        p.info.applyProposal = false;
        p.info.maxWeight = maxWeight;
        p.info.closeVoteTimestamp =
            block.timestamp +
            g().getPolicyByIndex(policyIndex).voteDuration;
        p.info.totalList = totalList;
        p.info.totalVoter = 0;

        for (uint16 i = 0; i < totalList; i++) {
            p.lists[i] = ListInfo({
                addr: lists[i].addr,
                controlWeight: lists[i].controlWeight,
                dataURI: lists[i].dataURI
            });
        }

        listProposalId += 1;
    }

    function voteListProposal(uint32 proposalId, bool approve) public {
        ListProposal storage p = listProposals[proposalId];
        uint8 decider = g().getPolicyByIndex(p.info.policyIndex).decider;

        require(
            p.exists &&
                p.info.openVote &&
                (
                    decider == 0
                        ? m().isMember(msg.sender)
                        : g().isManager(msg.sender)
                ) &&
                block.timestamp < p.info.closeVoteTimestamp
        );

        if (!p.voters[msg.sender].voted) {
            p.votersAddress[p.info.totalVoter] = msg.sender;
            p.info.totalVoter += 1;
            p.voters[msg.sender].voted = true;
            p.voters[msg.sender].approve = approve;
        } else {
            p.voters[msg.sender].approve = approve;
        }
    }

    function countVoteListProposal(uint32 proposalId) public {
        ListProposal storage p = listProposals[proposalId];
        uint8 decider = g().getPolicyByIndex(p.info.policyIndex).decider;

        require(
            p.exists &&
                p.info.openVote &&
                block.timestamp >= p.info.closeVoteTimestamp
        );

        p.info.openVote = false;
        p.info.totalVoteToken = 0;
        p.info.totalApproveToken = 0;
        p.info.totalSupplyToken = decider == 0
            ? t().totalFreeFloatSupply()
            : g().getManagerMaxControlWeight();

        for (uint32 i = 0; i < p.info.totalVoter; i++) {
            uint256 voterToken = decider == 0
                ? t().balanceOf(p.votersAddress[i])
                : g().getManagerByAddress(p.votersAddress[i]).controlWeight;
            p.info.totalVoteToken += voterToken;

            if (p.voters[p.votersAddress[i]].approve) {
                p.info.totalApproveToken += voterToken;
            }
        }

        p.info.voteValid =
            p.info.totalVoteToken >=
            (p.info.totalSupplyToken *
                g().getPolicyByIndex(p.info.policyIndex).minWeightValidVote) /
                g().getPolicyByIndex(p.info.policyIndex).maxWeight;

        p.info.voteApprove =
            p.info.totalApproveToken >=
            (p.info.totalVoteToken *
                g().getPolicyByIndex(p.info.policyIndex).minWeightApproveVote) /
                g().getPolicyByIndex(p.info.policyIndex).maxWeight;

        p.info.countVote = true;
        p.info.processResultTimestamp = block.timestamp;
    }

    function applyListProposal(uint32 proposalId) public {
        ListProposal storage p = listProposals[proposalId];
        uint8 decider = g().getPolicyByIndex(p.info.policyIndex).decider;

        require(
            p.info.countVote &&
                !p.info.applyProposal &&
                p.info.voteValid &&
                block.timestamp >=
                p.info.closeVoteTimestamp +
                    g().getPolicyByIndex(p.info.policyIndex).effectiveDuration
        );

        bytes32 managerPolicyIndex = g().stringToBytes32("MANAGERS_LIST");
        bytes32 operationPolicyIndex = g().stringToBytes32("OPERATIONS_LIST");
        bytes32 auditorPolicyIndex = g().stringToBytes32("AUDITORS_LIST");
        bytes32 custodianPolicyIndex = g().stringToBytes32("CUSTODIANS_LIST");

        if (
            (p.info.policyIndex == managerPolicyIndex && p.info.voteApprove) ||
            (p.info.policyIndex == operationPolicyIndex &&
                p.info.voteApprove) ||
            (p.info.policyIndex == auditorPolicyIndex) ||
            (p.info.policyIndex == custodianPolicyIndex)
        ) {
            for (uint16 i = 0; i < p.info.totalList; i++) {
                if (p.info.policyIndex == managerPolicyIndex) {
                    g().setManagerAtIndexByProposal(
                        p.info.totalList,
                        i,
                        p.lists[i].addr,
                        p.lists[i].controlWeight,
                        p.info.maxWeight,
                        p.lists[i].dataURI
                    );
                } else if (p.info.policyIndex == operationPolicyIndex) {
                    g().setOperationAtIndexByProposal(
                        p.info.totalList,
                        i,
                        p.lists[i].addr,
                        p.lists[i].controlWeight,
                        p.info.maxWeight,
                        p.lists[i].dataURI
                    );
                } else if (p.info.policyIndex == auditorPolicyIndex) {
                    g().setAuditorByProposal(
                        p.lists[i].addr,
                        p.info.voteApprove,
                        p.lists[i].dataURI
                    );
                } else if (p.info.policyIndex == custodianPolicyIndex) {
                    g().setCustodianByProposal(
                        p.lists[i].addr,
                        p.info.voteApprove,
                        p.lists[i].dataURI
                    );
                }
            }
        }

        p.info.applyProposal = true;
        p.info.countVote = false;
    }

    function getCurrentPolicyProposal(string memory policyName)
        public
        view
        returns (PolicyProposalInfo memory policyProposalInfo)
    {
        bytes32 policyIndex = g().stringToBytes32(policyName);
        return policyProposals[policyProposalIndexes[policyIndex].id].info;
    }

    function getCurrentPolicyProposalId() public view returns (uint256) {
        return policyProposalId - 1;
    }

    function getCurrentListProposalId() public view returns (uint256) {
        return listProposalId - 1;
    }
}
