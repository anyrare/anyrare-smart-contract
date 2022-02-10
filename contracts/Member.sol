pragma solidity ^0.8.0;
pragma abicoder v2;

contract Member {
    struct MemberInfo {
        address referral;
        string username;
        string thumbnail;
    }

    mapping(address => MemberInfo) public members;
    mapping(bytes32 => address) public usernames;

    constructor(address root) {
        MemberInfo storage m = members[root];
        m.referral = root;
        m.username = "root";
        usernames[stringToBytes32("root")] = root;
    }

    function stringToBytes32(string memory str) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(str));
    }

    function setMember(
        address addr,
        address referral,
        string memory username,
        string memory thumbnail
    ) public {
        require(
            msg.sender == addr &&
                members[addr].referral == address(0) &&
                members[referral].referral != address(0) &&
                usernames[stringToBytes32(username)] == address(0)
        );
        MemberInfo storage m = members[addr];
        m.referral = referral;
        m.username = username;
        m.thumbnail = thumbnail;

        usernames[stringToBytes32(username)] = addr;
    }

    function updateMember(
        address addr,
        string memory username,
        string memory thumbnail
    ) public {
        require(
            msg.sender == addr &&
                (usernames[stringToBytes32(username)] == address(0) ||
                    usernames[stringToBytes32(username)] == addr)
        );

        MemberInfo storage m = members[addr];
        m.thumbnail = thumbnail;

        if (stringToBytes32(m.username) != stringToBytes32(username)) {
            usernames[stringToBytes32(m.username)] = address(0);
            usernames[stringToBytes32(username)] = addr;
            m.username = username;
        }
    }

    function isMember(address addr) public view returns (bool) {
        return members[addr].referral != address(0);
    }

    function getReferral(address addr) public view returns (address) {
        return members[addr].referral;
    }

    function getAddressByUsername(string memory username) public view returns (address) {
        return usernames[stringToBytes32(username)];
    }
}
