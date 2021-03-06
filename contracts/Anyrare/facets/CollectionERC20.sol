// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import {CollectionStorage} from "../libraries/LibAppStorage.sol";

contract CollectionERC20 {
    CollectionStorage internal s;

    uint256 constant MAX_UINT = type(uint256).max;

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Burn(address indexed _from, uint256 _value);

    function name() external view returns (string memory) {
        return s.name;
    }

    function symbol() external view returns (string memory) {
        return s.symbol;
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

    function tokenURI() external view returns (string memory) {
        return s.tokenURI;
    }

    function setMetadata(
        string memory _name,
        string memory _symbol,
        string memory _tokenURI
    ) public {
        require(msg.sender == s.owner || s.owner == address(0));
        s.owner = msg.sender;
        s.name = _name;
        s.symbol = _symbol;
        s.tokenURI = _tokenURI;
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(msg.sender == s.owner);
        uint256 frombalances = s.balances[msg.sender];
        require(
            frombalances >= _value,
            "CollectionERC20: Not enough Token to transfer"
        );
        s.balances[msg.sender] = frombalances - _value;
        s.balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        success = true;
    }

    function addApprovedContract(address _contract) external {
        LibDiamond.enforceIsContractOwner();
        require(
            s.approvedContractIndexes[_contract] == 0,
            "CollectionERC20: Approved contract already exists"
        );
        s.approvedContracts.push(_contract);
        s.approvedContractIndexes[_contract] = s.approvedContracts.length;
    }

    function removeApprovedContract(address _contract) external {
        LibDiamond.enforceIsContractOwner();
        uint256 index = s.approvedContractIndexes[_contract];
        require(index > 0, "CollectinERC20: Approved contract does not exist");
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
        require(msg.sender == s.owner);
        uint256 fromBalance = s.balances[_from];
        if (msg.sender == _from || s.approvedContractIndexes[msg.sender] > 0) {
            // pass
        } else {
            uint256 l_allowance = s.allowances[_from][msg.sender];
            require(
                l_allowance >= _value,
                "CollectionERC20: Not allowed to transfer"
            );
            if (l_allowance != MAX_UINT) {
                s.allowances[_from][msg.sender] = l_allowance - _value;
                emit Approval(_from, msg.sender, l_allowance - _value);
            }
        }
        require(
            fromBalance >= _value,
            "CollectionERC20: Not enough token to transfer"
        );
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
            "CollectionERC20: Allowance increase overflowed"
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
        require(
            l_allowance >= _value,
            "CollectionERC20: Allowance decreased below 0"
        );
        l_allowance -= _value;
        s.allowances[msg.sender][_spender] = l_allowance;
        emit Approval(msg.sender, _spender, l_allowance);
        success = true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining_)
    {
        remaining_ = s.allowances[_owner][_spender];
    }

    function mint(uint256 amount) external {
        require(msg.sender == s.owner);
        s.balances[msg.sender] += amount;
        s.totalSupply += uint96(amount);
        emit Transfer(address(0), msg.sender, amount);
    }

    function mintTo(address _user, uint256 _amount) external {
        require(msg.sender == s.owner);
        s.balances[_user] += _amount;
        s.totalSupply += uint96(_amount);
        emit Transfer(address(0), _user, _amount);
    }

    function burn(address _user, uint256 _amount) external {
        require(msg.sender == s.owner && s.balances[_user] >= _amount);
        s.balances[_user] -= _amount;
        s.totalSupply -= uint96(_amount);
        emit Burn(_user, _amount);
    }
}
