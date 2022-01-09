pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Governance.sol";
import "./CollectionToken.sol";
import "./NFTFactory.sol";

contract CollectionFactory  {
    address private governanceContract;
    uint256 currentTokenId;

    mapping(uint256 => address) public collections;

    constructor(address _governanceContract) {
        governanceContract = _governanceContract;
    }

    function g() private view returns (Governance) {
        return Governance(governanceContract);
    }

    function n() public view returns (NFTFactory) {
        return NFTFactory(g().getNFTFactoryContract());
    }

    function t(address addr) public view returns (CollectionToken) {
        return CollectionToken(addr);
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
    ) public payable {
        CollectionToken token = new CollectionToken(
            governanceContract,
            msg.sender,
            _name,
            _symbol,
            _initialValue
        );

        for (uint32 i = 0; i < _totalNft; i++) {
            require(n().ownerOf(_nfts[i]) == msg.sender);
        }

        for (uint32 i = 0; i < _totalNft; i++) {
            n().transferFromCollectionFactory(msg.sender, address(token), _nfts[i]);
        }

        token.mint(msg.sender, 10 ** 25, _totalNft, _nfts);

        collections[currentTokenId] = address(token);
        currentTokenId += 1;
    }
}
