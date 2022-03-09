// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {AppStorage} from "../libraries/LibAppStorage.sol";
import "../libraries/LibData.sol";
import "../interfaces/IMember.sol";
import "hardhat/console.sol";

contract DataFacet {
    AppStorage internal s;

    function isMember(address addr) external view returns (bool) {
        return LibData.isMember(s, addr);
    }

    function getReferral(address addr) external view returns (address) {
        return LibData.getReferral(s, addr);
    }

    function getAddressByUsername(string memory username)
        external
        view
        returns (address)
    {
        return LibData.getAddressByUsername(s, username);
    }

    function getMember(address addr)
        external
        view
        returns (IMember.MemberInfo memory m)
    {
        return LibData.getMember(s, addr);
    }

    function getFounder(uint16 index)
        public
        view
        returns (GovernanceFounder memory founder)
    {
        return LibData.getFounder(s, index);
    }

    function getFounderByAddress(address addr)
        public
        view
        returns (GovernanceFounder memory founder)
    {
        return LibData.getFounderByAddress(s, addr);
    }

    function getTotalFounder() public view returns (uint16) {
        return LibData.getTotalFounder(s);
    }

    function getFounderMaxControlWeight() public view returns (uint256) {
        return LibData.getFounderMaxControlWeight(s);
    }

    function getManager(uint16 index)
        public
        view
        returns (GovernanceManager memory manager)
    {
        return LibData.getManager(s, index);
    }

    function getManagerByAddress(address addr)
        public
        view
        returns (GovernanceManager memory manager)
    {
        return LibData.getManagerByAddress(s, addr);
    }

    function getTotalManager() public view returns (uint16) {
        return LibData.getTotalManager(s);
    }

    function getManagerMaxControlWeight() public view returns (uint256) {
        return LibData.getManagerMaxControlWeight(s);
    }

    function getOperation(uint16 index)
        public
        view
        returns (GovernanceOperation memory operation)
    {
        return LibData.getOperation(s, index);
    }

    function getOperationByAddress(address addr)
        public
        view
        returns (GovernanceOperation memory operation)
    {
        return LibData.getOperationByAddress(s, addr);
    }

    function getTotalOperation() public view returns (uint16) {
        return LibData.getTotalOperation(s);
    }

    function getOperationMaxControlWeight() public view returns (uint256) {
        return LibData.getOperationMaxControlWeight(s);
    }

    function getPolicy(string memory policyName)
        public
        view
        returns (GovernancePolicy memory policy)
    {
        return LibData.getPolicy(s, policyName);
    }

    function getPolicyByIndex(bytes32 policyIndex)
        public
        view
        returns (GovernancePolicy memory policy)
    {
        return LibData.getPolicyByIndex(s, policyIndex);
    }

    function isManager(address addr) public view returns (bool) {
        return LibData.isManager(s, addr);
    }

    function isOperation(address addr) public view returns (bool) {
        return LibData.isOperation(s, addr);
    }

    function isAuditor(address addr) public view returns (bool) {
        return LibData.isAuditor(s, addr);
    }

    function isCustodian(address addr) public view returns (bool) {
        return LibData.isCustodian(s, addr);
    }

    function getTotalCollection() external view returns (uint256) {
        return LibData.getTotalCollection(s);
    }

    function isValidCollection(address addr) external view returns (bool) {
        return LibData.isValidCollection(s, addr);
    }

    function getManagementFundValue() external view returns (uint256) {
        return LibData.getManagementFundValue(s);
    }
}
