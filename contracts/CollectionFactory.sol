pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Governance.sol";
import "./CollectionToken.sol";

contract CollectionFactory {
    address private governanceContract;
    uint256 currentTokenId;

    mapping(uint256 => CollectionToken) collections;

    constructor(address _governanceContract) {
        governanceContract = _governanceContract;
    }

    function getCurrentTokenId() public view returns (uint256) {
        return currentTokenId - 1;
    }

    function mint(
        string memory _name,
        string memory _symbol,
        uint256 _initialValue,
        uint32 _totalNft,
        uint256[] memory _nfts
    ) public {
        CollectionToken token = new CollectionToken(
            governanceContract,
            msg.sender,
            _name,
            _symbol,
            _initialValue,
            10 ** 25,
            _totalNft,
            _nfts
        );

        collections[currentTokenId] = token;
        currentTokenId += 1;
    }
}
