pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./Governance.sol";
import "./NFTTransferFee.sol";
import "./NFTDataType.sol";
import "./Member.sol";
import "hardhat/console.sol";

contract NFTFactory is ERC721URIStorage, NFTDataType {
    mapping(uint256 => NFTInfo) public nfts;

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

    function m() public returns (Member) {
        return Member(g().getMemberContract());
    }

    function t() public returns (ERC20) {
        return ERC20(g().getARATokenContract());
    }

    function nt() private view returns (NFTTransferFee) {
        return NFTTransferFee(g().getNFTTransferFeeContract());
    }

    function getCurrentTokenId() public view returns (uint256) {
        return currentTokenId - 1;
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
                t().transfer(lists[i].receiver, lists[i].amount);
            }
        }
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

        nfts[currentTokenId].exists = true;
        nfts[currentTokenId].tokenId = currentTokenId;
        nfts[currentTokenId].addr = addr;
        nfts[currentTokenId].fee = fee;

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
        require(
            nfts[tokenId].exists &&
                !nfts[tokenId].status.custodianSign &&
                msg.sender == nfts[tokenId].addr.custodian
        );

        nfts[tokenId].status.custodianSign = true;
        nfts[tokenId].fee.custodianWeight = custodianWeight;
        nfts[tokenId].fee.custodianGeneralFee = custodianGeneralFee;
        nfts[tokenId].fee.custodianRedeemWeight = custodianRedeemWeight;
    }

    function payFeeAndClaimToken(uint256 tokenId) public payable {
        NFTInfo storage nft = nfts[tokenId];

        nt().requirePayFeeAndClaimToken(
            nft.exists,
            nft.status,
            nft.addr,
            nft.fee,
            msg.sender
        );

        t().transferFrom(
            msg.sender,
            address(this),
            nft.fee.auditFee + nft.fee.mintFee
        );

        TransferARA[] memory feeLists = new TransferARA[](2);
        feeLists[0] = TransferARA({
            receiver: nft.addr.auditor,
            amount: nft.fee.auditFee
        });
        feeLists[1] = TransferARA({
            receiver: g().getManagementFundContract(),
            amount: nft.fee.mintFee
        });
        transferARAFromContract(feeLists, 2);

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
        nt().requireOpenAuction(
            ownerOf(tokenId) == msg.sender,
            nfts[tokenId].status,
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

        nfts[tokenId].status.auction = true;
        nfts[tokenId].auctions[nfts[tokenId].totalAuction] = auction;
        nfts[tokenId].totalAuction += 1;

        _transfer(msg.sender, address(this), tokenId);
    }

    function getAuctionByAuctionId(uint256 tokenId, uint32 auctionId)
        public
        view
        returns (NFTAuction memory a)
    {
        NFTAuction memory auction = nfts[tokenId].auctions[auctionId];
        if (
            auction.value < auction.reservePrice && nfts[tokenId].status.auction
        ) {
            auction.reservePrice = 0;
        }
        if (nfts[tokenId].status.auction) {
            auction.maxBid = 0;
        }
        return auction;
    }

    function getAuction(uint256 tokenId)
        public
        view
        returns (NFTAuction memory a)
    {
        return getAuctionByAuctionId(tokenId, nfts[tokenId].totalAuction - 1);
    }

    function getAuctionBid(uint256 tokenId, uint32 bidId)
        public
        view
        returns (NFTAuctionBid memory bid)
    {
        return nfts[tokenId].bids[bidId];
    }

    function bidAuction(
        uint256 tokenId,
        uint256 bidValue,
        uint256 maxBid
    ) public payable {
        NFTInfo storage nft = nfts[tokenId];
        uint32 auctionId = nft.totalAuction - 1;
        NFTAuction storage auction = nft.auctions[auctionId];
        uint256 minBidValue = (auction.value * auction.nextBidWeight) /
            auction.maxWeight +
            auction.value;

        nt().requireBidAuction(
            nfts[tokenId].status,
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

        nft.bids[nft.bidId] = NFTAuctionBid({
            auctionId: auctionId,
            timestamp: block.timestamp,
            value: maxBid >= auction.reservePrice ? bidValue : maxBid,
            meetReservePrice: maxBid >= auction.reservePrice,
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
        }

        if (maxBid <= auction.maxBid) {
            nft.bids[nft.bidId] = NFTAuctionBid({
                auctionId: auctionId,
                timestamp: block.timestamp,
                value: maxBid,
                meetReservePrice: maxBid >= auction.reservePrice,
                bidder: auction.bidder,
                autoRebid: true
            });
            nft.bidId += 1;
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
        NFTInfo storage nft = nfts[tokenId];
        uint32 auctionId = nft.totalAuction - 1;
        NFTAuction memory auction = nft.auctions[auctionId];

        require(
            nft.status.auction &&
                block.timestamp >= auction.closeAuctionTimestamp
        );

        nft.status.auction = false;

        if (auction.totalBid > 0 && auction.value >= auction.reservePrice) {
            nft.latestAuctionValue = auction.value;
            transferARAFromContract(
                nt().calculateAuctionTransferFeeLists(
                    nft.fee,
                    nft.addr,
                    auction
                ),
                7
            );
            _transfer(address(this), auction.bidder, tokenId);

            nft.addr.owner = auction.bidder;
        } else {
            _transfer(address(this), auction.owner, tokenId);
        }
    }

    function openBuyItNow(uint256 tokenId, uint256 value) public {
        nt().requireOpenBuyItNow(
            nfts[tokenId].exists,
            ownerOf(tokenId) == msg.sender,
            nfts[tokenId].status,
            msg.sender,
            value,
            g().getPolicy("OPEN_BUY_IT_NOW_NFT_PLATFORM_FEE").policyValue,
            g().getPolicy("OPEN_BUY_IT_NOW_NFT_REFERRAL_FEE").policyValue
        );

        transferOpenFee(
            "OPEN_BUY_IT_NOW_NFT_PLATFORM_FEE",
            "OPEN_BUY_IT_NOW_NFT_REFERRAL_FEE"
        );

        nfts[tokenId].status.buyItNow = true;
        nfts[tokenId].buyItNow.owner = msg.sender;
        nfts[tokenId].buyItNow.value = value;

        _transfer(msg.sender, address(this), tokenId);
    }

    function changeBuyItNowPrice(uint256 tokenId, uint256 value) public {
        require(
            nfts[tokenId].exists &&
                nfts[tokenId].status.buyItNow &&
                nfts[tokenId].buyItNow.owner == msg.sender &&
                value > 0
        );

        nfts[tokenId].buyItNow.value = value;
    }

    function buyFromBuyItNow(uint256 tokenId) public payable {
        NFTInfo storage nft = nfts[tokenId];

        nt().requireBuyFromBuyItNow(
            nft.exists,
            nft.status.buyItNow,
            nft.buyItNow.value,
            msg.sender
        );

        nft.status.buyItNow = false;
        nft.latestBuyValue = nft.buyItNow.value;

        t().transferFrom(msg.sender, address(this), nft.buyItNow.value);

        transferARAFromContract(
            nt().calculateBuyItNowTransferFeeLists(
                nft.fee,
                nft.addr,
                nft.buyItNow,
                msg.sender
            ),
            6
        );

        nft.buyItNow.owner = address(0x0);
        nft.buyItNow.value = 0;
        nft.addr.owner = msg.sender;

        _transfer(address(this), msg.sender, tokenId);
    }

    function closeBuyItNow(uint256 tokenId) public {
        require(
            nfts[tokenId].exists &&
                nfts[tokenId].status.buyItNow &&
                nfts[tokenId].buyItNow.owner == msg.sender
        );

        nfts[tokenId].status.buyItNow = false;

        _transfer(address(this), nfts[tokenId].buyItNow.owner, tokenId);

        nfts[tokenId].buyItNow.owner = address(0x0);
        nfts[tokenId].buyItNow.value = 0;
    }

    function openOffer(uint256 bidValue, uint256 tokenId) public {
        NFTInfo storage nft = nfts[tokenId];

        nt().requireOpenOffer(
            nft.exists,
            ownerOf(tokenId) == msg.sender,
            nft.status,
            nft.offer,
            bidValue,
            msg.sender
        );

        t().transferFrom(
            msg.sender,
            address(this),
            msg.sender == nft.offer.bidder
                ? bidValue - nft.offer.value
                : bidValue
        );

        if (nft.status.offer && nft.offer.bidder != msg.sender) {
            t().transfer(nft.offer.bidder, nft.offer.value);
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
            nft.exists &&
                nfts[tokenId].status.offer &&
                ownerOf(tokenId) == msg.sender
        );

        nft.status.offer = false;

        transferARAFromContract(
            nt().calculateOfferTransferFeeLists(nft.fee, nft.addr, nft.offer),
            6
        );

        _transfer(msg.sender, nft.offer.bidder, tokenId);

        nft.addr.owner = nft.offer.bidder;
        nft.offer.status = 2;
        nft.offer.value = 0;
        nft.offer.owner = address(0x0);
        nft.offer.bidder = address(0x0);
        nft.latestBuyValue = nft.offer.value;
    }

    function revertOffer(uint256 tokenId) public {
        require(
            nfts[tokenId].exists &&
                nfts[tokenId].status.offer &&
                (block.timestamp >= nfts[tokenId].offer.closeOfferTimestamp ||
                    ownerOf(tokenId) == msg.sender ||
                    nfts[tokenId].offer.bidder == msg.sender)
        );

        t().transfer(nfts[tokenId].offer.bidder, nfts[tokenId].offer.value);

        nfts[tokenId].status.offer = false;
        nfts[tokenId].offer.status = 0;
        nfts[tokenId].offer.value = 0;
        nfts[tokenId].offer.owner = address(0x0);
        nfts[tokenId].offer.bidder = address(0x0);
    }

    function redeem(uint256 tokenId) public payable {
        nt().requireRedeem(
            nfts[tokenId].exists,
            nfts[tokenId].status,
            ownerOf(tokenId) == msg.sender
        );
        t().transferFrom(
            msg.sender,
            address(this),
            nt().calculateRedeemFee(
                nfts[tokenId].fee,
                nfts[tokenId].latestAuctionValue,
                nfts[tokenId].latestBuyValue
            )
        );

        nfts[tokenId].redeemTimestamp = block.timestamp;
        nfts[tokenId].status.redeem = true;
        _transfer(msg.sender, address(this), tokenId);
    }

    function redeemCustodianSign(uint256 tokenId) public {
        require(nfts[tokenId].status.redeem);
        nfts[tokenId].status.freeze = true;

        transferARAFromContract(
            nt().calculateRedeemFeeLists(
                nfts[tokenId].addr,
                nfts[tokenId].fee,
                nfts[tokenId].latestAuctionValue,
                nfts[tokenId].latestBuyValue
            ),
            4
        );
    }

    function revertRedeem(uint256 tokenId) public {
        nt().requireRevertRedeem(
            nfts[tokenId].addr,
            nfts[tokenId].status,
            nfts[tokenId].redeemTimestamp,
            msg.sender
        );

        nfts[tokenId].status.redeem = false;
        t().transfer(
            msg.sender,
            nt().calculateRedeemFee(
                nfts[tokenId].fee,
                nfts[tokenId].latestAuctionValue,
                nfts[tokenId].latestBuyValue
            )
        );
        _transfer(address(this), nfts[tokenId].addr.owner, tokenId);
    }

    function transferFrom(
        address sender,
        address receiver,
        uint256 tokenId
    ) public override {
        nt().requireTransfer(
            nfts[tokenId].exists,
            nfts[tokenId].status,
            ownerOf(tokenId) == msg.sender,
            sender == msg.sender
        );
        t().transferFrom(
            msg.sender,
            address(this),
            nt().calculateTransferFee(
                nfts[tokenId].fee,
                nfts[tokenId].latestAuctionValue,
                nfts[tokenId].latestBuyValue
            )
        );
        transferARAFromContract(
            nt().calculateTransferFeeLists(
                nfts[tokenId].addr,
                nfts[tokenId].fee,
                nfts[tokenId].latestAuctionValue,
                nfts[tokenId].latestBuyValue,
                sender,
                receiver
            ),
            5
        );
        _transfer(msg.sender, receiver, tokenId);
        nfts[tokenId].addr.owner = receiver;
    }
}
