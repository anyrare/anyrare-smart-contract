pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./ARAToken.sol";
import "./BancorFormula.sol";
import "./Member.sol";
import "./Governance.sol";

contract Utils {
    address private governanceContract;

    function g() internal returns (Governance) {
        return Governance(governanceContract);
    }

    function m() internal returns (Member) {
        return Member(g().getMemberContract());
    }

    function t() internal returns (ERC20) {
        return ERC20(g().getARATokenContract());
    }

    function b() internal returns (BancorFormula) {
        return BancorFormula(g().getBancorFormulaContract());
    }

    function n() internal returns (ERC721) {
        return ERC721(g().getNFTFactoryContract());
    }

    function isMember(address addr) internal returns (bool) {
        return m().isMember(addr);
    }

    function isAuditor(address addr) internal returns (bool) {
        return g().isAuditor(addr);
    }

    function isCustodian(address addr) internal returns (bool) {
        return g().isCustodian(addr);
    }

    function isManager(address addr) internal returns (bool) {
        return g().isManager(addr);
    }

    function getReferral(address addr) internal returns (address) {
        return m().getReferral(addr);
    }

    function maybeTransferNFT(
        address sender,
        address receiver,
        uint256 tokenId
    ) internal {
        require(n().ownerOf(tokenId) == sender, "33");
    }

    function maybeTransferARA(
        address sender,
        address receiver,
        uint256 value
    ) internal {
        require(t().balanceOf(sender) >= value, "31");

        if (value > 0) {
            t().transferFrom(sender, receiver, value);
        }
    }

    function calculateFeeFromPolicy(uint256 value, string memory policyName)
        internal
        returns (uint256)
    {
        return
            (value * g().getPolicy(policyName).policyWeight) /
            g().getPolicy(policyName).maxWeight;
    }

    function getManagementFundContract() internal returns (address) {
        return g().getManagementFundContract();
    }

    function max(uint256 x, uint256 y) internal view returns (uint256) {
        return x > y ? x : y;
    }

    function min(uint256 x, uint256 y) internal view returns (uint256) {
        return x < y ? x : y;
    }
}
