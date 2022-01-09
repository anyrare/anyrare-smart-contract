pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Governance.sol";
import "./CollectionToken.sol";

contract CollectionFactory {
    address private governanceContract;
    uint256 currentTokenId;

    mapping(uint256 => address) public collections;

    constructor(address _governanceContract) {
        governanceContract = _governanceContract;
    }

    function g() private view returns (Governance) {
        return Governance(governanceContract);
    }

    function m() public view returns (Member) {
        return Member(g().getMemberContract());
    }

    function t() public view returns (ERC20) {
        return ERC20(g().getARATokenContract());
    }

    function b() public returns (BancorFormula) {
        return BancorFormula(g().getBancorFormulaContract());
    }

    function n() public returns (ERC721) {
        return ERC721(g().getNFTFactoryContract());
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
            _initialValue
        );

        for (uint32 i = 0; i < _totalNft; i++) {
            require(n().ownerOf(_nfts[i]) == msg.sender);
        }

        for (uint32 i = 0; i < _totalNft; i++) {
            n().transferFrom(msg.sender, address(this), _nfts[i]);
        }

        // token.mint(msg.sender, 10 ** 25, _totalNft, _nfts);

        collections[currentTokenId] = address(token);
        currentTokenId += 1;
    }
}
