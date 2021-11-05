pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "hardhat/console.sol";

contract BondingCurvedToken is ERC20 {

  address public collateral;
  uint256 public poolBalance;


  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals,
    address _collateral
  ) ERC20(name, symbol) public {
    console.log("address %s", _collateral);
    // console.log("totalSupply %d", totalSupply);
    collateral = _collateral;
    _mint(msg.sender, 10);
  }

  function priceToMint(uint256 numTokens) public returns(uint256)  {
    return numTokens;
  }
  
  // function rewardForBurn(uint256 numTokens) public returns(uint256);

  function mint(uint256 numTokens) public payable {
    uint256 priceForTokens = priceToMint(numTokens);
    _transfer(msg.sender, collateral, 1);
    // require(msg.value >= priceForTokens);

    _mint(msg.sender, numTokens);
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