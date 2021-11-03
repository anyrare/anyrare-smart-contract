pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract ARAToken is ERC20 {
  constructor(uint256 initialSupply) ERC20("Anyrare", "ARA") {
    _mint(msg.sender, initialSupply);
  }

  function mintMinerReward() public {
    console.log("block.coinbase %s", block.coinbase);
    _mint(block.coinbase, 100);
  }
}