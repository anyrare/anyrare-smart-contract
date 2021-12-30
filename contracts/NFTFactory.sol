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

    struct NFTBuyItNow {
        uint256 value;
        address ownerAddr;
    }

    struct NFTInfo {
        bool exists;
        uint256 tokenId;
        bool isCustodianSign;
        bool isClaim;
        bool isLockInCollection;
        bool isAuction;
        bool isBuyItNow;
        NFTInfoAddress addr;
        NFTInfoFee fee;
        NFTBuyItNow buyItNow;
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

    function getManagementFundContract() private view returns (address) {
        return g().getManagementFundContract();
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
            isAuditor(msg.sender) &&
                isCustodian(custodianAddr) &&
                isMember(founderAddr),
            "50"
        );

        NFTInfoAddress memory addr = NFTInfoAddress({
            auditorAddr: msg.sender,
            custodianAddr: custodianAddr,
            founderAddr: founderAddr,
            ownerAddr: address(this)
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
        nfts[tokenId].isClaim = false;
        nfts[tokenId].isLockInCollection = false;
        nfts[tokenId].isAuction = false;
        nfts[tokenId].isBuyItNow = false;
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
        uint32 custodianFeeWeight,
        uint256 custodianRedeemFee
    ) public {
        require(
            nfts[tokenId].exists &&
                !nfts[tokenId].isCustodianSign &&
                msg.sender == nfts[tokenId].addr.custodianAddr,
            "51"
        );

        nfts[tokenId].isCustodianSign = true;
        nfts[tokenId].fee.custodianFeeWeight = custodianFeeWeight;
        nfts[tokenId].fee.custodianRedeemFee = custodianRedeemFee;
    }

    function payFeeAndClaimToken(uint256 tokenId) public payable {
        NFTInfo storage nft = nfts[tokenId];

        require(
            nft.exists &&
                nft.isCustodianSign &&
                !nft.isClaim &&
                nft.addr.founderAddr == msg.sender &&
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
            t().transfer(nft.addr.auditorAddr, nft.fee.auditFee);
        }

        if (nft.fee.mintFee > 0) {
            t().transfer(g().getManagementFundContract(), nft.fee.mintFee);
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
        uint256 platformFee = g()
            .getPolicy("OPEN_AUCTION_PLATFORM_FEE")
            .policyValue;
        uint256 referralFee = g()
            .getPolicy("OPEN_AUCTION_REFERRAL_FEE")
            .policyValue;

        require(
            ownerOf(tokenId) == msg.sender &&
                isMember(msg.sender) &&
                !nfts[tokenId].isAuction &&
                !nfts[tokenId].isBuyItNow &&
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
            ownerAddr: msg.sender,
            bidderAddr: address(0x0),
            startingPrice: startingPrice,
            value: 0,
            maxWeight: maxWeight,
            nextBidWeight: nextBidWeight,
            totalBid: 0
        });

        nfts[tokenId].isAuction = true;
        nfts[tokenId].auctions[nfts[tokenId].totalAuction] = auction;
        nfts[tokenId].totalAuction += 1;

        transferFrom(msg.sender, address(this), tokenId);
    }

    function bidAuction(uint256 tokenId, uint256 bidValue) public payable {
        NFTInfo storage nft = nfts[tokenId];
        uint32 auctionId = nft.totalAuction - 1;
        NFTAuction memory auction = nft.auctions[auctionId];
        require(
            (nfts[tokenId].isAuction) &&
                (isMember(msg.sender)) &&
                (
                    auction.bidderAddr != msg.sender
                        ? t().balanceOf(msg.sender) >= bidValue
                        : t().balanceOf(msg.sender) >= bidValue - auction.value
                ) &&
                (
                    auction.totalBid == 0
                        ? bidValue >= auction.startingPrice
                        : uint256(bidValue) >=
                            (uint256(auction.value) *
                                uint256(auction.nextBidWeight)) /
                                uint256(auction.maxWeight) +
                                uint256(auction.value)
                ) &&
                (block.timestamp < auction.closeAuctionTimestamp),
            "54"
        );

        t().transferFrom(
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
            t().transfer(auction.bidderAddr, auction.value);
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
        NFTInfo storage nft = nfts[tokenId];
        uint32 auctionId = nft.totalAuction - 1;
        NFTAuction memory auction = nft.auctions[auctionId];

        require(
            nft.isAuction && block.timestamp >= auction.closeAuctionTimestamp,
            "55"
        );

        nft.isAuction = false;

        if (auction.totalBid > 0) {
            uint256 founderRoyaltyFee = (auction.value *
                uint256(nft.fee.founderRoyaltyWeight)) /
                uint256(nft.fee.maxWeight);
            uint256 custodianFee = (auction.value *
                uint256(nft.fee.custodianFeeWeight)) /
                uint256(nft.fee.maxWeight);
            uint256 platformFee = (auction.value *
                uint256(
                    g().getPolicy("CLOSE_AUCTION_PLATFORM_FEE").policyWeight
                )) /
                uint256(g().getPolicy("CLOSE_AUCTION_PLATFORM_FEE").maxWeight);
            uint256 referralBuyerFee = (auction.value *
                uint256(
                    g()
                        .getPolicy("CLOSE_AUCTION_REFERRAL_BUYER_FEE")
                        .policyWeight
                )) /
                uint256(
                    g().getPolicy("CLOSE_AUCTION_REFERRAL_BUYER_FEE").maxWeight
                );
            uint256 referralSellerFee = (auction.value *
                uint256(
                    g()
                        .getPolicy("CLOSE_AUCTION_REFERRAL_SELLER_FEE")
                        .policyWeight
                )) /
                uint256(
                    g().getPolicy("CLOSE_AUCTION_REFERRAL_SELLER_FEE").maxWeight
                );

            if (founderRoyaltyFee > 0) {
                t().transfer(nft.addr.founderAddr, founderRoyaltyFee);
            }
            if (custodianFee > 0) {
                t().transfer(nft.addr.custodianAddr, custodianFee);
            }
            if (platformFee > 0) {
                t().transfer(getManagementFundContract(), platformFee);
            }
            if (referralBuyerFee > 0) {
                t().transfer(getReferral(auction.bidderAddr), referralBuyerFee);
            }
            if (referralSellerFee > 0) {
                t().transfer(getReferral(auction.ownerAddr), referralSellerFee);
            }

            t().transfer(
                auction.ownerAddr,
                auction.value -
                    founderRoyaltyFee -
                    custodianFee -
                    platformFee -
                    referralBuyerFee -
                    referralSellerFee
            );

            _transfer(address(this), auction.bidderAddr, tokenId);
        } else {
            _transfer(address(this), auction.ownerAddr, tokenId);
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
            .getPolicy("OPEN_BUY_IT_NOW_PLATFORM_FEE")
            .policyValue;
        uint256 referralFee = g()
            .getPolicy("OPEN_BUY_IT_NOW_REFERRAL_FEE")
            .policyValue;

        require(
            nfts[tokenId].exists &&
                !nfts[tokenId].isAuction &&
                !nfts[tokenId].isBuyItNow &&
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

        nfts[tokenId].isBuyItNow = true;
        nfts[tokenId].buyItNow.ownerAddr = msg.sender;
        nfts[tokenId].buyItNow.value = value;

        transferFrom(msg.sender, address(this), tokenId);
    }

    function changeBuyItNowPrice(uint256 tokenId, uint256 value) public {
        require(
            nfts[tokenId].exists &&
                nfts[tokenId].isBuyItNow &&
                nfts[tokenId].buyItNow.ownerAddr == msg.sender &&
                value > 0,
            "58."
        );

        nfts[tokenId].buyItNow.value = value;
    }

    function buyFromBuyItNow(uint256 tokenId) public payable {
        NFTInfo storage nft = nfts[tokenId];

        require(
            nft.exists &&
                nft.isBuyItNow &&
                t().balanceOf(msg.sender) >= nft.buyItNow.value &&
                isMember(msg.sender),
            "59"
        );

        nft.isBuyItNow = false;

        t().transferFrom(msg.sender, address(this), nft.buyItNow.value);

        uint256 founderRoyaltyFee = (nft.buyItNow.value *
            uint256(nft.fee.founderRoyaltyWeight)) / uint256(nft.fee.maxWeight);
        uint256 custodianFee = (nft.buyItNow.value *
            uint256(nft.fee.custodianFeeWeight)) / uint256(nft.fee.maxWeight);
        uint256 platformFee = (nft.buyItNow.value *
            uint256(g().getPolicy("BUY_IT_NOW_PLATFORM_FEE").policyWeight)) /
            uint256(g().getPolicy("BUY_IT_NOW_PLATFORM_FEE").maxWeight);
        uint256 referralBuyerFee = (nft.buyItNow.value *
            uint256(
                g().getPolicy("BUY_IT_NOW_REFERRAL_BUYER_FEE").policyWeight
            )) /
            uint256(g().getPolicy("BUY_IT_NOW_REFERRAL_BUYER_FEE").maxWeight);
        uint256 referralSellerFee = (nft.buyItNow.value *
            uint256(
                g().getPolicy("BUY_IT_NOW_REFERRAL_SELLER_FEE").policyWeight
            )) /
            uint256(g().getPolicy("BUY_IT_NOW_REFERRAL_SELLER_FEE").maxWeight);

        if (founderRoyaltyFee > 0) {
            t().transfer(nft.addr.founderAddr, founderRoyaltyFee);
        }
        if (custodianFee > 0) {
            t().transfer(nft.addr.custodianAddr, custodianFee);
        }
        if (platformFee > 0) {
            t().transfer(getManagementFundContract(), platformFee);
        }
        if (referralBuyerFee > 0) {
            t().transfer(getReferral(msg.sender), referralBuyerFee);
        }
        if (referralSellerFee > 0) {
            t().transfer(
                getReferral(nft.buyItNow.ownerAddr),
                referralSellerFee
            );
        }

        t().transfer(
            nft.buyItNow.ownerAddr,
            nft.buyItNow.value -
                founderRoyaltyFee -
                custodianFee -
                platformFee -
                referralBuyerFee -
                referralSellerFee
        );

        nft.buyItNow.ownerAddr = address(0x0);
        nft.buyItNow.value = 0;

        _transfer(address(this), msg.sender, tokenId);
    }

    function closeBuyItNow(uint256 tokenId) public {
        require(
            nfts[tokenId].exists &&
                nfts[tokenId].isBuyItNow &&
                nfts[tokenId].buyItNow.ownerAddr == msg.sender,
            "60"
        );

        nfts[tokenId].isBuyItNow = false;

        _transfer(address(this), nfts[tokenId].buyItNow.ownerAddr, tokenId);

        nfts[tokenId].buyItNow.ownerAddr = address(0x0);
        nfts[tokenId].buyItNow.value = 0;
    }
}
