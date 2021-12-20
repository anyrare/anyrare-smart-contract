pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CollateralToken is ERC20 {
    address public owner;

    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        uint256 initialAmount
    ) public ERC20(_name, _symbol) {
        owner = _owner;
        _mint(msg.sender, initialAmount);
    }

    function mint(uint256 amount) public payable {
        require(
            msg.sender == owner,
            "Error 2000: No permission to mint new token."
        );

        _mint(owner, amount);
    }
}
