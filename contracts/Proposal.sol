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
        bytes8 policyIndex;
        uint32 id;
        bool openVote;
        bool exists;
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
        uint256 policyValue;
        uint8 decider;
        uint8 voteDecider;
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

    struct AuditorProposal {
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
        address addr;
        mapping(uint256 => address) votersAddress;
        mapping(address => Voter) voters;
    }

    struct CustodianProposal {
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
        address addr;
        mapping(uint256 => address) votersAddress;
        mapping(address => Voter) voters;
    }

    address governanceContract;
    uint32 policyProposalId;
    uint32 managerProposalId;
    uint32 auditorProposalId;
    uint32 custodianProposalId;

    mapping(bytes8 => PolicyProposalIndex) policyProposalIndexs;
    mapping(uint32 => PolicyProposal) policyProposals;
    mapping(uint32 => ManagerProposal) managerProposals;
    mapping(uint32 => AuditorProposal) auditorProposals;
    mapping(uint32 => CustodianProposal) custodianProposals;

    constructor(address _governanceContract) public {
        governanceContract = _governanceContract;
        policyProposalId = 0;
        managerProposalId = 0;
        auditorProposalId = 0;
        custodianProposalId = 0;
    }

    function isMember(address addr) public view returns (bool) {
        Governance g = Governance(governanceContract);
        Member m = Member(g.getMemberContract());
        return m.isMember(addr);
    }

    function isManager(address addr) public view returns (bool) {
        Governance g = Governance(governanceContract);
        return g.isManager(addr);
    }

    function openPolicyProposal(
        string memory policyName,
        uint32 policyWeight,
        uint32 maxWeight,
        uint32 voteDurationSecond,
        uint32 minWeightOpenVote,
        uint32 minWeightValidVote,
        uint32 minWeightApproveVote,
        uint256 policyValue,
        uint8 decider
    ) public {
        Governance g = Governance(governanceContract);
        bytes8 policyIndex = g.stringToBytes8(policyName);

        require(
            policyProposalIndexs[policyIndex].exists &&
                policyProposalIndexs[policyIndex].openVote,
            "Error 4000: Policy proposal address already exists."
        );
        require(
            isMember(msg.sender),
            "Error 4001: Invalid member no permission to open policy proposal."
        );

        ERC20 t = ERC20(g.getARATokenContract());

        require(
            t.balanceOf(msg.sender) >=
                (t.totalSupply() * g.getPolicy(policyName).minWeightOpenVote) /
                    g.getPolicy(policyName).maxWeight,
            "Error 4002: Insufficient token to open policy proposal."
        );

        policyProposalId += 1;

        PolicyProposalIndex storage pIndex = policyProposalIndexs[policyIndex];
        pIndex.policyIndex = policyIndex;
        pIndex.id = policyProposalId;
        pIndex.openVote = true;
        pIndex.exists = true;

        PolicyProposal storage p = policyProposals[policyProposalId];
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
        p.policyValue = policyValue;
        p.decider = decider;
        p.totalVoter = 0;
        p.voteDecider = g.getPolicyByIndex(policyIndex).exists
            ? g.getPolicyByIndex(policyIndex).decider
            : decider;
    }

    function votePolicyProposal(uint32 proposalId, bool approve) public {
        require(
            policyProposals[proposalId].exists &&
                policyProposals[proposalId].openVote,
            "Error 4003: Policy proposal is closed or did not exists."
        );

        PolicyProposal storage p = policyProposals[proposalId];

        require(
            p.voteDecider == 0 ? isMember(msg.sender) : isManager(msg.sender),
            "Error 4004: Invalid member no permission to vote policy proposal."
        );

        if (!p.voters[msg.sender].voted) {
            p.votersAddress[p.totalVoter] = msg.sender;
            p.totalVoter += 1;
            p.voters[msg.sender].voted = true;
            p.voters[msg.sender].approve = approve;
        } else {
            p.voters[msg.sender].approve = approve;
        }
    }

    function processPolicyProposal(uint32 proposalId) public {
        PolicyProposal storage p = policyProposals[proposalId];
        require(p.openVote, "Error 4005: Policy proposal was proceed.");

        p.openVote = false;
        Governance g = Governance(governanceContract);
        ERC20 t = ERC20(g.getARATokenContract());
        p.totalVoteToken = 0;
        p.totalApproveToken = 0;
        p.totalSupplyToken = p.voteDecider == 0
            ? t.totalSupply()
            : g.getManagerControlMaxWeight();

        for (uint256 i = 0; i < p.totalVoter; i++) {
            uint256 voterToken = p.voteDecider == 0
                ? t.balanceOf(p.votersAddress[i])
                : g.getManagerByAddress(p.votersAddress[i]).controlWeight;
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
                g.getPolicyByIndex(p.policyIndex).minWeightApproveVote) /
                g.getPolicyByIndex(p.policyIndex).maxWeight;

        p.voteResult = isVoteValid && isVoteApprove;

        if (isVoteValid && isVoteApprove) {
            g.setPolicyByProposal(
                p.policyIndex,
                proposalId,
                p.policyWeight,
                p.maxWeight,
                p.voteDurationSecond,
                p.minWeightOpenVote,
                p.minWeightValidVote,
                p.minWeightApproveVote,
                p.policyValue,
                p.decider
            );
        }

        p.processResultTimestamp = block.timestamp;
    }

    function openManagerProposal(
        uint16 totalManager,
        ManagerInfo[] memory managers
    ) public {
        require(
            managerProposalId == 0 ||
                !managerProposals[managerProposalId].openVote,
            "Error 4006: Manager proposal address already exists."
        );
        require(
            isMember(msg.sender),
            "Error 4007: Invalid member no permission to open manager proposal."
        );

        for (uint16 i = 0; i < totalManager; i++) {
            require(
                isMember(managers[i].addr),
                "Error 4008: Invalid member cannot add to manager list."
            );
        }

        managerProposalId += 1;
        Governance g = Governance(governanceContract);
        ERC20 t = ERC20(g.getARATokenContract());
        bytes8 policyIndex = g.stringToBytes8("MANAGERS_LIST");

        require(
            t.balanceOf(msg.sender) >=
                (t.totalSupply() *
                    g.getPolicyByIndex(policyIndex).minWeightOpenVote) /
                    g.getPolicyByIndex(policyIndex).maxWeight,
            "Error 4009: Insufficient token to open manager proposal."
        );

        ManagerProposal storage p = managerProposals[managerProposalId];
        p.policyIndex = policyIndex;
        p.exists = true;
        p.openVote = true;
        p.closeVoteTimestamp =
            block.timestamp +
            g.getPolicyByIndex(policyIndex).voteDurationSecond;
        p.totalManager = totalManager;
        p.totalVoter = 0;

        for (uint16 i = 0; i < totalManager; i++) {
            p.managers[i].addr = managers[i].addr;
            p.managers[i].controlWeight = managers[i].controlWeight;
            p.managers[i].maxWeight = managers[i].maxWeight;
        }
    }

    function voteManagerProposal(bool approve) public {
        require(
            managerProposalId > 0 &&
                managerProposals[managerProposalId].exists &&
                managerProposals[managerProposalId].openVote,
            "Error 4009: Manager proposal is closed or did not exists."
        );

        require(
            isMember(msg.sender),
            "Error 4010: Invalid member no permission to vote manager proposal."
        );

        ManagerProposal storage p = managerProposals[managerProposalId];

        if (!p.voters[msg.sender].voted) {
            p.votersAddress[p.totalVoter] = msg.sender;
            p.totalVoter += 1;
            p.voters[msg.sender].voted = true;
            p.voters[msg.sender].approve = approve;
        } else {
            p.voters[msg.sender].approve = approve;
        }
    }

    function processManagerProposal() public {
        require(
            managerProposalId > 0 &&
                managerProposals[managerProposalId].exists &&
                managerProposals[managerProposalId].openVote,
            "Error 4011: Manager proposal was proceed."
        );
        ManagerProposal storage p = managerProposals[managerProposalId];

        p.openVote = false;
        Governance g = Governance(governanceContract);
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
                g.getPolicyByIndex(p.policyIndex).minWeightApproveVote) /
                g.getPolicyByIndex(p.policyIndex).maxWeight;

        p.voteResult = isVoteValid && isVoteApprove;

        if (isVoteValid && isVoteApprove) {
            for (uint16 i = 0; i < p.totalManager; i++) {
                g.setManagerAtIndexByProposal(
                    p.totalManager,
                    i,
                    p.managers[i].addr,
                    p.managers[i].controlWeight,
                    p.managers[i].maxWeight
                );
            }
        }

        p.processResultTimestamp = block.timestamp;
    }

    function openAuditorProposal(address auditorAddr) public {
        require(
            auditorProposalId == 0 ||
                !auditorProposals[auditorProposalId].openVote,
            "Error 4012: Auditor proposal address already exists."
        );
        require(
            isMember(msg.sender),
            "Error 4013: Invalid member have no permission to open auditor proposal."
        );
        require(
            isMember(auditorAddr),
            "Error 4014: Invalid member cannot add to auditor list."
        );

        auditorProposalId += 1;
        Governance g = Governance(governanceContract);
        ERC20 t = ERC20(g.getARATokenContract());
        bytes8 policyIndex = g.stringToBytes8("AUDITORS_LIST");

        require(
            t.balanceOf(msg.sender) >=
                (t.totalSupply() *
                    g.getPolicyByIndex(policyIndex).minWeightOpenVote) /
                    g.getPolicyByIndex(policyIndex).maxWeight,
            "Error 4015: Insufficient token to open auditor proposal."
        );

        AuditorProposal storage p = auditorProposals[auditorProposalId];
        p.policyIndex = policyIndex;
        p.exists = true;
        p.openVote = true;
        p.closeVoteTimestamp =
            block.timestamp +
            g.getPolicyByIndex(policyIndex).voteDurationSecond;
        p.addr = auditorAddr;
        p.totalVoter = 0;
    }

    function voteAuditorProposal(bool approve) public {
        require(
            auditorProposalId > 0 &&
                auditorProposals[auditorProposalId].exists &&
                auditorProposals[auditorProposalId].openVote,
            "Error 4016: Auditor proposal is closed or did not exists."
        );

        require(
            isMember(msg.sender),
            "Error 4017: Invalid member cannot vote auditor proposal list."
        );

        AuditorProposal storage p = auditorProposals[auditorProposalId];

        if (!p.voters[msg.sender].voted) {
            p.votersAddress[p.totalVoter] = msg.sender;
            p.totalVoter += 1;
            p.voters[msg.sender].voted = true;
            p.voters[msg.sender].approve = approve;
        } else {
            p.voters[msg.sender].approve = approve;
        }
    }

    function processAuditorProposal() public {
        require(
            auditorProposalId > 0 &&
                auditorProposals[auditorProposalId].exists &&
                auditorProposals[auditorProposalId].openVote,
            "Error 4018: Auditor proposal was proceed."
        );
        AuditorProposal storage p = auditorProposals[auditorProposalId];

        p.openVote = false;
        Governance g = Governance(governanceContract);
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
                g.getPolicyByIndex(p.policyIndex).minWeightApproveVote) /
                g.getPolicyByIndex(p.policyIndex).maxWeight;

        p.voteResult = isVoteValid && isVoteApprove;

        if (isVoteValid) {
            g.setAuditorByProposal(p.addr, isVoteApprove);
        }

        p.processResultTimestamp = block.timestamp;
    }

    function openCustodianProposal(address custodianAddr) public {
        require(
            custodianProposalId == 0 ||
                !custodianProposals[custodianProposalId].openVote,
            "Error 4019: Custodian proposal address already exists."
        );

        require(
            isMember(msg.sender),
            "Error 4020: Invalid member no permission to open custodian proposal."
        );

        require(
            isMember(custodianAddr),
            "Error 4021: Invalid member cannot add to custodianslist."
        );

        custodianProposalId += 1;
        Governance g = Governance(governanceContract);
        ERC20 t = ERC20(g.getARATokenContract());
        bytes8 policyIndex = g.stringToBytes8("CUSTODIANS_LIST");

        require(
            t.balanceOf(msg.sender) >=
                (t.totalSupply() *
                    g.getPolicyByIndex(policyIndex).minWeightOpenVote) /
                    g.getPolicyByIndex(policyIndex).maxWeight,
            "Error 4022: Insufficient token to open custodian proposal."
        );

        CustodianProposal storage p = custodianProposals[custodianProposalId];
        p.policyIndex = policyIndex;
        p.exists = true;
        p.openVote = true;
        p.closeVoteTimestamp =
            block.timestamp +
            g.getPolicyByIndex(policyIndex).voteDurationSecond;
        p.addr = custodianAddr;
        p.totalVoter = 0;
    }

    function voteCustodianProposal(bool approve) public {
        require(
            custodianProposalId > 0 &&
                custodianProposals[custodianProposalId].exists &&
                custodianProposals[custodianProposalId].openVote,
            "Error 4023: Custodian proposal is closed or did not exists."
        );

        require(
            isMember(msg.sender),
            "Error 4024: Invalid member no permission to vote custodian proposal."
        );

        CustodianProposal storage p = custodianProposals[custodianProposalId];

        if (!p.voters[msg.sender].voted) {
            p.votersAddress[p.totalVoter] = msg.sender;
            p.totalVoter += 1;
            p.voters[msg.sender].voted = true;
            p.voters[msg.sender].approve = approve;
        } else {
            p.voters[msg.sender].approve = approve;
        }
    }

    function processCustodianProposal(uint32 proposalId) public {
        require(
            custodianProposalId > 0 &&
                custodianProposals[custodianProposalId].exists &&
                custodianProposals[custodianProposalId].openVote,
            "Error 4015: Auditor proposal was proceed."
        );
        CustodianProposal storage p = custodianProposals[custodianProposalId];

        p.openVote = false;
        Governance g = Governance(governanceContract);
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

        if (isVoteValid) {
            g.setCustodianByProposal(p.addr, isVoteApprove);
        }

        p.processResultTimestamp = block.timestamp;
    }
}
