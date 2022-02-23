pragma solidity ^0.8.0;

import {AppStorage} from "../libraries/LibAppStorage.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract CollateralTokenFacet {
    AppStorage internal s;

    uint256 constant MAX_UINT = type(uint256).max;

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function name() external pure returns (string memory) {
        return "wDAI";
    }

    function symbol() external pure returns (string memory) {
        return "wDAI";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return s.collateralToken.totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        balance = s.collateralToken.balances[_owner];
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        uint256 fromBalances = s.collateralToken.balances[msg.sender];
        require(
            fromBalances >= _value,
            "CollateralToken: Not enough token to transfer"
        );
        s.collateralToken.balances[msg.sender] = fromBalances - _value;
        s.collateralToken.balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        success = true;
    }

    function addApprovedContract(address _contract) external {
        LibDiamond.enforceIsContractOwner();
        require(
            s.collateralToken.approvedContractIndexes[_contract] == 0,
            "CollateralToken: Approved contract already exists"
        );
        s.collateralToken.approvedContracts.push(_contract);
    }

    function removeApprovedContract(address _contract) external {
        LibDiamond.enforceIsContractOwner();
        uint256 index = s.collateralToken.approvedContractIndexes[_contract];
        require(index > 0, "CollateralToken: Approved contract does not exist");
        uint256 lastIndex = s.collateralToken.approvedContracts.length;
        if (index != lastIndex) {
            address lastContract = s.collateralToken.approvedContracts[
                lastIndex - 1
            ];
            s.collateralToken.approvedContracts[index - 1] = lastContract;
            s.collateralToken.approvedContractIndexes[lastContract] = index;
        }
        s.collateralToken.approvedContracts.pop();
        delete s.collateralToken.approvedContractIndexes[_contract];
    }

    function approvedContracts()
        external
        view
        returns (address[] memory contracts_)
    {
        contracts_ = s.collateralToken.approvedContracts;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        uint256 fromBalance = s.collateralToken.balances[_from];
        if (
            msg.sender == _from ||
            s.collateralToken.approvedContractIndexes[msg.sender] > 0
        ) {
            // pass
        } else {
            uint256 l_allowance = s.collateralToken.allowances[_from][
                msg.sender
            ];
            require(
                l_allowance >= _value,
                "CollateralToken: Not allowed to transfer"
            );
            if (l_allowance != MAX_UINT) {
                s.collateralToken.allowances[_from][msg.sender] =
                    l_allowance -
                    _value;
                emit Approval(_from, msg.sender, l_allowance - _value);
            }
        }
        require(
            fromBalance >= _value,
            "ColltateralToken: Not enough GHST to transfer"
        );
        s.collateralToken.balances[_from] = fromBalance - _value;
        s.collateralToken.balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        success = true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        s.collateralToken.allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        success = true;
    }

    function increaseAllowance(address _spender, uint256 _value)
        external
        returns (bool success)
    {
        uint256 l_allowance = s.collateralToken.allowances[msg.sender][
            _spender
        ];
        uint256 newAllowance = l_allowance + _value;
        require(
            newAllowance >= l_allowance,
            "CollateralToken: Allowance increase overflowed"
        );
        s.collateralToken.allowances[msg.sender][_spender] = newAllowance;
        emit Approval(msg.sender, _spender, newAllowance);
        success = true;
    }

    function decreaseAllowance(address _spender, uint256 _value)
        external
        returns (bool success)
    {
        uint256 l_allowance = s.collateralToken.allowances[msg.sender][
            _spender
        ];
        require(
            l_allowance >= _value,
            "CollateralToken: Allowance decreased below 0"
        );
        l_allowance -= _value;
        s.collateralToken.allowances[msg.sender][_spender] = l_allowance;
        emit Approval(msg.sender, _spender, l_allowance);
        success = true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining_)
    {
        remaining_ = s.collateralToken.allowances[_owner][_spender];
    }

    function mint(uint256 amount) public {
        require(
            msg.sender == s.collateralToken.owner,
            "CollateralTokenFacet: No permission to mint"
        );
        s.collateralToken.balances[msg.sender] += amount;
        s.collateralToken.totalSupply += uint96(amount);
        emit Transfer(address(0), msg.sender, amount);
    }

    function mintTo(address addr, uint256 amount) public {
        require(
            msg.sender == s.collateralToken.owner,
            "CollateralTokenFacet: No permission to mint"
        );
        s.collateralToken.balances[addr] += amount;
        s.collateralToken.totalSupply += uint96(amount);
        emit Transfer(address(0), addr, amount);
    }

    function collateralTokenSetOwner(address _owner) external {
        require(
            s.collateralToken.owner == address(0) ||
                msg.sender == s.collateralToken.owner,
            "CollateralTokenFacet: Failed to set owner"
        );
        s.collateralToken.owner = _owner;
    }

    function collateralTokenMint(address addr, uint256 amount)
        external
        payable
    {
        mintTo(addr, amount);
    }

    function collateralTokenTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    function collateralTokenBalanceOf(address addr)
        external
        view
        returns (uint256)
    {
        return balanceOf(addr);
    }

    function collateralTokenTransfer(address recipient, uint256 amount)
        external
        payable
    {
        transfer(recipient, amount);
    }

    function collateralTokenTransferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external payable {
        transferFrom(sender, recipient, amount);
    }

    function collateralTokenApprove(address spender, uint256 amount) external {
        approve(spender, amount);
    }
}
