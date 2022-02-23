pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";
import {LibBancorFormula} from "../libraries/LibBancorFormula.sol";
import {LibACL} from "../libraries/LibACL.sol";
import {LibGovernance} from "../libraries/LibGovernance.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibUtils} from "../libraries/LibUtils.sol";
import "hardhat/console.sol";

contract ARATokenFacet is ERC20 {
    AppStorage internal s;

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}

    function _collateralBalanceOf(address addr) private returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        (address facetAddress, bytes4 functionSelector) = LibUtils
            .facetAddressAndFunctionSelector(
                ds,
                "collateralTokenBalanceOf(address)"
            );

        uint256 collateralBalance = LibUtils.bytesToUint256(
            LibUtils.delegateCallFunc(
                ds,
                facetAddress,
                abi.encodeWithSelector(functionSelector, addr)
            )
        );

        return collateralBalance;
    }

    function araTokenInitialize(address _collateralToken, uint256 initialAmount)
        external
    {
        require(
            s.araToken.collateralToken == address(0),
            "ARATokenFacet: Failed to initialize"
        );

        s.araToken.collateralToken = _collateralToken;
        _mint(msg.sender, initialAmount);
    }

    function araTokenMint(uint256 amount) public returns (uint256) {
        console.log(msg.sender);
        console.log("isMember", LibACL.isMember(s, msg.sender));
        console.log(s.member.totalMember);
        console.log("collateralToken", s.collateralToken.owner);
        require(
                LibACL.isMember(s, msg.sender),
            // &&
        //         _collateralBalanceOf(address(this)) >= amount &&
        //         amount > 0,
            "ARATokenFacet: Failed to mint"
        );

        uint256 mintAmounts = LibBancorFormula.purchaseTargetAmount(
            totalSupply(),
            _collateralBalanceOf(address(this)),
            uint32(
                LibGovernance.getPolicy(s, "ARA_COLLATERAL_WEIGHT").policyWeight
            ),
            amount
        );

        return amount;

        // console.log(mintAmounts);
    }

    //     c().transferFrom(msg.sender, address(this), amount);

    //     uint256 managementFund = (mintAmounts *
    //         LibGovernance
    //             .getPolicy("ARA_MINT_MANAGEMENT_FUND_WEIGHT")
    //             .policyWeight) /
    //         LibGovernance
    //             .getPolicy("ARA_MINT_MANAGEMENT_FUND_WEIGHT")
    //             .maxWeight;

    //     if (managementFund > 0) {
    //         _mint(
    //             LibGovernance.getManagementFundContract(),
    //             managementFund
    //         );
    //         s.governance.managementFundValue += managementFund;
    //     }

    //     if (mintAmounts - managementFund > 0) {
    //         _mint(msg.sender, mintAmounts - managementFund);
    //     }
    // }
}
