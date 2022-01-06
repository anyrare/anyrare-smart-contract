pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ARAToken.sol";
import "./Member.sol";
import "./Governance.sol";

contract Utils {
    function g() internal returns (Governance) {
        return Governance(governanceContract);
    }

    function m() internal returns (Member) {
        return Member(g().getMemberContract());
    }

    function t() internal returns (ERC20) {
        return ERC20(g().getARATokenContract());
    }

    function b() private view returns (BancorFormula) {
        return BancorFormula(bancorFormulaContract);
    }

    function n() interal returns (ERC721) {
        return ERC721(g().getNFTFactoryContract());
    }

    function isMember(address account) internal view returns (bool) {
        return m().isMember(account);
    }

    function isAuditor(address account) internal view returns (bool) {
        return g().isAuditor(account);
    }

    function isCustodian(address account) internal view returns (bool) {
        return g().isCustodian(account);
    }

    function getReferral(address account) internal view returns (address) {
        return m().getReferral(account);
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

    function calculateFeeFromPolicy(string memory policyName, uint256 value)
        internal
        returns (uint256)
    {
        return
            (value * g().getPolicy(policyName).policyWeight) /
            g().getPolicy(policyName).maxWeight;
    }

    function getManagementFundContract() internal view returns (address) {
        return g().getManagementFundContract();
    }

    function max(uint256 x, uint256 y) internal view returns (uint256) {
        return x > y ? x : y;
    }

    function min(uint256 x, uint256 y) internal view returns (uint256) {
        return x < y ? x : y;
    }
}
