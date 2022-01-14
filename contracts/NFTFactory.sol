pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./ARAToken.sol";
import "./Governance.sol";
import "./NFTUtils.sol";
import "./NFTDataType.sol";
import "./Member.sol";

contract NFTFactory is ERC721URIStorage, NFTDataType {
    mapping(uint256 => NFT) public nfts;

    address private governanceContract;
    uint256 private currentTokenId;

    constructor(
        address _governanceContract,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        governanceContract = _governanceContract;
    }

    function g() private view returns (Governance) {
        return Governance(governanceContract);
    }

    function m() public view returns (Member) {
        return Member(g().getMemberContract());
    }

    function t() public view returns (ARAToken) {
        return ARAToken(g().getARATokenContract());
    }

    function nu() private view returns (NFTUtils) {
        return NFTUtils(g().getNFTUtilsContract());
    }

    function getCurrentTokenId() public view returns (uint256) {
        return currentTokenId - 1;
    }

    function mint(
        address founder,
        address custodian,
        string memory tokenURI,
        uint256 maxWeight,
        uint256 founderWeight,
        uint256 founderRedeemWeight,
        uint256 founderGeneralFee,
        uint256 auditFee
    ) public {
        require(
            g().isAuditor(msg.sender) &&
                g().isCustodian(custodian) &&
                m().isMember(founder)
        );

        NFTAddress memory addr = NFTAddress({
            auditor: msg.sender,
            custodian: custodian,
            founder: founder,
            owner: founder
        });

        NFTFee memory fee = NFTFee({
            maxWeight: maxWeight,
            founderWeight: founderWeight,
            founderGeneralFee: founderGeneralFee,
            founderRedeemWeight: founderRedeemWeight,
            custodianWeight: 0,
            custodianGeneralFee: 0,
            custodianRedeemWeight: 0,
            auditFee: auditFee,
            mintFee: g().getPolicy("NFT_MINT_FEE").policyValue
        });

        nfts[currentTokenId].info.exists = true;
        nfts[currentTokenId].info.tokenId = currentTokenId;
        nfts[currentTokenId].info.addr = addr;
        nfts[currentTokenId].info.fee = fee;

        _mint(address(this), currentTokenId);
        _setTokenURI(currentTokenId, tokenURI);

        currentTokenId += 1;
    }

    function custodianSign(
        uint256 tokenId,
        uint256 custodianWeight,
        uint256 custodianGeneralFee,
        uint256 custodianRedeemWeight
    ) public {
        nu().requireCustodianSign(nfts[tokenId].info, msg.sender);

        nfts[tokenId].info.status.custodianSign = true;
        nfts[tokenId].info.fee.custodianWeight = custodianWeight;
        nfts[tokenId].info.fee.custodianGeneralFee = custodianGeneralFee;
        nfts[tokenId].info.fee.custodianRedeemWeight = custodianRedeemWeight;
    }

    function payFeeAndClaimToken(uint256 tokenId) public payable {
        NFTInfo storage info = nfts[tokenId].info;

        nu().requirePayFeeAndClaimToken(info, msg.sender);

        t().transferFrom(
            msg.sender,
            address(this),
            info.fee.auditFee + info.fee.mintFee
        );

        transferARAFromContract(
            nu().calculatePayFeeAndClaimTokenFeeLists(info),
            3
        );

        _transfer(address(this), msg.sender, tokenId);

        info.status.claim = true;
    }

    function transferOpenFee(
        string memory policyPlatform,
        string memory policyReferral
    ) private {
        uint256 platformFee = g().getPolicy(policyPlatform).policyValue;
        uint256 referralFee = g().getPolicy(policyReferral).policyValue;
        require(t().balanceOf(msg.sender) >= platformFee + referralFee);

        t().transferFrom(msg.sender, address(this), platformFee + referralFee);

        TransferARA[] memory feeLists = new TransferARA[](2);
        feeLists[0] = TransferARA({
            receiver: g().getManagementFundContract(),
            amount: platformFee
        });
        feeLists[1] = TransferARA({
            receiver: m().getReferral(msg.sender),
            amount: referralFee
        });

        transferARAFromContract(feeLists, 2);
    }

    function transferARAFromContract(TransferARA[] memory lists, uint8 length)
        private
    {
        for (uint8 i = 0; i < length; i++) {
            if (lists[i].amount > 0) {
                t().transfer(
                    lists[i].receiver,
                    nu().min(lists[i].amount, t().balanceOf(address(this)))
                );
            }
        }
    }

    function getAuctionByAuctionId(uint256 tokenId, uint32 auctionId)
        public
        view
        returns (NFTAuction memory a)
    {
        NFTAuction memory auction = nfts[tokenId].auctions[auctionId];
        if (
            auction.value < auction.reservePrice &&
            nfts[tokenId].info.status.auction
        ) {
            auction.reservePrice = 0;
        }
        if (nfts[tokenId].info.status.auction) {
            auction.maxBid = 0;
        }
        return auction;
    }

    function getAuction(uint256 tokenId)
        public
        view
        returns (NFTAuction memory a)
    {
        return
            getAuctionByAuctionId(tokenId, nfts[tokenId].info.totalAuction - 1);
    }

    function getAuctionBid(uint256 tokenId, uint32 bidId)
        public
        view
        returns (NFTAuctionBid memory bid)
    {
        return nfts[tokenId].bids[bidId];
    }

    function getOfferBid(uint256 tokenId, uint32 offerId)
        public
        view
        returns (NFTOfferBid memory bid)
    {
        return nfts[tokenId].offerBids[offerId];
    }

    function openAuction(
        uint256 tokenId,
        uint256 closeAuctionPeriodSecond,
        uint256 startingPrice,
        uint256 reservePrice,
        uint256 maxWeight,
        uint256 nextBidWeight
    ) public payable {
        nu().requireOpenAuction(
            ownerOf(tokenId) == msg.sender,
            nfts[tokenId].info.status,
            msg.sender
        );

        transferOpenFee(
            "OPEN_AUCTION_NFT_PLATFORM_FEE",
            "OPEN_AUCTION_NFT_REFERRAL_FEE"
        );

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
            totalBid: 0,
            meetReservePrice: false
        });

        nfts[tokenId].info.status.auction = true;
        nfts[tokenId].auctions[nfts[tokenId].info.totalAuction] = auction;
        nfts[tokenId].info.totalAuction += 1;

        _transfer(msg.sender, address(this), tokenId);
    }

    function bidAuction(
        uint256 tokenId,
        uint256 bidValue,
        uint256 maxBid
    ) public payable {
        NFTInfo storage info = nfts[tokenId].info;
        NFTAuction storage auction = nfts[tokenId].auctions[
            info.totalAuction - 1
        ];
        uint256 minBidValue = (auction.value * auction.nextBidWeight) /
            auction.maxWeight +
            auction.value;

        nu().requireBidAuction(
            nfts[tokenId].info.status,
            auction,
            msg.sender,
            bidValue,
            maxBid,
            minBidValue
        );

        if (bidValue < auction.reservePrice && maxBid >= auction.reservePrice) {
            bidValue = auction.reservePrice;
        }

        if (bidValue < minBidValue && maxBid >= minBidValue) {
            bidValue = minBidValue;
        }

        nfts[tokenId].bids[info.bidId] = NFTAuctionBid({
            auctionId: info.totalAuction - 1,
            timestamp: block.timestamp,
            value: maxBid >= auction.reservePrice ? bidValue : maxBid,
            meetReservePrice: maxBid >= auction.reservePrice,
            bidder: msg.sender,
            autoRebid: false
        });

        info.bidId += 1;
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
        }

        if (maxBid <= auction.maxBid) {
            nfts[tokenId].bids[info.bidId] = NFTAuctionBid({
                auctionId: info.totalAuction - 1,
                timestamp: block.timestamp,
                value: maxBid,
                meetReservePrice: maxBid >= auction.reservePrice,
                bidder: auction.bidder,
                autoRebid: true
            });
            info.bidId += 1;
            auction.value = maxBid;
            auction.totalBid += 1;
        } else if (maxBid >= auction.reservePrice) {
            t().transferFrom(
                msg.sender,
                address(this),
                auction.bidder != msg.sender
                    ? maxBid
                    : maxBid - (auction.meetReservePrice ? auction.maxBid : 0)
            );

            if (
                auction.bidder != msg.sender &&
                auction.bidder != address(0x0) &&
                auction.meetReservePrice
            ) {
                t().transfer(auction.bidder, auction.maxBid);
            }

            auction.bidder = msg.sender;
            auction.value = bidValue;
            auction.maxBid = maxBid;
        } else {
            auction.bidder = msg.sender;
            auction.value = maxBid;
            auction.maxBid = maxBid;
        }

        auction.meetReservePrice = auction.value >= auction.reservePrice;

        if (
            auction.closeAuctionTimestamp <=
            block.timestamp +
                g().getPolicy("EXTENDED_AUCTION_NFT_TIME_TRIGGER").policyValue
        ) {
            auction.closeAuctionTimestamp =
                block.timestamp +
                g().getPolicy("EXTENDED_AUCTION_NFT_DURATION").policyValue;
        }
    }

    function processAuction(uint256 tokenId) public {
        NFTInfo storage info = nfts[tokenId].info;
        NFTAuction memory auction = nfts[tokenId].auctions[
            info.totalAuction - 1
        ];

        require(
            info.status.auction &&
                block.timestamp >= auction.closeAuctionTimestamp
        );

        info.status.auction = false;

        if (auction.totalBid > 0 && auction.value >= auction.reservePrice) {
            transferARAFromContract(
                nu().calculateAuctionTransferFeeLists(info, auction),
                9
            );
            _transfer(address(this), auction.bidder, tokenId);

            info.addr.owner = auction.bidder;
        } else {
            _transfer(address(this), auction.owner, tokenId);
        }
    }

    function openBuyItNow(uint256 tokenId, uint256 value) public {
        nu().requireOpenBuyItNow(
            nfts[tokenId].info,
            ownerOf(tokenId) == msg.sender,
            msg.sender,
            value,
            g().getPolicy("OPEN_BUY_IT_NOW_NFT_PLATFORM_FEE").policyValue,
            g().getPolicy("OPEN_BUY_IT_NOW_NFT_REFERRAL_FEE").policyValue
        );

        transferOpenFee(
            "OPEN_BUY_IT_NOW_NFT_PLATFORM_FEE",
            "OPEN_BUY_IT_NOW_NFT_REFERRAL_FEE"
        );

        nfts[tokenId].info.status.buyItNow = true;
        nfts[tokenId].info.buyItNow.owner = msg.sender;
        nfts[tokenId].info.buyItNow.value = value;

        _transfer(msg.sender, address(this), tokenId);
    }

    function changeBuyItNowPrice(uint256 tokenId, uint256 value) public {
        nu().requireChangeBuyItNowPrice(nfts[tokenId].info, msg.sender, value);
        nfts[tokenId].info.buyItNow.value = value;
    }

    function buyFromBuyItNow(uint256 tokenId) public payable {
        NFTInfo storage info = nfts[tokenId].info;

        info.status.buyItNow = false;

        t().transferFrom(msg.sender, address(this), info.buyItNow.value);

        transferARAFromContract(
            nu().calculateBuyItNowTransferFeeLists(info, msg.sender),
            8
        );

        info.addr.owner = msg.sender;

        _transfer(address(this), msg.sender, tokenId);
    }

    function closeBuyItNow(uint256 tokenId) public {
        nu().requireCloseBuyItNow(nfts[tokenId].info, msg.sender);
        nfts[tokenId].info.status.buyItNow = false;

        _transfer(address(this), nfts[tokenId].info.buyItNow.owner, tokenId);
    }

    function openOffer(uint256 bidValue, uint256 tokenId) public {
        NFTInfo storage info = nfts[tokenId].info;

        nu().requireOpenOffer(
            ownerOf(tokenId) == msg.sender,
            info,
            bidValue,
            msg.sender
        );

        t().transferFrom(
            msg.sender,
            address(this),
            msg.sender == info.offer.bidder && info.status.offer
                ? bidValue - info.offer.value
                : bidValue
        );

        if (info.status.offer && info.offer.bidder != msg.sender) {
            t().transfer(info.offer.bidder, info.offer.value);
        }

        nfts[tokenId].offerBids[info.offerId].value = bidValue;
        nfts[tokenId].offerBids[info.offerId].bidder = msg.sender;
        nfts[tokenId].offerBids[info.offerId].timestamp = block.timestamp;
        info.offer.value = bidValue;
        info.offer.owner = ownerOf(tokenId);
        info.offer.bidder = msg.sender;
        info.offer.openOfferTimestamp = block.timestamp;
        info.offer.closeOfferTimestamp =
            block.timestamp +
            g().getPolicy("OFFER_PRICE_NFT_DURATION").policyValue;
        info.status.offer = true;
        info.offerId += 1;
    }

    function acceptOffer(uint256 tokenId) public {
        NFTInfo storage info = nfts[tokenId].info;

        require(
            info.exists && info.status.offer && ownerOf(tokenId) == msg.sender
        );

        info.status.offer = false;

        transferARAFromContract(nu().calculateOfferTransferFeeLists(info), 8);

        _transfer(msg.sender, info.offer.bidder, tokenId);

        info.addr.owner = info.offer.bidder;
    }

    function revertOffer(uint256 tokenId) public {
        nu().requireRevertOffer(
            nfts[tokenId].info,
            ownerOf(tokenId) == msg.sender,
            msg.sender
        );
        t().transfer(
            nfts[tokenId].info.offer.bidder,
            nfts[tokenId].info.offer.value
        );

        nfts[tokenId].info.status.offer = false;
    }

    function redeem(uint256 tokenId) public payable {
        NFTInfo storage info = nfts[tokenId].info;
        nu().requireRedeem(info, ownerOf(tokenId) == msg.sender);
        t().transferFrom(
            msg.sender,
            address(this),
            nu().calculateRedeemFee(
                info,
                info.totalAuction > 0
                    ? nfts[tokenId].auctions[info.totalAuction - 1].value
                    : 0
            )
        );

        info.redeemTimestamp = block.timestamp;
        info.status.redeem = true;
        _transfer(msg.sender, address(this), tokenId);
    }

    function redeemCustodianSign(uint256 tokenId) public {
        NFTInfo storage info = nfts[tokenId].info;

        require(info.status.redeem);
        info.status.freeze = true;

        transferARAFromContract(
            nu().calculateRedeemFeeLists(
                info,
                info.totalAuction > 0
                    ? nfts[tokenId].auctions[info.totalAuction - 1].value
                    : 0
            ),
            6
        );
    }

    function revertRedeem(uint256 tokenId) public {
        NFTInfo storage info = nfts[tokenId].info;

        nu().requireRevertRedeem(info, msg.sender);

        info.status.redeem = false;
        t().transfer(
            msg.sender,
            nu().calculateRedeemFee(
                info,
                info.totalAuction > 0
                    ? nfts[tokenId].auctions[info.totalAuction - 1].value
                    : 0
            )
        );
        _transfer(address(this), info.addr.owner, tokenId);
    }

    function transferFrom(
        address sender,
        address receiver,
        uint256 tokenId
    ) public override {
        NFTInfo storage info = nfts[tokenId].info;

        nu().requireTransfer(
            info,
            ownerOf(tokenId) == msg.sender,
            sender == msg.sender
        );

        t().transferFrom(
            msg.sender,
            address(this),
            nu().calculateTransferFee(
                info,
                info.totalAuction > 0
                    ? nfts[tokenId].auctions[info.totalAuction - 1].value
                    : 0
            )
        );
        transferARAFromContract(
            nu().calculateTransferFeeLists(
                info,
                info.totalAuction > 0
                    ? nfts[tokenId].auctions[info.totalAuction - 1].value
                    : 0,
                sender,
                receiver
            ),
            7
        );

        _transfer(msg.sender, receiver, tokenId);
        info.addr.owner = receiver;
    }

    function transferFromCollectionFactory(
        address sender,
        address receiver,
        uint256 tokenId
    ) public {
        require(
            msg.sender == g().getCollectionFactoryContract() ||
                nu().isValidCollection(msg.sender)
        );

        _transfer(sender, receiver, tokenId);

        nfts[tokenId].info.addr.owner = receiver;
    }
}
