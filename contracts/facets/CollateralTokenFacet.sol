pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";
import "hardhat/console.sol";

contract CollateralTokenFacet is ERC20 {
    AppStorage internal s;

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}

    function collateralTokenSetOwner(address _owner) external {
        require(
            s.collateralToken.owner == address(0) ||
                msg.sender == s.collateralToken.owner,
            "CollateralTokenFacet: Failed to set owner"
        );
        console.log("setOwner", msg.sender, _owner);
        s.collateralToken.owner = _owner;
    }

    function collateralTokenMint(address addr, uint256 amount)
        external
        payable
    {
        require(
            msg.sender == s.collateralToken.owner,
            "CollateralTokenFacet: Failed to mint"
        );
        _mint(addr, amount);
    }

    function collateralTokenTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    function collateralTokenBalanceOf(address addr) external view returns (uint256) {
        return balanceOf(addr);
    }

    function collateralTokenTransfer(address recipient, uint256 amount)
        external
        payable
    {
        transfer(recipient, amount);
    }

    function collateralTokenApprove(address spender, uint256 amount) external{
        approve(spender, amount);
    }
}
