pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Member.sol";
import "./Governance.sol";

contract NFTFactory is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    struct NFTInfo {
        bool exists;
        uint256 tokenId;
        address auditorAddr;
        address custodianAddr;
        address founderAddr;
        address ownerAddr;
        address auctionAddr;
        bool isLockInCollection;
        bool isAuction;
        bool isPaidAuditFee;
        bool isPaidMintFee;
        uint32 maxWeight;
        uint32 founderRoyaltyWeight;
        uint32 custodianFeeWeight;
        uint256 founderRedeemFee;
        uint256 custodianRedeemFee;
        uint256 auditFee;
        uint256 mintFee;
    }

    mapping(uint256 => NFTInfo) public nfts;

    address public governanceContract;

    constructor(
        address _governanceContract,
        string memory _name,
        string memory _symbol
    ) public ERC721(_name, _symbol) {
        governanceContract = _governanceContract;
    }

    function isMember(address account) public view returns (bool) {
        Governance g = Governance(governanceContract);
        Member m = Member(g.getMemberContract());
        return m.isMember(account);
    }

    function isAuditor(address account) public view returns (bool) {
        Governance g = Governance(governanceContract);
        return g.isAuditor(account);
    }

    function isCustodian(address account) public view returns (bool) {
        Governance g = Governance(governanceContract);
        return g.isCustodian(account);
    }

    function mint(
        address founderAddr,
        address custodianAddr,
        string memory tokenURI,
        uint32 maxWeight,
        uint32 founderRoyaltyWeight,
        uint256 founderRedeemFee,
        uint256 auditFee
    ) public returns (uint256) {
        require(
            isAuditor(msg.sender),
            "Error 5000: Invalid auditor no permission to mint new token"
        );
        require(isCustodian(custdianAddr), "Error 5001: Invalid custodian");
        require(
            isMember(founderAddr),
            "Error 5002: Invalid member no permission to mint new token"
        );

        tokenIds.increment();

        uint256 tokenId = tokenIds.current();

        nfts[tokenId].exists = true;
        nfts[tokenId].tokenId = tokenId;
        nfts[tokenId].auditorAddr = msg.sender;
        nfts[tokenId].custodianAddr = custodianAddr;
        nfts[tokenId].founderAddr = founderAddr;
        nfts[tokenId].ownerAddr = address(this);
        nfts[tokenId].isLockInCollection = false;
        nfts[tokenId].isAuction = false;
        nfts[tokenId].isPaidAuditFee = false;
        nfts[tokenId].isPaidMintFee = false;
        nfts[tokenId].maxWeight = maxWeight;
        nfts[tokenId].founderRoyaltyWeight = founderRoyaltyWeight;
        nfts[tokenId].founderRedeemFee = founderRedeemFee;
        nfts[tokenId].auditFee = auditFee;
        // TODO: Add min fee from policy
        nfts[tokenId].mintFee = 0;

        _mint(address(this), tokenId);
        _setTokenURI(tokenId, tokenURI);

        return tokenId;
    }

    
}
