pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";
import {LibBancorFormula} from "../libraries/LibBancorFormula.sol";

contract ARATokenFacet is ERC20 {
    AppStorage internal s;

    constructor(
        string memory _name,
        string memory _symbol,
        address _collateralToken,
        uint256 initialAmount
    ) ERC20(_name, _symbol) {
        s.araToken.collateralToken = _collateralToken;
        _mint(msg.sender, initialAmount);
    }
}
