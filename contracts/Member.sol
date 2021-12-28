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
        if (members[referral].referral != address(0)) {
            Member storage m = members[account];
            m.referral = referral;
        } else {
            revert();
        }
    }

    function isValidMember(address account) public view returns (bool) {
        return members[account].referral != address(0);
    }
}
