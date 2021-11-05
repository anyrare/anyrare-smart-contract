pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./converter/BancorFormula.sol";
import "hardhat/console.sol";

contract ARAToken is ERC20, BancorFormula {

  address public reserve;
  uint32 public reserveWeight;

  using SafeMath for uint256;

  constructor(
    string memory _name,
    string memory _symbol,
    uint32 _reserveRatio,
    address _reserve
  ) ERC20(_name, _symbol) public {
    reserve = _reserve;
    reserveWeight = _reserveRatio;
    _mint(msg.sender, 10 ** 10);
  }

  receive() external payable {
    mint(msg.value);
  }

  function mint(uint256 amount) public payable {
    uint256 mintAmounts = purchaseTargetAmount(
      this.totalSupply(),
      reserve.balance,
      reserveWeight,
      amount
    );

    uint256 increseTokensReserve = mintAmounts;
    uint256 increseTokensSender = mintAmounts;
    console.log("this.totalSupply %d", this.totalSupply());
    console.log("reserve.balance %d", reserve.balance);
    console.log("reserveWeight %d", reserveWeight);
    console.log("mintAmounts %d", mintAmounts);

    // _mint(msg.sender, increseTokensSender);
    // _mint(reserve, increseTokensReserve);
  }

  // function burn(uint256 numTokens) public {
  //   require(balances[msg.sender] >= numTokens);

  //   uint256 reserveTokenToReturn = rewardForBurn(numTokens);
  //   totalSupply_ = totalSupply_.sub(numTokens);
  //   balances[msg.sender] = balances[msg.sender].sub(numTokens);
  //   poolBalance = poolBalance.sub(reserveTokensToReturn);
  //   reserveToken.transfer(msg.sender, reserveTokenToReturn);

  //   emit Burned(numTokens, reserveTokensToReturn);
  // }
}