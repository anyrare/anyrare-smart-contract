pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Member.sol";
import "./Governance.sol";
import "./CollateralToken.sol";
import "./converter/BancorFormula.sol";
import "./Governance.sol";

contract ARAToken is ERC20 {
    address public governanceContract;
    address public bancorFormulaContract;
    address public collateralToken;

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

    function isMember(address account) public view returns (bool) {
        Governance g = Governance(governanceContract);
        Member m = Member(g.getMemberContract());
        return m.isMember(account);
    }

    function mint(uint256 amount) public payable {
        require(
            isMember(msg.sender),
            "Error 1000: Invalid member no permission to mint new token."
        );

        Governance g = Governance(governanceContract);
        BancorFormula b = BancorFormula(bancorFormulaContract);
        CollateralToken c = CollateralToken(collateralToken);

        uint256 mintAmounts = b.purchaseTargetAmount(
            this.totalSupply(),
            c.balanceOf(address(this)),
            g.getPolicy("ARA_COLLATERAL_WEIGHT").policyWeight,
            amount
        );

        require(
            c.balanceOf(msg.sender) >= amount && amount > 0,
            "Error 1001: Insufficient fund to mint."
        );

        c.transferFrom(msg.sender, address(this), amount);

        uint256 managementFund = (mintAmounts *
            g.getPolicy("ARA_MINT_MANAGEMENT_FUND_WEIGHT").policyWeight) /
            g.getPolicy("ARA_MINT_MANAGEMENT_FUND_WEIGHT").maxWeight;

        if (managementFund > 0) {
            _mint(g.getManagementFundContract(), managementFund);
        }

        if (mintAmounts - managementFund > 0) {
            _mint(msg.sender, mintAmounts - managementFund);
        }
    }

    function burn(uint256 amount) public payable {
        require(
            isMember(msg.sender),
            "Error 1002: Invalid member no permission to withdraw."
        );

        require(
            this.balanceOf(msg.sender) >= amount && amount > 0,
            "Error 1003: Insufficient fund to burn."
        );

        Governance g = Governance(governanceContract);
        CollateralToken c = CollateralToken(collateralToken);
        BancorFormula b = BancorFormula(bancorFormulaContract);

        uint256 withdrawAmounts = b.saleTargetAmount(
            this.totalSupply(),
            c.balanceOf(address(this)),
            g.getPolicy("ARA_COLLATERAL_WEIGHT").policyWeight,
            amount
        );

        require(
            c.balanceOf(address(this)) >= withdrawAmounts,
            "Error 1004: Insufficient collateral to withdraw."
        );

        _burn(msg.sender, amount);

        if (withdrawAmounts > 0) {
            c.transfer(msg.sender, withdrawAmounts);
        }
    }
}
