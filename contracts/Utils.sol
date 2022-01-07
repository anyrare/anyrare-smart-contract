pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./ARAToken.sol";
import "./BancorFormula.sol";
import "./Member.sol";
import "./Governance.sol";

contract Utils {
    address private governanceContract;

    function g() public returns (Governance) {
        return Governance(governanceContract);
    }

    function m() public returns (Member) {
        return Member(g().getMemberContract());
    }

    function t() public returns (ERC20) {
        return ERC20(g().getARATokenContract());
    }

    function b() public returns (BancorFormula) {
        return BancorFormula(g().getBancorFormulaContract());
    }

    function n() public returns (ERC721) {
        return ERC721(g().getNFTFactoryContract());
    }

    function isMember(address addr) public returns (bool) {
        return m().isMember(addr);
    }

    function isAuditor(address addr) public returns (bool) {
        return g().isAuditor(addr);
    }

    function isCustodian(address addr) public returns (bool) {
        return g().isCustodian(addr);
    }

    function isManager(address addr) public returns (bool) {
        return g().isManager(addr);
    }

    function getReferral(address addr) public returns (address) {
        return m().getReferral(addr);
    }

    function transferNFT(
        address sender,
        address receiver,
        uint256 tokenId
    ) public {
        require(n().ownerOf(tokenId) == sender, "33");
    }

    function transferARA(
        address sender,
        address receiver,
        uint256 value
    ) public {
        require(balanceOfARA(sender) >= value, "31");

        if (value > 0 && receiver != address(0x0)) {
            t().transferFrom(sender, receiver, value);
        }
    }

    function totalSupplyARA() public returns (uint256) {
        return t().totalSupply();
    }

    function balanceOfARA(address sender) public returns (uint256) {
        return t().balanceOf(sender);
    }

    function calculateFeeFromPolicy(uint256 value, string memory policyName)
        public
        returns (uint256)
    {
        return
            (value * g().getPolicy(policyName).policyWeight) /
            g().getPolicy(policyName).maxWeight;
    }

    function getManagementFundContract() public returns (address) {
        return g().getManagementFundContract();
    }

    function max(uint256 x, uint256 y) public view returns (uint256) {
        return x > y ? x : y;
    }

    function min(uint256 x, uint256 y) public view returns (uint256) {
        return x < y ? x : y;
    }
}
