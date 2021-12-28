pragma solidity ^0.8.0;

contract Member {
    struct Member {
        address referral;
    }

    mapping(address => Member) public members;

    constructor(address root) public {
        Member storage m = members[root];
        m.referral = root;
    }

    function setMember(address account, address referral) public {
        require(
            members[referral].referral != address(0),
            "Error 3100: Failed to set member, referral not found"
        );
        Member storage m = members[account];
        m.referral = referral;
    }

    function isMember(address account) public view returns (bool) {
        return members[account].referral != address(0);
    }
}
