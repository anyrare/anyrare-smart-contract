pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "hardhat/console.sol";

contract BondingCurvedToken is ERC20 {

  address public collateral;
  uint256 public poolBalance;

  using SafeMath for uint256;

  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals,
    address payable _collateral
  ) ERC20(name, symbol) public {
    collateral = _collateral;
    _mint(msg.sender, 10);
  }

  function priceToMint(uint256 collateralValue) public returns(uint256)  {
    return collateralValue;
  }
  
  // function rewardForBurn(uint256 numTokens) public returns(uint256);

  receive() external payable {
    console.log("receive eth %d", msg.value);
    mint(msg.value);
  }

  function mint(uint256 collateralValue) public payable {
    uint256 increaseTokens = priceToMint(collateralValue);
    console.log("wei for msg.sender %d", msg.sender.balance);
    console.log("wei for collateral %d", collateral.balance);

    uint256 increseTokensSender = increaseTokens.mul(7).div(10);
    uint256 increseTokensCollateral = increaseTokens - increseTokensSender;

    _mint(msg.sender, increseTokensSender);
    _mint(collateral, increseTokensCollateral);
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