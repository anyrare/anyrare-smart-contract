pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ARAToken.sol";
import "./Governance.sol";

contract Proposal {
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
        uint32 timelockDuration;
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

    struct ManagerInfo {
        address addr;
        uint256 controlWeight;
    }

    struct ManagerProposalInfo {
        bool openVote;
        bool countVote;
        bool applyProposal;
        uint256 maxWeight;
        uint256 closeVoteTimestamp;
        uint256 totalVoteToken;
        uint256 totalApproveToken;
        uint256 totalSupplyToken;
        bool voteResult;
        uint256 processResultTimestamp;
        uint32 totalVoter;
        uint16 totalManager;
    }

    struct ManagerProposal {
        bool exists;
        ManagerProposalInfo info;
        mapping(uint32 => address) votersAddress;
        mapping(address => Voter) voters;
        mapping(uint16 => ManagerInfo) managers;
    }

    struct AuditorProposalInfo {
        bool openVote;
        bool countVote;
        bool applyProposal;
        bool voteValid;
        bool voteApprove;
        uint256 closeVoteTimestamp;
        uint256 totalVoteToken;
        uint256 totalApproveToken;
        uint256 totalSupplyToken;
        uint256 processResultTimestamp;
        uint32 totalVoter;
        address addr;
    }

    struct AuditorProposal {
        bool exists;
        AuditorProposalInfo info;
        mapping(uint32 => address) votersAddress;
        mapping(address => Voter) voters;
    }

    struct CustodianProposalInfo {
        bool openVote;
        bool countVote;
        bool applyProposal;
        bool voteValid;
        bool voteApprove;
        uint256 closeVoteTimestamp;
        uint256 totalVoteToken;
        uint256 totalApproveToken;
        uint256 totalSupplyToken;
        uint256 processResultTimestamp;
        uint32 totalVoter;
        address addr;
    }

    struct CustodianProposal {
        bool exists;
        CustodianProposalInfo info;
        mapping(uint32 => address) votersAddress;
        mapping(address => Voter) voters;
    }

    address private governanceContract;
    uint32 private policyProposalId;
    uint32 private managerProposalId;
    uint32 private auditorProposalId;
    uint32 private custodianProposalId;

    mapping(bytes32 => PolicyProposalIndex) private policyProposalIndexs;
    mapping(uint32 => PolicyProposal) private policyProposals;
    mapping(uint32 => ManagerProposal) private managerProposals;
    mapping(uint32 => AuditorProposal) private auditorProposals;
    mapping(uint32 => CustodianProposal) private custodianProposals;

    constructor(address _governanceContract) {
        governanceContract = _governanceContract;
        policyProposalId = 0;
        managerProposalId = 0;
        auditorProposalId = 0;
        custodianProposalId = 0;
    }

    function g() private view returns (Governance) {
        return Governance(governanceContract);
    }

    function m() private view returns (Member) {
        return Member(g().getMemberContract());
    }

    function t() private view returns (ERC20) {
        return ERC20(g().getARATokenContract());
    }

    function isMember(address addr) public view returns (bool) {
        return m().isMember(addr);
    }

    function isManager(address addr) public view returns (bool) {
        return g().isManager(addr);
    }

    function openPolicyProposal(
        string memory policyName,
        uint256 policyWeight,
        uint256 maxWeight,
        uint32 voteDuration,
        uint256 minWeightOpenVote,
        uint256 minWeightValidVote,
        uint256 minWeightApproveVote,
        uint256 policyValue,
        uint8 decider
    ) public {
        bytes32 policyIndex = g().stringToBytes32(policyName);

        uint8 voteDecider = g().getPolicyByIndex(policyIndex).exists
            ? g().getPolicyByIndex(policyIndex).decider
            : decider;

        require(
            (!policyProposalIndexs[policyIndex].exists ||
                !policyProposalIndexs[policyIndex].openVote) &&
                (
                    voteDecider == 0
                        ? isMember(msg.sender)
                        : isManager(msg.sender)
                ) &&
                (
                    voteDecider == 0
                        ? (t().balanceOf(msg.sender))
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
                    ),
            "40"
        );

        policyProposalId += 1;

        PolicyProposalIndex storage pIndex = policyProposalIndexs[policyIndex];
        pIndex.policyIndex = policyIndex;
        pIndex.id = policyProposalId;
        pIndex.openVote = true;
        pIndex.exists = true;

        PolicyProposal storage p = policyProposals[policyProposalId];
        p.exists = true;
        p.info.policyIndex = policyIndex;
        p.info.openVote = true;
        p.info.countVote = false;
        p.info.applyProposal = false;
        p.info.closeVoteTimestamp =
            block.timestamp +
            (
                g().getPolicyByIndex(policyIndex).exists
                    ? g().getPolicyByIndex(policyIndex).voteDuration
                    : voteDuration
            );
        p.info.policyWeight = policyWeight;
        p.info.maxWeight = maxWeight;
        p.info.minWeightOpenVote = minWeightOpenVote;
        p.info.minWeightValidVote = minWeightValidVote;
        p.info.minWeightApproveVote = minWeightApproveVote;
        p.info.policyValue = policyValue;
        p.info.decider = decider;
        p.info.totalVoter = 0;
        p.info.voteDecider = voteDecider;
    }

    function votePolicyProposal(string memory policyName, bool approve) public {
        uint32 proposalId = policyProposalIndexs[
            g().stringToBytes32(policyName)
        ].id;

        PolicyProposal storage p = policyProposals[proposalId];

        require(
            (policyProposals[proposalId].exists &&
                policyProposals[proposalId].info.openVote) &&
                (
                    p.info.voteDecider == 0
                        ? isMember(msg.sender)
                        : isManager(msg.sender)
                ) &&
                block.timestamp < p.info.closeVoteTimestamp,
            "41"
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
            policyProposalIndexs[policyIndex].id
        ];

        require(
            p.info.openVote && block.timestamp >= p.info.closeVoteTimestamp,
            "42"
        );

        p.info.openVote = false;
        policyProposalIndexs[policyIndex].openVote = false;
        p.info.totalVoteToken = 0;
        p.info.totalApproveToken = 0;
        p.info.totalSupplyToken = p.info.voteDecider == 0
            ? t().totalSupply()
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
            policyProposalIndexs[policyIndex].id
        ];

        require(
            p.info.countVote &&
                !p.info.applyProposal &&
                block.timestamp >=
                p.info.closeVoteTimestamp +
                    g().getPolicyByIndex(policyIndex).timelockDuration,
            "42"
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
    }

    function openManagerProposal(
        uint16 totalManager,
        uint256 maxWeight,
        ManagerInfo[] memory managers
    ) public {
        bytes32 policyIndex = g().stringToBytes32("MANAGERS_LIST");

        require(
            (managerProposalId == 0 ||
                !managerProposals[managerProposalId].info.openVote) &&
                isMember(msg.sender) &&
                t().balanceOf(msg.sender) >=
                (t().totalSupply() *
                    g().getPolicyByIndex(policyIndex).minWeightOpenVote) /
                    g().getPolicyByIndex(policyIndex).maxWeight,
            "43"
        );

        for (uint16 i = 0; i < totalManager; i++) {
            require(isMember(managers[i].addr), "44");
        }

        managerProposalId += 1;

        ManagerProposal storage p = managerProposals[managerProposalId];
        p.exists = true;
        p.info.openVote = true;
        p.info.countVote = false;
        p.info.applyProposal = false;
        p.info.maxWeight = maxWeight;
        p.info.closeVoteTimestamp =
            block.timestamp +
            g().getPolicyByIndex(policyIndex).voteDuration;
        p.info.totalManager = totalManager;
        p.info.totalVoter = 0;

        for (uint16 i = 0; i < totalManager; i++) {
            p.managers[i].addr = managers[i].addr;
            p.managers[i].controlWeight = managers[i].controlWeight;
        }
    }

    function voteManagerProposal(bool approve) public {
        ManagerProposal storage p = managerProposals[managerProposalId];

        require(
            managerProposalId > 0 &&
                managerProposals[managerProposalId].exists &&
                managerProposals[managerProposalId].info.openVote &&
                isMember(msg.sender) &&
                block.timestamp < p.info.closeVoteTimestamp,
            "44"
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

    function countVoteManagerProposal() public {
        ManagerProposal storage p = managerProposals[managerProposalId];
        bytes32 policyIndex = g().stringToBytes32("MANAGERS_LIST");

        require(
            managerProposalId > 0 &&
                p.exists &&
                p.info.openVote &&
                block.timestamp >= p.info.closeVoteTimestamp,
            "45"
        );

        p.info.openVote = false;
        p.info.totalVoteToken = 0;
        p.info.totalApproveToken = 0;
        p.info.totalSupplyToken = t().totalSupply();

        for (uint32 i = 0; i < p.info.totalVoter; i++) {
            uint256 voterToken = t().balanceOf(p.votersAddress[i]);
            p.info.totalVoteToken += voterToken;

            if (p.voters[p.votersAddress[i]].approve) {
                p.info.totalApproveToken += voterToken;
            }
        }

        bool isVoteValid = p.info.totalVoteToken >=
            (p.info.totalSupplyToken *
                g().getPolicyByIndex(policyIndex).minWeightValidVote) /
                g().getPolicyByIndex(policyIndex).maxWeight;

        bool isVoteApprove = p.info.totalApproveToken >=
            (p.info.totalVoteToken *
                g().getPolicyByIndex(policyIndex).minWeightApproveVote) /
                g().getPolicyByIndex(policyIndex).maxWeight;

        p.info.voteResult = isVoteValid && isVoteApprove;
        p.info.countVote = true;

        p.info.processResultTimestamp = block.timestamp;
    }

    function applyManagerProposal() public {
        ManagerProposal storage p = managerProposals[managerProposalId];
        bytes32 policyIndex = g().stringToBytes32("MANAGERS_LIST");

        require(
            p.info.countVote &&
                !p.info.applyProposal &&
                block.timestamp >=
                p.info.closeVoteTimestamp +
                    g().getPolicyByIndex(policyIndex).timelockDuration,
            "46"
        );

        if (p.info.voteResult) {
            for (uint16 i = 0; i < p.info.totalManager; i++) {
                g().setManagerAtIndexByProposal(
                    p.info.totalManager,
                    i,
                    p.managers[i].addr,
                    p.managers[i].controlWeight,
                    p.info.maxWeight
                );
            }
        }

        p.info.applyProposal = true;
    }

    function openAuditorProposal(address addr) public {
        bytes32 policyIndex = g().stringToBytes32("AUDITORS_LIST");

        require(
            (auditorProposalId == 0 ||
                !auditorProposals[auditorProposalId].info.openVote) &&
                isManager(msg.sender) &&
                isMember(addr) &&
                g().getManagerByAddress(msg.sender).controlWeight >=
                ((g().getManagerMaxControlWeight() *
                    g().getPolicyByIndex(policyIndex).minWeightOpenVote) /
                    g().getPolicyByIndex(policyIndex).maxWeight),
            "46"
        );

        auditorProposalId += 1;

        AuditorProposal storage p = auditorProposals[auditorProposalId];
        p.exists = true;
        p.info.openVote = true;
        p.info.voteValid = false;
        p.info.voteApprove = false;
        p.info.closeVoteTimestamp =
            block.timestamp +
            g().getPolicyByIndex(policyIndex).voteDuration;
        p.info.addr = addr;
        p.info.totalVoter = 0;
    }

    function voteAuditorProposal(bool approve) public {
        AuditorProposal storage p = auditorProposals[auditorProposalId];

        require(
            auditorProposalId > 0 &&
                auditorProposals[auditorProposalId].exists &&
                auditorProposals[auditorProposalId].info.openVote &&
                isManager(msg.sender) &&
                block.timestamp < p.info.closeVoteTimestamp,
            "47"
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

    function countVoteAuditorProposal() public {
        AuditorProposal storage p = auditorProposals[auditorProposalId];
        bytes32 policyIndex = g().stringToBytes32("AUDITORS_LIST");

        require(
            auditorProposalId > 0 &&
                p.exists &&
                p.info.openVote &&
                block.timestamp >= p.info.closeVoteTimestamp,
            "48"
        );

        p.info.openVote = false;
        p.info.totalVoteToken = 0;
        p.info.totalApproveToken = 0;
        p.info.totalSupplyToken = g().getManagerMaxControlWeight();

        for (uint32 i = 0; i < p.info.totalVoter; i++) {
            uint256 voterToken = g()
                .getManagerByAddress(p.votersAddress[i])
                .controlWeight;
            p.info.totalVoteToken += voterToken;

            if (p.voters[p.votersAddress[i]].approve) {
                p.info.totalApproveToken += voterToken;
            }
        }

        p.info.voteValid =
            p.info.totalVoteToken >=
            (p.info.totalSupplyToken *
                g().getPolicyByIndex(policyIndex).minWeightValidVote) /
                g().getPolicyByIndex(policyIndex).maxWeight;

        p.info.voteApprove =
            p.info.totalApproveToken >=
            (p.info.totalVoteToken *
                g().getPolicyByIndex(policyIndex).minWeightApproveVote) /
                g().getPolicyByIndex(policyIndex).maxWeight;

        p.info.countVote = true;
        p.info.processResultTimestamp = block.timestamp;
    }

    function applyAuditorProposal() public {
        AuditorProposal storage p = auditorProposals[auditorProposalId];
        bytes32 policyIndex = g().stringToBytes32("AUDITORS_LIST");

        require(
            p.info.countVote &&
                !p.info.applyProposal &&
                block.timestamp >=
                p.info.closeVoteTimestamp +
                    g().getPolicyByIndex(policyIndex).timelockDuration,
            "49"
        );

        if (p.info.voteValid) {
            g().setAuditorByProposal(p.info.addr, p.info.voteApprove);
        }
    }

    function openCustodianProposal(address addr) public {
        bytes32 policyIndex = g().stringToBytes32("CUSTODIANS_LIST");

        require(
            (custodianProposalId == 0 ||
                !custodianProposals[custodianProposalId].info.openVote) &&
                isManager(msg.sender) &&
                isMember(addr) &&
                g().getManagerByAddress(msg.sender).controlWeight >=
                ((g().managerMaxControlWeight() *
                    g().getPolicyByIndex(policyIndex).minWeightOpenVote) /
                    g().getPolicyByIndex(policyIndex).maxWeight),
            "49"
        );

        custodianProposalId += 1;

        CustodianProposal storage p = custodianProposals[custodianProposalId];
        p.exists = true;
        p.info.openVote = true;
        p.info.voteValid = false;
        p.info.voteApprove = false;
        p.info.closeVoteTimestamp =
            block.timestamp +
            g().getPolicyByIndex(policyIndex).voteDuration;
        p.info.addr = addr;
        p.info.totalVoter = 0;
    }

    function voteCustodianProposal(bool approve) public {
        CustodianProposal storage p = custodianProposals[custodianProposalId];

        require(
            custodianProposalId > 0 &&
                custodianProposals[custodianProposalId].exists &&
                custodianProposals[custodianProposalId].info.openVote &&
                isManager(msg.sender) &&
                block.timestamp < p.info.closeVoteTimestamp,
            "50"
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

    function countVoteCustodianProposal() public {
        CustodianProposal storage p = custodianProposals[custodianProposalId];
        bytes32 policyIndex = g().stringToBytes32("CUSTODIANS_LIST");

        require(
            custodianProposalId > 0 &&
                p.exists &&
                p.info.openVote &&
                block.timestamp >= p.info.closeVoteTimestamp,
            "51"
        );

        p.info.openVote = false;
        p.info.totalVoteToken = 0;
        p.info.totalApproveToken = 0;
        p.info.totalSupplyToken = g().getManagerMaxControlWeight();

        for (uint32 i = 0; i < p.info.totalVoter; i++) {
            uint256 voterToken = g()
                .getManagerByAddress(p.votersAddress[i])
                .controlWeight;
            p.info.totalVoteToken += voterToken;

            if (p.voters[p.votersAddress[i]].approve) {
                p.info.totalApproveToken += voterToken;
            }
        }

        p.info.voteValid =
            p.info.totalVoteToken >=
            (p.info.totalSupplyToken *
                g().getPolicyByIndex(policyIndex).minWeightOpenVote) /
                g().getPolicyByIndex(policyIndex).maxWeight;

        p.info.voteApprove =
            p.info.totalApproveToken >=
            (p.info.totalVoteToken *
                g().getPolicyByIndex(policyIndex).minWeightOpenVote) /
                g().getPolicyByIndex(policyIndex).maxWeight;

        p.info.countVote = true;
        p.info.processResultTimestamp = block.timestamp;
    }

    function applyCustodianProposal() public {
        CustodianProposal storage p = custodianProposals[custodianProposalId];
        bytes32 policyIndex = g().stringToBytes32("CUSTODIANS_LIST");

        require(
            p.info.countVote &&
                !p.info.applyProposal &&
                block.timestamp >=
                p.info.closeVoteTimestamp +
                    g().getPolicyByIndex(policyIndex).timelockDuration,
            "52"
        );

        if (p.info.voteValid) {
            g().setCustodianByProposal(p.info.addr, p.info.voteApprove);
        }
    }

    function getCurrentPolicyProposal(string memory policyName)
        public
        view
        returns (PolicyProposalInfo memory policyProposalInfo)
    {
        bytes32 policyIndex = g().stringToBytes32(policyName);
        return policyProposals[policyProposalIndexs[policyIndex].id].info;
    }

    function getCurrentManagerProposal()
        public
        view
        returns (ManagerProposalInfo memory managerProposalInfo)
    {
        return managerProposals[managerProposalId].info;
    }
}
