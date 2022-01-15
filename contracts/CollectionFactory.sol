pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Governance.sol";
import "./CollectionToken.sol";
import "./NFTFactory.sol";

contract CollectionFactory {
    address private governanceContract;
    uint256 currentTokenId;

    struct CollectionIndex {
        bool exists;
        uint256 tokenId;
    }

    mapping(uint256 => address) public collections;
    mapping(address => CollectionIndex) public collectionIndexes;

    constructor(address _governanceContract) {
        governanceContract = _governanceContract;
    }

    function g() private view returns (Governance) {
        return Governance(governanceContract);
    }

    function n() private view returns (NFTFactory) {
        return NFTFactory(g().getNFTFactoryContract());
    }

    function getCurrentTokenId() public view returns (uint256) {
        return currentTokenId - 1;
    }

    function isValidCollection(address addr) public view returns (bool) {
        return collectionIndexes[addr].exists;
    }

    function mint(
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        uint256 _initialValue,
        uint256 _maxWeight,
        uint256 _collateralWeight,
        uint256 _collectorFeeWeight,
        uint32 _totalNft,
        uint256[] memory _nfts
    ) public payable {
        CollectionToken token = new CollectionToken(
            governanceContract,
            msg.sender,
            _name,
            _symbol,
            _tokenURI,
            _initialValue,
            _maxWeight,
            _collateralWeight,
            _collectorFeeWeight
        );

        for (uint32 i = 0; i < _totalNft; i++) {
            require(n().ownerOf(_nfts[i]) == msg.sender);
        }

        for (uint32 i = 0; i < _totalNft; i++) {
            n().transferFromCollectionFactory(
                msg.sender,
                address(token),
                _nfts[i]
            );
        }

        token.mint(
            msg.sender,
            (_initialValue * _collateralWeight) / _maxWeight,
            _totalNft,
            _nfts
        );

        collections[currentTokenId] = address(token);
        collectionIndexes[address(token)] = CollectionIndex({
            exists: true,
            tokenId: currentTokenId
        });
        currentTokenId += 1;
    }
}
