pragma solidity ^0.8.0;

contract Member {
    struct MemberInfo {
        address referral;
    }

    mapping(address => MemberInfo) public members;

    constructor(address root) public {
        MemberInfo storage m = members[root];
        m.referral = root;
    }

    function setMember(address account, address referral) public {
        if (members[referral].referral != address(0)) {
            MemberInfo storage m = members[account];
            m.referral = referral;
        }
    }
}
