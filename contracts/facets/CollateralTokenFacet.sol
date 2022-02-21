pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";

contract CollateralTokenFacet is ERC20 {
    AppStorage internal s;

    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        uint256 initialAmount
    ) ERC20(_name, _symbol) {
        s.collateralToken.owner = _owner;
        _mint(msg.sender, initialAmount);
    }

    function mint(uint256 amount) public payable {
        require(msg.sender == s.collateralToken.owner);
        _mint(s.collateralToken.owner, amount);
    }
}
