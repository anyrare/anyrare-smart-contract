pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Member.sol";
import "./Governance.sol";
import "./CollateralToken.sol";
import "./BancorFormula.sol";

contract ARAToken is ERC20 {
    address private governanceContract;
    address private bancorFormulaContract;
    address private collateralToken;

    constructor(
        address _governanceContract,
        address _bancorFormulaContract,
        string memory _name,
        string memory _symbol,
        address _collateralToken,
        uint256 initialAmount
    ) ERC20(_name, _symbol) {
        governanceContract = _governanceContract;
        bancorFormulaContract = _bancorFormulaContract;
        collateralToken = _collateralToken;
        _mint(msg.sender, initialAmount);
    }

    function g() private view returns (Governance) {
        return Governance(governanceContract);
    }

    function m() private view returns (Member) {
        return Member(g().getMemberContract());
    }

    function b() private view returns (BancorFormula) {
        return BancorFormula(bancorFormulaContract);
    }

    function c() private view returns (CollateralToken) {
        return CollateralToken(collateralToken);
    }

    function isMember(address account) private view returns (bool) {
        return m().isMember(account);
    }

    function mint(uint256 amount) public payable {
        require(
            isMember(msg.sender) &&
                c().balanceOf(msg.sender) >= amount &&
                amount > 0,
            "10"
        );

        uint256 mintAmounts = b().purchaseTargetAmount(
            totalSupply(),
            c().balanceOf(address(this)),
            uint32(g().getPolicy("ARA_COLLATERAL_WEIGHT").policyWeight),
            amount
        );

        c().transferFrom(msg.sender, address(this), amount);

        uint256 managementFund = (mintAmounts *
            g().getPolicy("ARA_MINT_MANAGEMENT_FUND_WEIGHT").policyWeight) /
            g().getPolicy("ARA_MINT_MANAGEMENT_FUND_WEIGHT").maxWeight;

        if (managementFund > 0) {
            _mint(g().getManagementFundContract(), managementFund);
        }

        if (mintAmounts - managementFund > 0) {
            _mint(msg.sender, mintAmounts - managementFund);
        }
    }

    function withdraw(uint256 amount) public payable {
        uint256 withdrawAmounts = b().saleTargetAmount(
            totalSupply(),
            c().balanceOf(address(this)),
            uint32(g().getPolicy("ARA_COLLATERAL_WEIGHT").policyWeight),
            amount
        );

        require(
            isMember(msg.sender) &&
                balanceOf(msg.sender) >= amount &&
                amount > 0 &&
                c().balanceOf(address(this)) >= withdrawAmounts,
            "11"
        );

        _burn(msg.sender, amount);

        if (withdrawAmounts > 0) {
            c().transfer(msg.sender, withdrawAmounts);
        }
    }

    function burn(uint256 amount) public payable {
        require(
            isMember(msg.sender) &&
                balanceOf(msg.sender) >= amount &&
                amount > 0,
            "12"
        );

        _burn(msg.sender, amount);
    }

    // f(C) -> targetARA
    function calculatePurchaseReturn(uint256 amount)
        public
        view
        returns (uint256)
    {
        uint256 mintAmounts = b().purchaseTargetAmount(
            totalSupply(),
            c().balanceOf(address(this)),
            uint32(g().getPolicy("ARA_COLLATERAL_WEIGHT").policyWeight),
            amount
        );

        uint256 managementFund = (mintAmounts *
            g().getPolicy("ARA_MINT_MANAGEMENT_FUND_WEIGHT").policyWeight) /
            g().getPolicy("ARA_MINT_MANAGEMENT_FUND_WEIGHT").maxWeight;

        return mintAmounts - managementFund;
    }

    // f(ARA) -> targetC
    function calculateSaleReturn(uint256 amount) public view returns (uint256) {
        return
            b().saleTargetAmount(
                totalSupply(),
                c().balanceOf(address(this)),
                uint32(g().getPolicy("ARA_COLLATERAL_WEIGHT").policyWeight),
                amount
            );
    }

    // f(targetARA) -> C
    function calculateFundCost(uint256 amount) public view returns (uint256) {
        uint256 adjAmount = (amount *
            g().getPolicy("ARA_MINT_MANAGEMENT_FUND_WEIGHT").maxWeight) /
            g().getPolicy("ARA_MINT_MANAGMENT_FUND_WEIGHT").policyWeight;

        return
            b().fundCost(
                totalSupply(),
                c().balanceOf(address(this)),
                uint32(g().getPolicy("ARA_COLLATERAL_WEIGHT").policyWeight),
                adjAmount
            );
    }

    // f(targetDAI) -> ARA
    function calculateLiquidateCost(uint256 amount)
        public
        view
        returns (uint256)
    {
        return
            b().liquidateCost(
                totalSupply(),
                c().balanceOf(address(this)),
                uint32(g().getPolicy("ARA_COLLATERAL_WEIGHT").policyWeight),
                amount
            );
    }

    function currentPrice() public view returns (uint256) {
        return
            c().totalSupply() /
            ((totalSupply() *
                g().getPolicy("ARA_COLLATERAL_WEIGHT").policyWeight) / 1000000);
    }

    function currentTotalValue() public view returns (uint256) {
        return
            (c().totalSupply() * 1000000) /
            g().getPolicy("ARA_COLLATERAL_WEIGHT").policyWeight;
    }
}
