pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "hardhat/console.sol";

contract ARAToken is ERC20 {
  using SafeMath for uint256;

  uint256 public scale = 10**18;
  uint256 public poolBalance = 1*scale;
  uint256 public reserveRatio;

  constructor(uint256 initialSupply) ERC20("Anyrare", "ARA") {
    _mint(msg.sender, initialSupply);
  }

  function mintMinerReward() public {
    console.log("block.coinbase %s", block.coinbase);
    _mint(block.coinbase, 100);
  }

  modifier validMint(uint256 _amount) {
    require(_amount > 0, "Amount must be non-zero!");
    _;
  }

  modifier validBurn(uint256 _amount) {
    require(_amount > 0, "Amount must be non-zero!");
    require(balanceOf(msg.sender) >= _amount, "Sender does not have enough tokens to burn.");
    _;
  }

  function mint(uint256 _deposit)
    validMint(_deposit)
    public
  {
    uint256 amount = _deposit ** 2;
    _mint(msg.sender, amount);
  }

  function burn(uint256 _amount)
    validBurn(_amount)
    public
  {
    uint256 amount = _amount ** 2;
    _burn(msg.sender, amount);
  }
}