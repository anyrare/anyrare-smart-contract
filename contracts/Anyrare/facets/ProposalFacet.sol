// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IGovernance.sol";
import "../../shared/libraries/LibUtils.sol";
import {AppStorage, GovernanceManager, GovernanceFounder, GovernanceOperation, GovernancePolicy, PolicyProposalInfo, PolicyProposalIndex, PolicyProposal, ListProposalListInfo, ListProposal} from "../libraries/LibAppStorage.sol";
import "../libraries/LibData.sol";
import "hardhat/console.sol";

contract Proposal {
    AppStorage internal s;

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
        bytes32 policyIndex = LibUtils.stringToBytes32(policyName);
        uint8 voteDecider = (
            LibData.getPolicyByIndex(s, policyIndex).exists
                ? LibData.getPolicyByIndex(s, policyIndex).decider
                : decider
        );

        require(
            (!s.proposal.policyProposalIndexes[policyIndex].exists ||
                !s.proposal.policyProposalIndexes[policyIndex].openVote) &&
                !s
                    .proposal
                    .policyProposals[
                        s.proposal.policyProposalIndexes[policyIndex].id
                    ]
                    .info
                    .countVote &&
                (
                    voteDecider == 0
                        ? LibData.isMember(s, msg.sender)
                        : LibData.isManager(s, msg.sender)
                ) &&
                (
                    voteDecider == 0
                        ? LibData.araBalanceOf(s, msg.sender)
                        : LibData
                            .getManagerByAddress(s, msg.sender)
                            .controlWeight
                ) >=
                ((
                    voteDecider == 0
                        ? LibData.araTotalFreeFloatSupply(s)
                        : LibData.getManagerMaxControlWeight(s)
                ) *
                    (
                        LibData.getPolicyByIndex(s, policyIndex).exists
                            ? (
                                LibData
                                    .getPolicyByIndex(s, policyIndex)
                                    .minWeightOpenVote
                            )
                            : minWeightOpenVote
                    )) /
                    (
                        LibData.getPolicyByIndex(s, policyIndex).exists
                            ? LibData.getPolicyByIndex(s, policyIndex).maxWeight
                            : maxWeight
                    ) &&
                minWeightOpenVote <= maxWeight &&
                minWeightValidVote <= maxWeight &&
                minWeightApproveVote <= maxWeight
        );

        s.proposal.policyProposalId += 1;

        s.proposal.policyProposalIndexes[policyIndex] = PolicyProposalIndex({
            policyIndex: policyIndex,
            id: s.proposal.policyProposalId,
            openVote: true,
            exists: true
        });

        s.proposal.policyProposals[s.proposal.policyProposalId].exists = true;
        s
            .proposal
            .policyProposals[s.proposal.policyProposalId]
            .info = PolicyProposalInfo({
            policyIndex: policyIndex,
            openVote: true,
            countVote: false,
            applyProposal: false,
            closeVoteTimestamp: block.timestamp +
                (
                    LibData.getPolicyByIndex(s, policyIndex).exists
                        ? LibData.getPolicyByIndex(s, policyIndex).voteDuration
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
                LibData.getPolicyByIndex(s, policyIndex).exists
                    ? LibData.getPolicyByIndex(s, policyIndex).decider
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
        uint32 proposalId = s
            .proposal
            .policyProposalIndexes[LibUtils.stringToBytes32(policyName)]
            .id;

        PolicyProposal storage p = s.proposal.policyProposals[proposalId];

        require(
            p.exists &&
                p.info.openVote &&
                (
                    p.info.voteDecider == 0
                        ? LibData.isMember(s, msg.sender)
                        : LibData.isManager(s, msg.sender)
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
        bytes32 policyIndex = LibUtils.stringToBytes32(policyName);

        PolicyProposal storage p = s.proposal.policyProposals[
            s.proposal.policyProposalIndexes[policyIndex].id
        ];

        require(
            p.info.openVote && block.timestamp >= p.info.closeVoteTimestamp,
            "ProposalFacet: proposal not close"
        );

        p.info.openVote = false;
        s.proposal.policyProposalIndexes[policyIndex].openVote = false;
        p.info.totalVoteToken = 0;
        p.info.totalApproveToken = 0;
        p.info.totalSupplyToken = p.info.voteDecider == 0
            ? LibData.araTotalFreeFloatSupply(s)
            : LibData.getManagerMaxControlWeight(s);

        for (uint32 i; i < p.info.totalVoter; i++) {
            uint256 voterToken = p.info.voteDecider == 0
                ? LibData.araBalanceOf(s, p.votersAddress[i])
                : LibData
                    .getManagerByAddress(s, p.votersAddress[i])
                    .controlWeight;
            p.info.totalVoteToken += voterToken;

            if (p.voters[p.votersAddress[i]].approve) {
                p.info.totalApproveToken += voterToken;
            }
        }

        uint256 currentMaxWeight = LibData
            .getPolicyByIndex(s, policyIndex)
            .exists
            ? uint256(LibData.getPolicyByIndex(s, policyIndex).maxWeight)
            : uint256(p.info.maxWeight);

        bool isVoteValid = p.info.totalVoteToken >=
            (p.info.totalSupplyToken *
                (
                    LibData.getPolicyByIndex(s, policyIndex).exists
                        ? LibData
                            .getPolicyByIndex(s, policyIndex)
                            .minWeightValidVote
                        : p.info.minWeightValidVote
                )) /
                currentMaxWeight;

        bool isVoteApprove = p.info.totalApproveToken >=
            (p.info.totalVoteToken *
                (
                    LibData.getPolicyByIndex(s, policyIndex).exists
                        ? LibData
                            .getPolicyByIndex(s, policyIndex)
                            .minWeightApproveVote
                        : p.info.minWeightApproveVote
                )) /
                currentMaxWeight;

        p.info.voteResult = isVoteValid && isVoteApprove;
        p.info.countVote = true;

        p.info.processResultTimestamp = block.timestamp;
    }

    function applyPolicyProposal(string memory policyName) public {
        bytes32 policyIndex = LibUtils.stringToBytes32(policyName);

        PolicyProposal storage p = s.proposal.policyProposals[
            s.proposal.policyProposalIndexes[policyIndex].id
        ];

        require(
            p.info.countVote &&
                !p.info.applyProposal &&
                block.timestamp >=
                p.info.closeVoteTimestamp +
                    LibData.getPolicyByIndex(s, policyIndex).effectiveDuration,
            "ProposalFacet: failed to apply policy proposal"
        );

        if (p.info.voteResult) {
            /*
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
            */
        }

        p.info.applyProposal = true;
        p.info.countVote = false;
    }

    function openListProposal(
        string memory policyName,
        uint256 maxWeight,
        ListProposalListInfo[] memory lists,
        uint16 totalList
    ) public {
        bytes32 policyIndex = LibUtils.stringToBytes32(policyName);
        uint8 decider = LibData.getPolicyByIndex(s, policyIndex).decider;

        require(
            (s.proposal.listProposalId == 0 ||
                !s
                    .proposal
                    .listProposals[s.proposal.listProposalId]
                    .info
                    .openVote) &&
                !s
                    .proposal
                    .listProposals[s.proposal.listProposalId]
                    .info
                    .countVote &&
                (
                    decider == 0
                        ? LibData.isMember(s, msg.sender)
                        : LibData.isManager(s, msg.sender)
                ) &&
                (
                    decider == 0
                        ? LibData.araBalanceOf(s, msg.sender) >=
                            (LibData.araTotalFreeFloatSupply(s) *
                                LibData
                                    .getPolicyByIndex(s, policyIndex)
                                    .minWeightOpenVote) /
                                LibData
                                    .getPolicyByIndex(s, policyIndex)
                                    .maxWeight
                        : LibData
                            .getManagerByAddress(s, msg.sender)
                            .controlWeight >=
                            ((LibData.getManagerMaxControlWeight(s) *
                                LibData
                                    .getPolicyByIndex(s, policyIndex)
                                    .minWeightOpenVote) /
                                LibData
                                    .getPolicyByIndex(s, policyIndex)
                                    .maxWeight)
                )
        );

        uint256 sumWeight = 0;
        for (uint16 i; i < totalList; i++) {
            require(
                LibData.isMember(s, lists[i].addr) &&
                    lists[i].addr != address(0x0) &&
                    lists[i].controlWeight > 0 &&
                    lists[i].controlWeight <= maxWeight
            );
            sumWeight += lists[i].controlWeight;
        }

        require(sumWeight <= maxWeight);

        ListProposal storage p = s.proposal.listProposals[
            s.proposal.listProposalId
        ];
        p.exists = true;
        p.info.policyIndex = policyIndex;
        p.info.openVote = true;
        p.info.countVote = false;
        p.info.applyProposal = false;
        p.info.maxWeight = maxWeight;
        p.info.closeVoteTimestamp =
            block.timestamp +
            LibData.getPolicyByIndex(s, policyIndex).voteDuration;
        p.info.totalList = totalList;
        p.info.totalVoter = 0;

        for (uint16 i = 0; i < totalList; i++) {
            p.lists[i] = ListProposalListInfo({
                addr: lists[i].addr,
                controlWeight: lists[i].controlWeight,
                dataURI: lists[i].dataURI
            });
        }

        s.proposal.listProposalId += 1;
    }

    function voteListProposal(uint32 proposalId, bool approve) public {
        ListProposal storage p = s.proposal.listProposals[proposalId];
        uint8 decider = LibData.getPolicyByIndex(s, p.info.policyIndex).decider;

        require(
            p.exists &&
                p.info.openVote &&
                (
                    decider == 0
                        ? LibData.isMember(s, msg.sender)
                        : LibData.isManager(s, msg.sender)
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
        ListProposal storage p = s.proposal.listProposals[proposalId];
        uint8 decider = LibData.getPolicyByIndex(s, p.info.policyIndex).decider;

        require(
            p.exists &&
                p.info.openVote &&
                block.timestamp >= p.info.closeVoteTimestamp
        );

        p.info.openVote = false;
        p.info.totalVoteToken = 0;
        p.info.totalApproveToken = 0;
        p.info.totalSupplyToken = decider == 0
            ? LibData.araTotalFreeFloatSupply(s)
            : LibData.getManagerMaxControlWeight(s);

        for (uint32 i; i < p.info.totalVoter; i++) {
            uint256 voterToken = decider == 0
                ? LibData.araBalanceOf(s, p.votersAddress[i])
                : LibData
                    .getManagerByAddress(s, p.votersAddress[i])
                    .controlWeight;
            p.info.totalVoteToken += voterToken;

            if (p.voters[p.votersAddress[i]].approve) {
                p.info.totalApproveToken += voterToken;
            }
        }

        p.info.voteValid =
            p.info.totalVoteToken >=
            (p.info.totalSupplyToken *
                LibData
                    .getPolicyByIndex(s, p.info.policyIndex)
                    .minWeightValidVote) /
                LibData.getPolicyByIndex(s, p.info.policyIndex).maxWeight;

        p.info.voteApprove =
            p.info.totalApproveToken >=
            (p.info.totalVoteToken *
                LibData
                    .getPolicyByIndex(s, p.info.policyIndex)
                    .minWeightApproveVote) /
                LibData.getPolicyByIndex(s, p.info.policyIndex).maxWeight;

        p.info.countVote = true;
        p.info.processResultTimestamp = block.timestamp;
    }

    function applyListProposal(uint32 proposalId) public {
        ListProposal storage p = s.proposal.listProposals[proposalId];
        uint8 decider = LibData.getPolicyByIndex(s, p.info.policyIndex).decider;

        require(
            p.info.countVote &&
                !p.info.applyProposal &&
                p.info.voteValid &&
                block.timestamp >=
                p.info.closeVoteTimestamp +
                    LibData
                        .getPolicyByIndex(s, p.info.policyIndex)
                        .effectiveDuration
        );

        bytes32 managerPolicyIndex = LibUtils.stringToBytes32("MANAGERS_LIST");
        bytes32 operationPolicyIndex = LibUtils.stringToBytes32(
            "OPERATIONS_LIST"
        );
        bytes32 auditorPolicyIndex = LibUtils.stringToBytes32("AUDITORS_LIST");
        bytes32 custodianPolicyIndex = LibUtils.stringToBytes32(
            "CUSTODIANS_LIST"
        );

        if (
            (p.info.policyIndex == managerPolicyIndex && p.info.voteApprove) ||
            (p.info.policyIndex == operationPolicyIndex &&
                p.info.voteApprove) ||
            (p.info.policyIndex == auditorPolicyIndex) ||
            (p.info.policyIndex == custodianPolicyIndex)
        ) {
            for (uint16 i; i < p.info.totalList; i++) {
                if (p.info.policyIndex == managerPolicyIndex) {
                    // g().setManagerAtIndexByProposal(
                    //     p.info.totalList,
                    //     i,
                    //     p.lists[i].addr,
                    //     p.lists[i].controlWeight,
                    //     p.info.maxWeight,
                    //     p.lists[i].dataURI
                    // );
                } else if (p.info.policyIndex == operationPolicyIndex) {
                    // g().setOperationAtIndexByProposal(
                    //     p.info.totalList,
                    //     i,
                    //     p.lists[i].addr,
                    //     p.lists[i].controlWeight,
                    //     p.info.maxWeight,
                    //     p.lists[i].dataURI
                    // );
                } else if (p.info.policyIndex == auditorPolicyIndex) {
                    // g().setAuditorByProposal(
                    //     p.lists[i].addr,
                    //     p.info.voteApprove,
                    //     p.lists[i].dataURI
                    // );
                } else if (p.info.policyIndex == custodianPolicyIndex) {
                    // g().setCustodianByProposal(
                    //     p.lists[i].addr,
                    //     p.info.voteApprove,
                    //     p.lists[i].dataURI
                    // );
                }
            }
        }

        p.info.applyProposal = true;
        p.info.countVote = false;
    }
}
