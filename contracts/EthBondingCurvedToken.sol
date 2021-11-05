// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// contract EthBondingCurvedToken is ERC20 {
//   event Minted(uint256 amount, uint256 totalCost);
//   event Burned(uint256 amount, uint256 reward);

//   using SafeMath for uint256;

//   uint256 public poolBalance;

//   constructor(
//     string name,
//     string symbol,
//     uint8 decimals
//   ) ERC20(name, symbol, decimals) public {}

//   function priceToMint(uint256 numTokens) public returns(uint256);
  
//   function rewardForBurn(uint256 numTokens) public returns(uint256);

//   function mint(uint256 numTokens) public {
//     uint256 priceForTokens = priceToMint(numTokens);
//     require(reserveToken.transferFrom(msg.sender, this, priceForTokens));

//     totalSupply_ = totalSupply_.add(numTokens);
//     balances[msg.sender] = balances[msg.sender].add(numTokens);
//     poolBalance = poolBalance.add(priceForTokens);
//     if (msg.value > priceForTokens) {
//       msg.sender.transfer(msg.value - priceForTokens);
//     }

//     emit Minted(numTokens, priceForTokens);
//   }

//   function burn(uint256 numTokens) public {
//     require(balances[msg.sender] >= numTokens);

//     uint256 reserveTokenToReturn = rewardForBurn(numTokens);
//     totalSupply_ = totalSupply_.sub(numTokens);
//     balances[msg.sender] = balances[msg.sender].sub(numTokens);
//     poolBalance = poolBalance.sub(reserveTokensToReturn);
//     reserveToken.transfer(msg.sender, reserveTokenToReturn);
//     msg.sender.transfer(ethToReturn);

//     emit Burned(numTokens, reserveTokensToReturn);
//   }
// }