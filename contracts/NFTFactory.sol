pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ARAToken.sol";
import "./Member.sol";
import "./Governance.sol";

contract NFTFactory is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    struct NFTInfoAddress {
        address auditorAddr;
        address custodianAddr;
        address founderAddr;
        address ownerAddr;
    }

    struct NFTInfoFee {
        bool isPaidFeeAndClaimToken;
        uint32 maxWeight;
        uint32 founderRoyaltyWeight;
        uint32 custodianFeeWeight;
        uint256 founderRedeemFee;
        uint256 custodianRedeemFee;
        uint256 auditFee;
        uint256 mintFee;
    }

    struct NFTAuctionBid {
        uint256 timestamp;
        uint256 value;
        uint256 bidder;
    }

    struct NFTAuction {
        uint256 openAuctionTimestamp;
        uint256 closeAuctionTimestamp;
        address ownerAddr;
        address winnerAddr;
        address bidderAddr;
        uint256 value;
        uint32 totalBid;
        mapping(uint32 => NFTAuctionBid) bids;
    }

    struct NFTInfo {
        bool exists;
        uint256 tokenId;
        bool isLockInCollection;
        bool isAuction;
        NFTInfoAddress addr;
        NFTInfoFee fee;
        uint32 totalAuction;
        mapping(uint32 => NFTAuction) auctions;
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
        require(isCustodian(custodianAddr), "Error 5001: Invalid custodian");
        require(
            isMember(founderAddr),
            "Error 5002: Invalid member no permission to mint new token"
        );

        tokenIds.increment();

        uint256 tokenId = tokenIds.current();

        NFTInfoAddress memory addr = NFTInfoAddress({
            auditorAddr: msg.sender,
            custodianAddr: custodianAddr,
            founderAddr: founderAddr,
            ownerAddr: address(this)
        });

        NFTInfoFee memory fee = NFTInfoFee({
            isPaidFeeAndClaimToken: false,
            maxWeight: maxWeight,
            founderRoyaltyWeight: founderRoyaltyWeight,
            founderRedeemFee: founderRedeemFee,
            custodianFeeWeight: 0,
            custodianRedeemFee: 0,
            auditFee: auditFee,
            mintFee: 0
        });

        nfts[tokenId].exists = true;
        nfts[tokenId].tokenId = tokenId;
        nfts[tokenId].isLockInCollection = false;
        nfts[tokenId].isAuction = false;
        nfts[tokenId].addr = addr;
        nfts[tokenId].fee = fee;

        _mint(address(this), tokenId);
        _setTokenURI(tokenId, tokenURI);

        return tokenId;
    }

    function payFeeAndClaimToken(uint256 tokenId) public payable {
        require(nfts[tokenId].exists, "Error 5003: Token doesn't exists");
        NFTInfo storage nft = nfts[tokenId];

        require(
            nft.addr.founderAddr == msg.sender,
            "Error 5004: No permission to claim this token"
        );

        Governance g = Governance(governanceContract);
        ERC20 t = ERC20(g.getARATokenContract());

        require(
            t.balanceOf(msg.sender) >= nft.fee.auditFee + nft.fee.mintFee,
            "Error 5005: Insufficient token to pay fee"
        );

        t.transferFrom(msg.sender, nft.addr.auditorAddr, nft.fee.auditFee);
        transferFrom(address(this), msg.sender, tokenId);
    }

    function openAuction(uint256 tokenId) public {}
}
