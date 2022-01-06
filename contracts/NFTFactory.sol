pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./ARAToken.sol";
import "./Member.sol";
import "./Governance.sol";

contract NFTFactory is ERC721URIStorage {
    struct NFTStatus {
        bool custodianSign;
        bool claim;
        bool lockInCollection;
        bool auction;
        bool buyItNow;
        bool offer;
    }

    struct NFTInfoAddress {
        address auditor;
        address custodian;
        address founder;
        address owner;
    }

    struct NFTInfoFee {
        uint256 maxWeight;
        uint256 founderRoyaltyWeight;
        uint256 custodianFeeWeight;
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
        bool autoRebid;
    }

    struct NFTAuction {
        uint256 openAuctionTimestamp;
        uint256 closeAuctionTimestamp;
        address owner;
        address bidder;
        uint256 startingPrice;
        uint256 reservePrice;
        uint256 value;
        uint256 maxBid;
        uint256 maxWeight;
        uint256 nextBidWeight;
        uint32 totalBid;
    }

    struct NFTBuyItNow {
        uint256 value;
        address owner;
    }

    struct NFTOffer {
        uint8 status;
        uint256 value;
        address owner;
        address bidder;
        uint256 openOfferTimestamp;
        uint256 closeOfferTimestamp;
    }

    struct NFTOfferBid {
        uint256 value;
        address bidder;
        uint256 timestamp;
    }

    struct NFTInfo {
        bool exists;
        uint256 tokenId;
        NFTStatus status;
        NFTInfoAddress addr;
        NFTInfoFee fee;
        NFTBuyItNow buyItNow;
        NFTOffer offer;
        uint32 totalAuction;
        uint32 offerId;
        uint32 bidId;
        uint256 currentValue;
        mapping(uint32 => NFTAuction) auctions;
        mapping(uint32 => NFTAuctionBid) bids;
        mapping(uint32 => NFTOfferBid) offerBids;
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

    function g() private view returns (Governance) {
        return Governance(governanceContract);
    }

    function m() private view returns (Member) {
        return Member(g().getMemberContract());
    }

    function t() private view returns (ERC20) {
        return ERC20(g().getARATokenContract());
    }

    function isMember(address account) private view returns (bool) {
        return m().isMember(account);
    }

    function isAuditor(address account) private view returns (bool) {
        return g().isAuditor(account);
    }

    function isCustodian(address account) private view returns (bool) {
        return g().isCustodian(account);
    }

    function getReferral(address account) private view returns (address) {
        return m().getReferral(account);
    }

    function maybeTransferToken(
        address sender,
        address receiver,
        uint256 value
    ) private {
        require(t().balanceOf(sender) >= value, "31");

        if (value > 0) {
            t().transferFrom(sender, receiver, value);
        }
    }

    function calculateFeeFromPolicy(string memory policyName, uint256 value)
        private
        returns (uint256)
    {
        return
            (value * g().getPolicy(policyName).policyWeight) /
            g().getPolicy(policyName).maxWeight;
    }

    function getManagementFundContract() private view returns (address) {
        return g().getManagementFundContract();
    }

    function max(uint256 x, uint256 y) private view returns (uint256) {
        return x > y ? x : y;
    }

    function min(uint256 x, uint256 y) private view returns (uint256) {
        return x < y ? x : y;
    }

    function mint(
        address founder,
        address custodian,
        string memory tokenURI,
        uint256 maxWeight,
        uint256 founderRoyaltyWeight,
        uint256 founderRedeemFee,
        uint256 auditFee
    ) public returns (uint256) {
        require(
            isAuditor(msg.sender) &&
                isCustodian(custodian) &&
                isMember(founder),
            "50"
        );

        NFTInfoAddress memory addr = NFTInfoAddress({
            auditor: msg.sender,
            custodian: custodian,
            founder: founder,
            owner: address(this)
        });

        NFTInfoFee memory fee = NFTInfoFee({
            maxWeight: maxWeight,
            founderRoyaltyWeight: founderRoyaltyWeight,
            founderRedeemFee: founderRedeemFee,
            custodianFeeWeight: 0,
            custodianRedeemFee: 0,
            auditFee: auditFee,
            mintFee: g().getPolicy("NFT_MINT_FEE").policyValue
        });

        uint256 tokenId = currentTokenId;

        nfts[tokenId].exists = true;
        nfts[tokenId].tokenId = tokenId;
        nfts[tokenId].status.claim = false;
        nfts[tokenId].status.lockInCollection = false;
        nfts[tokenId].status.auction = false;
        nfts[tokenId].status.buyItNow = false;
        nfts[tokenId].addr = addr;
        nfts[tokenId].fee = fee;
        nfts[tokenId].totalAuction = 0;
        nfts[tokenId].bidId = 0;

        _mint(address(this), tokenId);
        _setTokenURI(tokenId, tokenURI);

        currentTokenId += 1;

        return tokenId;
    }

    function custodianSign(
        uint256 tokenId,
        uint256 custodianFeeWeight,
        uint256 custodianRedeemFee
    ) public {
        require(
            nfts[tokenId].exists &&
                !nfts[tokenId].status.custodianSign &&
                msg.sender == nfts[tokenId].addr.custodian,
            "51"
        );

        nfts[tokenId].status.custodianSign = true;
        nfts[tokenId].fee.custodianFeeWeight = custodianFeeWeight;
        nfts[tokenId].fee.custodianRedeemFee = custodianRedeemFee;
    }

    function payFeeAndClaimToken(uint256 tokenId) public payable {
        NFTInfo storage nft = nfts[tokenId];

        require(
            nft.exists &&
                nft.status.custodianSign &&
                !nft.status.claim &&
                (nft.addr.founder == msg.sender ||
                    (nft.addr.custodian == msg.sender &&
                        block.timestamp >=
                        g()
                            .getPolicy("NFT_CUSTODIAN_CAN_CLAIM_DURATION")
                            .policyValue)) &&
                t().balanceOf(msg.sender) >= nft.fee.auditFee + nft.fee.mintFee,
            "52"
        );

        if (nft.fee.auditFee + nft.fee.mintFee > 0) {
            t().transferFrom(
                msg.sender,
                address(this),
                nft.fee.auditFee + nft.fee.mintFee
            );
        }

        if (nft.fee.auditFee > 0) {
            t().transfer(nft.addr.auditor, nft.fee.auditFee);
        }

        if (nft.fee.mintFee > 0) {
            t().transfer(g().getManagementFundContract(), nft.fee.mintFee);
        }

        _transfer(address(this), msg.sender, tokenId);

        nfts[tokenId].status.claim = true;
    }

    function openAuction(
        uint256 tokenId,
        uint256 closeAuctionPeriodSecond,
        uint256 startingPrice,
        uint256 reservePrice,
        uint256 maxWeight,
        uint256 nextBidWeight
    ) public payable {
        uint256 platformFee = g()
            .getPolicy("OPEN_AUCTION_NFT_PLATFORM_FEE")
            .policyValue;
        uint256 referralFee = g()
            .getPolicy("OPEN_AUCTION_NFT_REFERRAL_FEE")
            .policyValue;

        require(
            ownerOf(tokenId) == msg.sender &&
                isMember(msg.sender) &&
                !nfts[tokenId].status.auction &&
                !nfts[tokenId].status.buyItNow &&
                !nfts[tokenId].status.offer &&
                t().balanceOf(msg.sender) >= platformFee + referralFee,
            "53"
        );

        if (platformFee > 0) {
            t().transferFrom(
                msg.sender,
                g().getManagementFundContract(),
                platformFee
            );
        }
        if (referralFee > 0) {
            t().transferFrom(msg.sender, getReferral(msg.sender), referralFee);
        }

        NFTAuction memory auction = NFTAuction({
            openAuctionTimestamp: block.timestamp,
            closeAuctionTimestamp: block.timestamp + closeAuctionPeriodSecond,
            owner: msg.sender,
            bidder: address(0x0),
            startingPrice: startingPrice,
            reservePrice: reservePrice,
            value: 0,
            maxBid: 0,
            maxWeight: maxWeight,
            nextBidWeight: nextBidWeight,
            totalBid: 0
        });

        nfts[tokenId].status.auction = true;
        nfts[tokenId].auctions[nfts[tokenId].totalAuction] = auction;
        nfts[tokenId].totalAuction += 1;

        transferFrom(msg.sender, address(this), tokenId);
    }

    function bidAuction(
        uint256 tokenId,
        uint256 bidValue,
        uint256 maxBid
    ) public payable {
        NFTInfo storage nft = nfts[tokenId];
        uint32 auctionId = nft.totalAuction - 1;
        NFTAuction memory auction = nft.auctions[auctionId];
        require(
            (nfts[tokenId].status.auction) &&
                (isMember(msg.sender)) &&
                (
                    auction.bidder != msg.sender
                        ? t().balanceOf(msg.sender) >= maxBid
                        : t().balanceOf(msg.sender) >= maxBid - auction.value
                ) &&
                (
                    auction.totalBid == 0
                        ? bidValue >= auction.startingPrice
                        : bidValue >=
                            (auction.value * auction.nextBidWeight) /
                                auction.maxWeight +
                                auction.value
                ) &&
                bidValue <= maxBid &&
                (block.timestamp < auction.closeAuctionTimestamp),
            "54"
        );

        nft.bids[nft.bidId] = NFTAuctionBid({
            auctionId: auctionId,
            timestamp: block.timestamp,
            value: bidValue,
            bidder: msg.sender,
            autoRebid: false
        });
        nft.bidId += 1;
        auction.totalBid += 1;

        if (
            auction.reservePrice > 0 &&
            auction.value < auction.reservePrice &&
            maxBid >= auction.reservePrice
        ) {
            auction.closeAuctionTimestamp =
                block.timestamp +
                g()
                    .getPolicy("MEET_RESERVE_PRICE_AUCTION_NFT_TIME_LEFT")
                    .policyValue;

            if (bidValue < auction.reservePrice) {
                bidValue += auction.reservePrice - bidValue;
                nft.bids[nft.bidId] = NFTAuctionBid({
                    auctionId: auctionId,
                    timestamp: block.timestamp,
                    value: bidValue,
                    bidder: msg.sender,
                    autoRebid: false
                });
                nft.bidId += 1;
                auction.totalBid += 1;
            }
        }

        require(bidValue >= auction.reservePrice, "55");

        if (maxBid <= auction.maxBid) {
            nft.bids[nft.bidId] = NFTAuctionBid({
                auctionId: auctionId,
                timestamp: block.timestamp,
                value: maxBid,
                bidder: auction.bidder,
                autoRebid: true
            });
            nft.bidId += 1;
            auction.value = maxBid;
            auction.totalBid += 1;
        } else {
            auction.bidder = msg.sender;
            auction.value = bidValue;

            t().transferFrom(
                msg.sender,
                address(this),
                auction.bidder != msg.sender ? maxBid : maxBid - auction.value
            );

            if (
                auction.bidder != msg.sender && auction.bidder != address(0x0)
            ) {
                t().transfer(auction.bidder, auction.maxBid);
            }

            auction.maxBid = maxBid;
        }

        if (
            auction.closeAuctionTimestamp - block.timestamp <=
            g().getPolicy("EXTENDED_AUCTION_NFT_TIME_TRIGGER").policyValue
        ) {
            auction.closeAuctionTimestamp =
                block.timestamp +
                g().getPolicy("EXTENDED_AUCTION_NFT_DURATION").policyValue;
        }
    }

    function processAuction(uint256 tokenId) public {
        NFTInfo storage nft = nfts[tokenId];
        uint32 auctionId = nft.totalAuction - 1;
        NFTAuction memory auction = nft.auctions[auctionId];

        require(
            nft.status.auction &&
                block.timestamp >= auction.closeAuctionTimestamp,
            "55"
        );

        nft.status.auction = false;

        require(auction.value >= auction.reservePrice, "55");

        if (auction.totalBid > 0) {
            nft.currentValue = auction.value;

            uint256 founderRoyaltyFee = (auction.value *
                nft.fee.founderRoyaltyWeight) / nft.fee.maxWeight;
            uint256 custodianFee = (auction.value *
                nft.fee.custodianFeeWeight) / nft.fee.maxWeight;
            uint256 platformFee = calculateFeeFromPolicy(
                auction.value,
                "CLOSE_AUCTION_NFT_PLATFORM_FEE"
            );
            uint256 referralBuyerFee = calculateFeeFromPolicy(
                auction.value,
                "CLOSE_AUCTION_NFT_REFERRAL_BUYER_FEE"
            );
            uint256 referralSellerFee = calculateFeeFromPolicy(
                auction.value,
                "CLOSE_AUCTION_NFT_REFERRAL_SELLER_FEE"
            );

            maybeTransferToken(
                address(this),
                nft.addr.founder,
                founderRoyaltyFee
            );
            maybeTransferToken(address(this), nft.addr.custodian, custodianFee);
            maybeTransferToken(
                address(this),
                getManagementFundContract(),
                platformFee
            );
            maybeTransferToken(
                address(this),
                getReferral(auction.bidder),
                referralBuyerFee
            );
            maybeTransferToken(
                address(this),
                getReferral(auction.owner),
                referralSellerFee
            );

            maybeTransferToken(
                address(this),
                auction.owner,
                auction.value -
                    founderRoyaltyFee -
                    custodianFee -
                    platformFee -
                    referralBuyerFee -
                    referralSellerFee
            );

            _transfer(address(this), auction.bidder, tokenId);

            maybeTransferToken(address(this), auction.bidder, auction.maxBid - auction.value)
        } else {
            _transfer(address(this), auction.owner, tokenId);
        }
    }

    function getNFTAuction(uint256 tokenId)
        public
        view
        returns (NFTAuction memory auction)
    {
        require(nfts[tokenId].totalAuction > 0, "56");

        return nfts[tokenId].auctions[nfts[tokenId].totalAuction - 1];
    }

    function openBuyItNow(uint256 tokenId, uint256 value) public {
        uint256 platformFee = g()
            .getPolicy("OPEN_BUY_IT_NOW_NFT_PLATFORM_FEE")
            .policyValue;
        uint256 referralFee = g()
            .getPolicy("OPEN_BUY_IT_NOW_NFT_REFERRAL_FEE")
            .policyValue;

        require(
            nfts[tokenId].exists &&
                !nfts[tokenId].status.auction &&
                !nfts[tokenId].status.buyItNow &&
                ownerOf(tokenId) == msg.sender &&
                isMember(msg.sender) &&
                value > 0 &&
                t().balanceOf(msg.sender) >= platformFee + referralFee,
            "57"
        );

        if (platformFee > 0) {
            t().transferFrom(
                msg.sender,
                g().getManagementFundContract(),
                platformFee
            );
        }
        if (referralFee > 0) {
            t().transferFrom(msg.sender, getReferral(msg.sender), referralFee);
        }

        nfts[tokenId].status.buyItNow = true;
        nfts[tokenId].buyItNow.owner = msg.sender;
        nfts[tokenId].buyItNow.value = value;

        transferFrom(msg.sender, address(this), tokenId);
    }

    function changeBuyItNowPrice(uint256 tokenId, uint256 value) public {
        require(
            nfts[tokenId].exists &&
                nfts[tokenId].status.buyItNow &&
                nfts[tokenId].buyItNow.owner == msg.sender &&
                value > 0,
            "58."
        );

        nfts[tokenId].buyItNow.value = value;
    }

    function buyFromBuyItNow(uint256 tokenId) public payable {
        NFTInfo storage nft = nfts[tokenId];

        require(
            nft.exists &&
                nft.status.buyItNow &&
                t().balanceOf(msg.sender) >= nft.buyItNow.value &&
                isMember(msg.sender),
            "59"
        );

        nft.status.buyItNow = false;

        t().transferFrom(msg.sender, address(this), nft.buyItNow.value);

        uint256 founderRoyaltyFee = (nft.buyItNow.value *
            nft.fee.founderRoyaltyWeight) / nft.fee.maxWeight;
        uint256 custodianFee = (nft.buyItNow.value *
            nft.fee.custodianFeeWeight) / nft.fee.maxWeight;
        uint256 platformFee = (nft.buyItNow.value *
            g().getPolicy("BUY_IT_NOW_NFT_PLATFORM_FEE").policyWeight) /
            g().getPolicy("BUY_IT_NOW_NFT_PLATFORM_FEE").maxWeight;
        uint256 referralBuyerFee = (nft.buyItNow.value *
            g().getPolicy("BUY_IT_NOW_NFT_REFERRAL_BUYER_FEE").policyWeight) /
            g().getPolicy("BUY_IT_NOW_NFT_REFERRAL_BUYER_FEE").maxWeight;
        uint256 referralSellerFee = (nft.buyItNow.value *
            g().getPolicy("BUY_IT_NOW_NFT_REFERRAL_SELLER_FEE").policyWeight) /
            g().getPolicy("BUY_IT_NOW_NFT_REFERRAL_SELLER_FEE").maxWeight;

        if (founderRoyaltyFee > 0) {
            t().transfer(nft.addr.founder, founderRoyaltyFee);
        }
        if (custodianFee > 0) {
            t().transfer(nft.addr.custodian, custodianFee);
        }
        if (platformFee > 0) {
            t().transfer(getManagementFundContract(), platformFee);
        }
        if (referralBuyerFee > 0) {
            t().transfer(getReferral(msg.sender), referralBuyerFee);
        }
        if (referralSellerFee > 0) {
            t().transfer(getReferral(nft.buyItNow.owner), referralSellerFee);
        }

        t().transfer(
            nft.buyItNow.owner,
            nft.buyItNow.value -
                founderRoyaltyFee -
                custodianFee -
                platformFee -
                referralBuyerFee -
                referralSellerFee
        );

        nft.currentValue = nft.buyItNow.value;
        nft.buyItNow.owner = address(0x0);
        nft.buyItNow.value = 0;

        _transfer(address(this), msg.sender, tokenId);
    }

    function closeBuyItNow(uint256 tokenId) public {
        require(
            nfts[tokenId].exists &&
                nfts[tokenId].status.buyItNow &&
                nfts[tokenId].buyItNow.owner == msg.sender,
            "60"
        );

        nfts[tokenId].status.buyItNow = false;

        _transfer(address(this), nfts[tokenId].buyItNow.owner, tokenId);

        nfts[tokenId].buyItNow.owner = address(0x0);
        nfts[tokenId].buyItNow.value = 0;
    }

    function openOffer(uint256 bidValue, uint256 tokenId) public {
        NFTInfo storage nft = nfts[tokenId];

        require(
            nft.exists &&
                nft.status.claim &&
                !nft.status.auction &&
                (bidValue > nfts[tokenId].offer.value) &&
                t().balanceOf(msg.sender) >=
                (
                    msg.sender == nft.offer.bidder
                        ? bidValue - nft.offer.value
                        : bidValue
                ) &&
                isMember(msg.sender),
            "61"
        );

        t().transferFrom(
            msg.sender,
            address(this),
            msg.sender == nft.offer.bidder
                ? bidValue - nft.offer.value
                : bidValue
        );

        if (nft.status.offer && nft.offer.bidder != msg.sender) {
            t().transferFrom(address(this), nft.offer.bidder, nft.offer.value);
        }

        nft.offerBids[nft.offerId].value = bidValue;
        nft.offerBids[nft.offerId].bidder = msg.sender;
        nft.offerBids[nft.offerId].timestamp = block.timestamp;
        nft.offer.status = 1;
        nft.offer.value = bidValue;
        nft.offer.owner = ownerOf(tokenId);
        nft.offer.bidder = msg.sender;
        nft.offer.openOfferTimestamp = block.timestamp;
        nft.offer.closeOfferTimestamp =
            block.timestamp +
            g().getPolicy("OFFER_PRICE_NFT_DURATION").policyValue;
        nft.status.offer = true;
        nft.offerId += 1;
    }

    function acceptOffer(uint256 tokenId) public {
        NFTInfo storage nft = nfts[tokenId];

        require(
            nft.exists && nft.status.offer && ownerOf(tokenId) == msg.sender,
            "62"
        );

        nft.status.offer = false;

        uint256 founderRoyaltyFee = (nft.offer.value *
            nft.fee.founderRoyaltyWeight) / nft.fee.maxWeight;
        uint256 custodianFee = (nft.offer.value * nft.fee.custodianFeeWeight) /
            nft.fee.maxWeight;
        uint256 platformFee = (nft.offer.value *
            g().getPolicy("OFFER_NFT_PLATFORM_FEE").policyWeight) /
            g().getPolicy("OFFER_NFT_PLATFORM_FEE").maxWeight;
        uint256 referralBuyerFee = (nft.offer.value *
            g().getPolicy("OFFER_NFT_REFERRAL_BUYER_FEE").policyWeight) /
            g().getPolicy("OFFER_NFT_REFERRAL_BUYER_FEE").maxWeight;
        uint256 referralSellerFee = (nft.offer.value *
            g().getPolicy("OFFER_NFT_REFERRAL_SELLER_FEE").policyWeight) /
            g().getPolicy("OFFER_NFT_REFERRAL_SELLER_FEE").maxWeight;

        if (founderRoyaltyFee > 0) {
            t().transfer(nft.addr.founder, founderRoyaltyFee);
        }
        if (custodianFee > 0) {
            t().transfer(nft.addr.custodian, custodianFee);
        }
        if (platformFee > 0) {
            t().transfer(getManagementFundContract(), platformFee);
        }
        if (referralBuyerFee > 0) {
            t().transfer(getReferral(nft.offer.bidder), referralBuyerFee);
        }
        if (referralSellerFee > 0) {
            t().transfer(getReferral(nft.offer.owner), referralSellerFee);
        }

        t().transfer(
            nft.offer.owner,
            nft.offer.value -
                founderRoyaltyFee -
                custodianFee -
                platformFee -
                referralBuyerFee -
                referralSellerFee
        );

        _transfer(msg.sender, nft.offer.bidder, tokenId);

        nft.offer.status = 2;
        nft.offer.value = 0;
        nft.offer.owner = address(0x0);
        nft.offer.bidder = address(0x0);
    }

    function revertOffer(uint256 tokenId) public {
        NFTInfo storage nft = nfts[tokenId];

        require(
            nft.exists &&
                nft.status.offer &&
                (block.timestamp >= nft.offer.closeOfferTimestamp ||
                    (ownerOf(tokenId) == msg.sender)),
            "62"
        );

        nft.status.offer = false;
        nft.offer.status = 0;
        nft.offer.value = 0;
        nft.offer.owner = address(0x0);
        nft.offer.bidder = address(0x0);

        t().transfer(nft.offer.bidder, nft.offer.value);
    }

    // function transferFrom() public {}
    // function transfer() public {}
}
