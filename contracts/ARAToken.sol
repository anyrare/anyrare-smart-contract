pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Member.sol";
import "./Governance.sol";
import "./CollateralToken.sol";
import "./converter/BancorFormula.sol";

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
    ) public ERC20(_name, _symbol) {
        governanceContract = _governanceContract;
        bancorFormulaContract = _bancorFormulaContract;
        collateralToken = _collateralToken;
        _mint(msg.sender, initialAmount);
    }

    function isValidMember(address account) public view returns (bool) {
        Governance g = Governance(governanceContract);
        Member m = Member(g.getMemberContract());
        return m.isValidMember(account);
    }

    function mint(uint256 amount) public payable {
        require(
            isValidMember(msg.sender),
            "Error 1000: Not a valid member so have no permission to mint new token."
        );

        Governance g = Governance(governanceContract);
        BancorFormula b = BancorFormula(bancorFormulaContract);
        CollateralToken c = CollateralToken(collateralToken);

        uint32 collateralWeight;
        (collateralWeight, , , , , ) = g.getPolicy("COLLATERAL_WEIGHT");

        uint256 mintAmounts = b.purchaseTargetAmount(
            this.totalSupply(),
            c.balanceOf(address(this)),
            collateralWeight,
            amount
        );

        require(
            c.balanceOf(msg.sender) >= amount,
            "Error 1001: Insufficient fund to mint."
        );

        c.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, mintAmounts);
    }

    function burn(uint256 amount) public payable {
        require(
            isValidMember(msg.sender),
            "Error 1002: Not a valid member so have no permission to withdraw."
        );
        require(
            this.balanceOf(msg.sender) >= amount,
            "Error 1003: Insufficient fund to burn."
        );

        Governance g = Governance(governanceContract);
        CollateralToken c = CollateralToken(collateralToken);
        BancorFormula b = BancorFormula(bancorFormulaContract);

        uint32 collateralWeight;
        (collateralWeight, , , , , ) = g.getPolicy("COLLATERAL_WEIGHT");

        uint256 withdrawAmounts = b.saleTargetAmount(
            this.totalSupply(),
            c.balanceOf(address(this)),
            collateralWeight,
            amount
        );

        require(
            c.balanceOf(address(this)) >= withdrawAmounts,
            "Error 1004: Insufficient collateral to withdraw."
        );
        _burn(msg.sender, amount);
        c.transfer(msg.sender, withdrawAmounts);
    }
}
