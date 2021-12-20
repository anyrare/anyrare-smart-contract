pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Member.sol";
import "./Governance.sol";
import "./CollateralToken.sol";
import "./converter/BancorFormula.sol";

contract ARA is ERC20 {
    address public governanceContract;
    address public bancorFormulaContract;
    address public collateralToken;
    address public collateralReserve;

    constructor(
        address _governanceContract,
        address _bancorFormulaContract,
        string memory _name,
        string memory _symbol,
        address _collateralToken,
        address _collateralReserve,
        uint256 initialAmount
    ) public ERC20(_name, _symbol) {
        governanceContract = _governanceContract;
        bancorFormulaContract = _bancorFormulaContract;
        collateralToken = _collateralToken;
        collateralReserve = _collateralReserve;
        _mint(msg.sender, initialAmount);
    }

    function mint(uint256 amount) public payable {
        if (!isValidMember(msg.sender)) {
            revert(
                "Error 1000: Not a valid member and have no permission to mint new token."
            );
        }

        Governance g = Governance(governanceContract);
        BancorFormula b = BancorFormula(bancorFormulaContract);
        CollateralToken c = CollateralToken(collateralToken);

        uint256 mintAmounts = b.purchaseTargetAmount(
            this.totalSupply(),
            c.balanceOf(collateralReserve),
            g.getCollateralWeight(),
            amount
        );

        ERC20(collateralToken).transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, mintAmounts);
    }

    function isValidMember(address account) public view returns (bool) {
        Governance g = Governance(governanceContract);
        Member m = Member(g.getMemberContract());
        return m.isValidMember(account);
    }
}
