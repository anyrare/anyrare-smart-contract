pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./ARAToken.sol";
import "./Member.sol";
import "./Governance.sol";

contract NFTFactory is ERC721URIStorage {
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
        uint32 auctionId;
        uint256 timestamp;
        uint256 value;
        address bidder;
    }

    struct NFTAuction {
        uint256 openAuctionTimestamp;
        uint256 closeAuctionTimestamp;
        address ownerAddr;
        address bidderAddr;
        uint256 startingPrice;
        uint256 value;
        uint32 maxWeight;
        uint32 nextBidWeight;
        uint32 totalBid;
    }

    struct NFTInfo {
        bool exists;
        uint256 tokenId;
        bool isClaim;
        bool isLockInCollection;
        bool isAuction;
        NFTInfoAddress addr;
        NFTInfoFee fee;
        uint32 totalAuction;
        uint32 bidId;
        mapping(uint32 => NFTAuction) auctions;
        mapping(uint32 => NFTAuctionBid) bids;
    }

    mapping(uint256 => NFTInfo) public nfts;

    address private governanceContract;
    uint256 private currentTokenId;

    constructor(
        address _governanceContract,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        governanceContract = _governanceContract;
        currentTokenId = 0;
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

        NFTInfoAddress memory addr = NFTInfoAddress({
            auditorAddr: msg.sender,
            custodianAddr: custodianAddr,
            founderAddr: founderAddr,
            ownerAddr: address(this)
        });

        Governance g = Governance(governanceContract);

        NFTInfoFee memory fee = NFTInfoFee({
            isPaidFeeAndClaimToken: false,
            maxWeight: maxWeight,
            founderRoyaltyWeight: founderRoyaltyWeight,
            founderRedeemFee: founderRedeemFee,
            custodianFeeWeight: 0,
            custodianRedeemFee: 0,
            auditFee: auditFee,
            mintFee: g.getPolicy("NFT_MINT_FEE").policyValue
        });

        uint256 tokenId = currentTokenId;

        nfts[tokenId].exists = true;
        nfts[tokenId].tokenId = tokenId;
        nfts[tokenId].isClaim = false;
        nfts[tokenId].isLockInCollection = false;
        nfts[tokenId].isAuction = false;
        nfts[tokenId].addr = addr;
        nfts[tokenId].fee = fee;
        nfts[tokenId].totalAuction = 0;
        nfts[tokenId].bidId = 0;

        _mint(address(this), tokenId);
        _setTokenURI(tokenId, tokenURI);

        currentTokenId += 1;

        return tokenId;
    }

    function payFeeAndClaimToken(uint256 tokenId) public payable {
        require(
            nfts[tokenId].exists && !nfts[tokenId].isClaim,
            "Error 5003: Token doesn't exists or already claim."
        );
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

        if (nft.fee.auditFee + nft.fee.mintFee > 0) {
            t.transferFrom(
                msg.sender,
                address(this),
                nft.fee.auditFee + nft.fee.mintFee
            );
        }

        if (nft.fee.auditFee > 0) {
            t.transfer(nft.addr.auditorAddr, nft.fee.auditFee);
        }

        if (nft.fee.mintFee > 0) {
            t.transfer(g.getManagmentFundContract(), nft.fee.mintFee);
        }

        _transfer(address(this), msg.sender, tokenId);

        nfts[tokenId].isClaim = true;
    }

    function openAuction(
        uint256 tokenId,
        uint256 closeAuctionPeriodSecond,
        uint256 startingPrice,
        uint32 maxWeight,
        uint32 nextBidWeight
    ) public payable {
        require(
            ownerOf(tokenId) == msg.sender,
            "Error 5006: Not an owner of this token"
        );

        NFTAuction memory auction = NFTAuction({
            openAuctionTimestamp: block.timestamp,
            closeAuctionTimestamp: block.timestamp + closeAuctionPeriodSecond,
            ownerAddr: msg.sender,
            bidderAddr: address(0x0),
            startingPrice: startingPrice,
            value: 0,
            maxWeight: maxWeight,
            nextBidWeight: nextBidWeight,
            totalBid: 0
        });

        nfts[tokenId].isAuction = true;
        nfts[tokenId].totalAuction += 1;
        nfts[tokenId].auctions[nfts[tokenId].totalAuction - 1] = auction;

        transferFrom(msg.sender, address(this), tokenId);
    }

    function bidAuction(uint256 tokenId, uint256 bidValue) public payable {
        require(
            nfts[tokenId].isAuction,
            "Error 5007: This NFT is not open an auction."
        );

        Governance g = Governance(governanceContract);
        ERC20 t = ERC20(g.getARATokenContract());
        NFTInfo storage nft = nfts[tokenId];
        uint32 auctionId = nft.totalAuction - 1;
        NFTAuction memory auction = nft.auctions[auctionId];

        require(
            auction.bidderAddr != msg.sender
                ? t.balanceOf(msg.sender) >= bidValue
                : t.balanceOf(msg.sender) >= bidValue - auction.value,
            "Error 5008: Insufficient fund to bid."
        );

        require(
            auction.totalBid == 0
                ? bidValue >= auction.startingPrice
                : bidValue >=
                    (auction.value * auction.nextBidWeight) /
                        auction.maxWeight +
                        auction.value,
            "Error 5009: Bid less than minimum price."
        );

        require(
            block.timestamp >= auction.closeAuctionTimestamp,
            "Error 5010: This auction is ending."
        );

        t.transferFrom(
            msg.sender,
            address(this),
            auction.bidderAddr != msg.sender
                ? bidValue
                : bidValue - auction.value
        );

        if (
            auction.bidderAddr != msg.sender &&
            auction.bidderAddr != address(0x0)
        ) {
            t.transferFrom(address(this), auction.bidderAddr, auction.value);
        }

        nft.bids[nft.bidId] = NFTAuctionBid({
            auctionId: auctionId,
            timestamp: block.timestamp,
            value: bidValue,
            bidder: msg.sender
        });

        nft.auctions[auctionId].bidderAddr = msg.sender;
        nft.auctions[auctionId].value = bidValue;
        nft.auctions[auctionId].totalBid += 1;
        nft.bidId += 1;
    }

    function processAuction(uint256 tokenId) public {
        Governance g = Governance(governanceContract);
        ERC20 t = ERC20(g.getARATokenContract());
        NFTInfo storage nft = nfts[tokenId];
        uint32 auctionId = nft.totalAuction - 1;
        NFTAuction memory auction = nft.auctions[auctionId];

        require(nft.isAuction, "Error 5012: This auction already close.");

        require(
            block.timestamp >= auction.closeAuctionTimestamp,
            "Error 5013: This auction is not end."
        );

        nft.isAuction = false;
        transferFrom(address(this), auction.bidderAddr, tokenId);
        // TODO: Add auction fee, custodian fee, royaltee fee, referral fee
        t.transferFrom(address(this), auction.ownerAddr, auction.value);
    }

    // TODO: Add buy it now options
}
