pragma solidity ^0.8.0;

contract Member {
    struct MemberInfo {
        address referral;
    }

    mapping(address => MemberInfo) public members;

    constructor(address root) {
        MemberInfo storage m = members[root];
        m.referral = root;
    }

    function setMember(address addr, address referral) public {
        require(
            msg.sender == addr &&
            members[addr].referral == address(0) &&
            members[referral].referral != address(0)
        );
        MemberInfo storage m = members[addr];
        m.referral = referral;
    }

    function isMember(address addr) public view returns (bool) {
        return members[addr].referral != address(0);
    }

    function getReferral(address addr) public view returns (address) {
        return members[addr].referral;
    }
}
