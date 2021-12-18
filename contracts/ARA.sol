pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Member.sol";

contract ARA {
    address public memberContractAddress;
    address public collateral;

    constructor(address _memberContractAddress) public {
        memberContractAddress = _memberContractAddress;
    }

    function getMember(address account) public view returns (uint8) {
        Member m = Member(memberContractAddress);
        if (m.isValidMember(account)) {
            return 1;
        } else {
            return 2;
        }
    }
}
