pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Member.sol";
import "./Governance.sol";
import "./converter/BancorFormula.sol";
import "hardhat/console.sol";

contract ARA is ERC20 {
  address public governanceContract;
  address public bancorFormulaContract;
  address public collateral;

  constructor(
    address _governanceContract,
    address _bancorFormulaContract,
    string memory _name,
    string memory _symbol,
    address _collateral
  ) ERC20(_name, _symbol) public {
    governanceContract = _governanceContract;
    bancorFormulaContract = _bancorFormulaContract;
    collateral = _collateral;
  }

  receive() external payable {
    if (!isValidMember(msg.sender)) {
      revert();
    } else {
      mint(msg.value);
    }
  }

  function mint(uint256 amount) public payable {
    Governance g = Governance(governanceContract);
    BancorFormula b = BancorFormula(bancorFormulaContract);

    uint256 mintAmounts = b.purchaseTargetAmount(
      this.totalSupply(),
      collateral.balance,
      g.getCollateralWeight(),
      amount
    );

    console.log("mintAmounts %d", mintAmounts);
  }


  function isValidMember(address account) public view returns (bool) {
    Governance g = Governance(governanceContract);
    Member m = Member(g.getMemberContract());
    return m.isValidMember(account);
  }
}
