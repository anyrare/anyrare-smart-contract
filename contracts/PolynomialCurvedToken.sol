// pragma solidity ^0.8.0;

// import "./BondingCurvedToken.sol";

// contract PolynomialCurvedToken is BondingCurvedToken {
//   uint256 constant private PRECISION = 10**10;

//   uint8 public exponent;

//   constructor(
//     string name,
//     string symbol,
//     uint8 decimals,
//     address reserveToken,
//     uint _exponent
//   ) BondingCurvedToken(name, symbol, decimals, reserveToken) public {
//     exponent = _exponent;
//   }

//   function curveIntegral(uint256 t) internal returns (uint256) {

//     uint256 nexp = exponent + 1;

//     return PRECISION.div(nexp).mul(t ** nexp).div(PRECISION);
//   }

//   function priceToMint(uint256 numTokens) public returns(uint256) {
//     return curveIntegral(totalSupply_.add(numTokens)).sub(poolBalance);
//   }

//   function rewardForBurn(uint256 numTokens) public returns(uint256) {
//     return poolBalance.sub(curveIntegral(totalSupply_.sub(numTokens)));
//   }
// }