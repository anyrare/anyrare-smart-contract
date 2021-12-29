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

    function setMember(address account, address referral) public {
        require(
            members[referral].referral != address(0),
            "Error 3100: Failed to set member, referral not found"
        );
        MemberInfo storage m = members[account];
        m.referral = referral;
    }

    function isMember(address account) public view returns (bool) {
        return members[account].referral != address(0);
    }
}
