// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import {LibBancorFormula} from "../../shared/libraries/LibBancorFormula.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";
import {DataFacet} from "../../Anyrare/facets/DataFacet.sol";
import "hardhat/console.sol";

contract ARAFacet {
    AppStorage internal s;

    uint256 constant MAX_UINT = type(uint256).max;

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function init(uint256 initialSupply) external {
        require(s.owner == address(0) && s.totalSupply == 0);
        s.owner = msg.sender;
        s.totalSupply = initialSupply;
    }

    function setOwner(address owner, address anyrare) external {
        require(s.owner == address(0) || msg.sender == owner);
        s.owner = owner;
        s.anyrare = anyrare;
    }

    function name() external pure returns (string memory) {
        return "ARA";
    }

    function symbol() external pure returns (string memory) {
        return "ARA";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return s.totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        balance = s.balances[_owner];
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        uint256 frombalances = s.balances[msg.sender];
        require(frombalances >= _value, "ARA: Not enough ARA to transfer");
        s.balances[msg.sender] = frombalances - _value;
        s.balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        success = true;
    }

    function addApprovedContract(address _contract) external {
        LibDiamond.enforceIsContractOwner();
        require(
            s.approvedContractIndexes[_contract] == 0,
            "ARAFacet: Approved contract already exists"
        );
        s.approvedContracts.push(_contract);
        s.approvedContractIndexes[_contract] = s.approvedContracts.length;
    }

    function removeApprovedContract(address _contract) external {
        LibDiamond.enforceIsContractOwner();
        uint256 index = s.approvedContractIndexes[_contract];
        require(index > 0, "ARAFacet: Approved contract does not exist");
        uint256 lastIndex = s.approvedContracts.length;
        if (index != lastIndex) {
            address lastContract = s.approvedContracts[lastIndex - 1];
            s.approvedContracts[index - 1] = lastContract;
            s.approvedContractIndexes[lastContract] = index;
        }
        s.approvedContracts.pop();
        delete s.approvedContractIndexes[_contract];
    }

    function approvedContracts()
        external
        view
        returns (address[] memory contracts_)
    {
        contracts_ = s.approvedContracts;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        uint256 fromBalance = s.balances[_from];
        if (msg.sender == _from || s.approvedContractIndexes[msg.sender] > 0) {
            // pass
        } else {
            uint256 l_allowance = s.allowances[_from][msg.sender];
            require(l_allowance >= _value, "ARA: Not allowed to transfer");
            if (l_allowance != MAX_UINT) {
                s.allowances[_from][msg.sender] = l_allowance - _value;
                emit Approval(_from, msg.sender, l_allowance - _value);
            }
        }
        require(fromBalance >= _value, "ARA: Not enough ARA to transfer");
        s.balances[_from] = fromBalance - _value;
        s.balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        success = true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        s.allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        success = true;
    }

    function increaseAllowance(address _spender, uint256 _value)
        external
        returns (bool success)
    {
        uint256 l_allowance = s.allowances[msg.sender][_spender];
        uint256 newAllowance = l_allowance + _value;
        require(
            newAllowance >= l_allowance,
            "ARAFacet: Allowance increase overflowed"
        );
        s.allowances[msg.sender][_spender] = newAllowance;
        emit Approval(msg.sender, _spender, newAllowance);
        success = true;
    }

    function decreaseAllowance(address _spender, uint256 _value)
        external
        returns (bool success)
    {
        uint256 l_allowance = s.allowances[msg.sender][_spender];
        require(l_allowance >= _value, "ARAFacet: Allowance decreased below 0");
        l_allowance -= _value;
        s.allowances[msg.sender][_spender] = l_allowance;
        emit Approval(msg.sender, _spender, l_allowance);
        success = true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return s.allowances[_owner][_spender];
    }

    function mint(uint16 collateralId, string memory transactionId) external {
        uint256 amount = s
            .collaterals[collateralId]
            .transactions[transactionId]
            .amount;
        address to = s
            .collaterals[collateralId]
            .transactions[transactionId]
            .wallet;

        require(
            amount > 0 &&
                !s
                    .collaterals[collateralId]
                    .transactions[transactionId]
                    .isSettle
        );

        s.collaterals[collateralId].transactions[transactionId].isSettle = true;

        uint256 mintAmounts = LibBancorFormula.purchaseTargetAmount(
            s.totalSupply,
            s.totalCollateralValue,
            uint32(
                DataFacet(s.anyrare)
                    .getPolicy("ARA_COLLATERAL_WEIGHT")
                    .policyWeight
            ),
            amount
        );

        s.totalCollateralValue += amount;
        s.totalSupply += mintAmounts;

        uint256 managementFund = ((mintAmounts *
            DataFacet(s.anyrare)
                .getPolicy("ARA_MINT_MANAGEMENT_FUND_WEIGHT")
                .policyWeight) /
            DataFacet(s.anyrare)
                .getPolicy("ARA_MINT_MANAGEMENT_FUND_WEIGHT")
                .maxWeight);

        if (managementFund > 0) {
            s.balances[s.anyrare] += managementFund;
            s.managementFundValue += managementFund;
        }

        if (mintAmounts - managementFund > 0) {
            s.balances[to] += mintAmounts - managementFund;
        }

        emit Transfer(address(0), to, amount);
    }

    function withdraw(uint256 amount) external {
        uint256 withdrawAmounts = LibBancorFormula.saleTargetAmount(
            s.totalSupply,
            s.totalCollateralValue,
            uint32(
                DataFacet(s.anyrare)
                    .getPolicy("ARA_COLLATERAL_WEIGHT")
                    .policyWeight
            ),
            amount
        );

        require(
            DataFacet(s.anyrare).isMember(msg.sender) &&
                s.balances[msg.sender] >= amount &&
                amount > 0 &&
                s.totalCollateralValue >= withdrawAmounts
        );

        s.balances[msg.sender] -= amount;
        s.totalSupply -= amount;

        if (withdrawAmounts > 0) {
            s.totalCollateralValue -= withdrawAmounts;
            // Transfer to other chain
        }
    }

    function burn(uint256 amount) external {
        require(
            (DataFacet(s.anyrare).isMember(msg.sender) ||
                msg.sender == s.anyrare) &&
                s.balances[msg.sender] >= amount &&
                amount > 0
        );

        s.balances[msg.sender] -= amount;
        s.totalSupply -= amount;
    }

    function crossChainDepositCollateral(
        address to,
        uint256 amount,
        uint16 collateralId,
        string memory transactionId
    ) external {
        require(
            msg.sender == s.owner &&
                DataFacet(s.anyrare).isMember(to) &&
                amount > 0
        );

        s.totalCollateralValue += amount;
        s.collaterals[collateralId].totalValue += amount;
        s
            .collaterals[collateralId]
            .transactions[transactionId]
            .transactionId = transactionId;
        s.collaterals[collateralId].transactions[transactionId].wallet = to;
        s.collaterals[collateralId].transactions[transactionId].amount = amount;
        s.collaterals[collateralId].totalTransaction += 1;
        s.collaterals[collateralId].balances[to] += amount;
    }
}
