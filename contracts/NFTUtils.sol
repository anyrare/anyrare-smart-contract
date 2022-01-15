pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ARAToken.sol";
import "./NFTDataType.sol";
import "./Governance.sol";
import "./Member.sol";
import "./CollectionFactory.sol";

contract NFTUtils is NFTDataType {
    address private governanceContract;

    constructor(address _governanceContract) {
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

    function cf() public view returns (CollectionFactory) {
        return CollectionFactory(g().getCollectionFactoryContract());
    }

    function calculateFeeFromPolicy(uint256 value, string memory policyName)
        public
        view
        returns (uint256)
    {
        return
            (value * g().getPolicy(policyName).policyWeight) /
            g().getPolicy(policyName).maxWeight;
    }

    function requireCustodianSign(
        bool exists,
        bool custodianSign,
        address sender,
        address custodian
    ) public view {
        require(exists && !custodianSign && sender == custodian);
    }

    function max(uint256 x, uint256 y) public pure returns (uint256) {
        return x > y ? x : y;
    }

    function min(uint256 x, uint256 y) public pure returns (uint256) {
        return x < y ? x : y;
    }

    function calculatePayFeeAndClaimTokenFeeLists(NFTInfo memory info)
        public
        view
        returns (TransferARA[] memory fees)
    {
        uint256 referralAuditorFee = calculateFeeFromPolicy(
            info.fee.auditFee,
            "MINT_NFT_REFERRAL_AUDITOR_FEE"
        );

        uint256 platformAuditorFee = calculateFeeFromPolicy(
            info.fee.auditFee,
            "MINT_NFT_PLATFORM_AUDITOR_FEE"
        );
        uint256 auditorFee = info.fee.auditFee -
            referralAuditorFee -
            platformAuditorFee;
        uint256 platformFee = info.fee.mintFee + platformAuditorFee;

        TransferARA[] memory feeLists = new TransferARA[](3);
        feeLists[0] = TransferARA({
            receiver: info.addr.auditor,
            amount: auditorFee
        });
        feeLists[1] = TransferARA({
            receiver: m().getReferral(info.addr.auditor),
            amount: referralAuditorFee
        });
        feeLists[2] = TransferARA({
            receiver: g().getManagementFundContract(),
            amount: platformFee
        });

        return feeLists;
    }

    function calculateAuctionTransferFeeLists(
        NFTInfo memory info,
        NFTAuction memory auction
    ) public view returns (TransferARA[] memory fees) {
        NFTAuctionTransferFee memory f = NFTAuctionTransferFee({
            _founderFee: (auction.value * info.fee.founderWeight) /
                info.fee.maxWeight,
            founderFee: 0,
            referralFounderFee: 0,
            platformFounderFee: 0,
            _custodianFee: (auction.value * info.fee.custodianWeight) /
                info.fee.maxWeight,
            custodianFee: 0,
            referralCustodianFee: 0,
            platformCustodianFee: 0,
            sellerFee: 0,
            referralSellerFee: calculateFeeFromPolicy(
                auction.value,
                "CLOSE_AUCTION_NFT_REFERRAL_SELLER_FEE"
            ),
            referralBuyerFee: calculateFeeFromPolicy(
                auction.value,
                "CLOSE_AUCTION_NFT_REFERRAL_BUYER_FEE"
            ),
            platformFee: 0
        });

        f.referralFounderFee = calculateFeeFromPolicy(
            f._founderFee,
            "CLOSE_AUCTION_NFT_REFERRAL_FOUNDER_FEE"
        );
        f.platformFounderFee = calculateFeeFromPolicy(
            f._founderFee,
            "CLOSE_AUCTION_NFT_PLATFORM_FOUNDER_FEE"
        );
        f.founderFee =
            f._founderFee -
            f.referralFounderFee -
            f.platformFounderFee;
        f.referralCustodianFee = calculateFeeFromPolicy(
            f._custodianFee,
            "CLOSE_AUCTION_NFT_REFERRAL_CUSTODIAN_FEE"
        );
        f.platformCustodianFee = calculateFeeFromPolicy(
            f._custodianFee,
            "CLOSE_AUCTION_NFT_PLATFORM_CUSTODIAN_FEE"
        );
        f.custodianFee =
            f._custodianFee -
            f.referralCustodianFee -
            f.platformCustodianFee;
        f.platformFee =
            calculateFeeFromPolicy(
                auction.value,
                "CLOSE_AUCTION_NFT_PLATFORM_FEE"
            ) +
            f.platformFounderFee +
            f.platformCustodianFee;
        f.sellerFee =
            auction.value -
            f.founderFee -
            f.referralFounderFee -
            f.custodianFee -
            f.referralCustodianFee -
            f.platformFee -
            f.referralBuyerFee -
            f.referralSellerFee;

        TransferARA[] memory feeLists = new TransferARA[](9);
        feeLists[0] = TransferARA({
            receiver: auction.owner,
            amount: f.sellerFee
        });
        feeLists[1] = TransferARA({
            receiver: info.addr.founder,
            amount: f.founderFee
        });
        feeLists[2] = TransferARA({
            receiver: m().getReferral(info.addr.founder),
            amount: f.referralFounderFee
        });
        feeLists[3] = TransferARA({
            receiver: info.addr.custodian,
            amount: f.custodianFee
        });
        feeLists[4] = TransferARA({
            receiver: m().getReferral(info.addr.custodian),
            amount: f.referralCustodianFee
        });
        feeLists[5] = TransferARA({
            receiver: g().getManagementFundContract(),
            amount: f.platformFee
        });
        feeLists[6] = TransferARA({
            receiver: m().getReferral(auction.bidder),
            amount: f.referralBuyerFee
        });
        feeLists[7] = TransferARA({
            receiver: m().getReferral(auction.owner),
            amount: f.referralSellerFee
        });
        feeLists[8] = TransferARA({
            receiver: auction.bidder,
            amount: auction.maxBid - auction.value
        });

        return feeLists;
    }

    function calculateOfferTransferFeeLists(NFTInfo memory info)
        public
        view
        returns (TransferARA[] memory fees)
    {
        NFTOfferTransferFee memory f = NFTOfferTransferFee({
            _founderFee: (info.offer.value * info.fee.founderWeight) /
                info.fee.maxWeight,
            founderFee: 0,
            referralFounderFee: 0,
            platformFounderFee: 0,
            _custodianFee: (info.offer.value * info.fee.custodianWeight) /
                info.fee.maxWeight,
            custodianFee: 0,
            referralCustodianFee: 0,
            platformCustodianFee: 0,
            sellerFee: 0,
            referralSellerFee: calculateFeeFromPolicy(
                info.offer.value,
                "OFFER_NFT_REFERRAL_SELLER_FEE"
            ),
            referralBuyerFee: calculateFeeFromPolicy(
                info.offer.value,
                "OFFER_NFT_REFERRAL_BUYER_FEE"
            ),
            platformFee: 0
        });

        f.referralFounderFee = calculateFeeFromPolicy(
            f._founderFee,
            "OFFER_NFT_REFERRAL_FOUNDER_FEE"
        );
        f.platformFounderFee = calculateFeeFromPolicy(
            f._founderFee,
            "OFFER_NFT_PLATFORM_FOUNDER_FEE"
        );
        f.founderFee =
            f._founderFee -
            f.referralFounderFee -
            f.platformFounderFee;
        f.referralCustodianFee = calculateFeeFromPolicy(
            f._custodianFee,
            "OFFER_NFT_REFERRAL_CUSTODIAN_FEE"
        );
        f.platformCustodianFee = calculateFeeFromPolicy(
            f._custodianFee,
            "OFFER_NFT_PLATFORM_CUSTODIAN_FEE"
        );
        f.custodianFee =
            f._custodianFee -
            f.referralCustodianFee -
            f.platformCustodianFee;
        f.platformFee =
            calculateFeeFromPolicy(info.offer.value, "OFFER_NFT_PLATFORM_FEE") +
            f.platformFounderFee +
            f.platformCustodianFee;
        f.sellerFee =
            info.offer.value -
            f.founderFee -
            f.referralFounderFee -
            f.custodianFee -
            f.referralCustodianFee -
            f.platformFee -
            f.referralBuyerFee -
            f.referralSellerFee;

        TransferARA[] memory feeLists = new TransferARA[](8);

        feeLists[0] = TransferARA({
            receiver: info.offer.owner,
            amount: f.sellerFee
        });
        feeLists[1] = TransferARA({
            receiver: info.addr.founder,
            amount: f.founderFee
        });
        feeLists[2] = TransferARA({
            receiver: m().getReferral(info.addr.founder),
            amount: f.referralFounderFee
        });
        feeLists[3] = TransferARA({
            receiver: info.addr.custodian,
            amount: f.custodianFee
        });
        feeLists[4] = TransferARA({
            receiver: m().getReferral(info.addr.custodian),
            amount: f.referralCustodianFee
        });
        feeLists[5] = TransferARA({
            receiver: g().getManagementFundContract(),
            amount: f.platformFee
        });
        feeLists[6] = TransferARA({
            receiver: m().getReferral(info.offer.bidder),
            amount: f.referralBuyerFee
        });
        feeLists[7] = TransferARA({
            receiver: m().getReferral(info.offer.owner),
            amount: f.referralSellerFee
        });

        return feeLists;
    }

    function calculateBuyItNowTransferFeeLists(
        NFTInfo memory info,
        address buyer
    ) public view returns (TransferARA[] memory fees) {
        NFTBuyItNowTransferFee memory f = NFTBuyItNowTransferFee({
            _founderFee: (info.buyItNow.value * info.fee.founderWeight) /
                info.fee.maxWeight,
            founderFee: 0,
            referralFounderFee: 0,
            platformFounderFee: 0,
            _custodianFee: (info.buyItNow.value * info.fee.custodianWeight) /
                info.fee.maxWeight,
            custodianFee: 0,
            referralCustodianFee: 0,
            platformCustodianFee: 0,
            sellerFee: 0,
            referralSellerFee: calculateFeeFromPolicy(
                info.buyItNow.value,
                "BUY_IT_NOW_NFT_REFERRAL_SELLER_FEE"
            ),
            referralBuyerFee: calculateFeeFromPolicy(
                info.buyItNow.value,
                "BUY_IT_NOW_NFT_REFERRAL_BUYER_FEE"
            ),
            platformFee: 0
        });

        f.referralFounderFee = calculateFeeFromPolicy(
            f._founderFee,
            "BUY_IT_NOW_NFT_REFERRAL_FOUNDER_FEE"
        );
        f.platformFounderFee = calculateFeeFromPolicy(
            f._founderFee,
            "BUY_IT_NOW_NFT_PLATFORM_FOUNDER_FEE"
        );
        f.founderFee =
            f._founderFee -
            f.referralFounderFee -
            f.platformFounderFee;
        f.referralCustodianFee = calculateFeeFromPolicy(
            f._custodianFee,
            "BUY_IT_NOW_NFT_REFERRAL_CUSTODIAN_FEE"
        );
        f.platformCustodianFee = calculateFeeFromPolicy(
            f._custodianFee,
            "BUY_IT_NOW_NFT_PLATFORM_CUSTODIAN_FEE"
        );
        f.custodianFee =
            f._custodianFee -
            f.referralCustodianFee -
            f.platformCustodianFee;
        f.platformFee =
            calculateFeeFromPolicy(
                info.buyItNow.value,
                "BUY_IT_NOW_NFT_PLATFORM_FEE"
            ) +
            f.platformFounderFee +
            f.platformCustodianFee;
        f.sellerFee =
            info.buyItNow.value -
            f.founderFee -
            f.referralFounderFee -
            f.custodianFee -
            f.referralCustodianFee -
            f.platformFee -
            f.referralBuyerFee -
            f.referralSellerFee;

        TransferARA[] memory feeLists = new TransferARA[](8);

        feeLists[0] = TransferARA({
            receiver: info.buyItNow.owner,
            amount: f.sellerFee
        });
        feeLists[1] = TransferARA({
            receiver: info.addr.founder,
            amount: f.founderFee
        });
        feeLists[2] = TransferARA({
            receiver: m().getReferral(info.addr.founder),
            amount: f.referralFounderFee
        });
        feeLists[3] = TransferARA({
            receiver: info.addr.custodian,
            amount: f.custodianFee
        });
        feeLists[4] = TransferARA({
            receiver: m().getReferral(info.addr.custodian),
            amount: f.referralCustodianFee
        });
        feeLists[5] = TransferARA({
            receiver: g().getManagementFundContract(),
            amount: f.platformFee
        });
        feeLists[6] = TransferARA({
            receiver: m().getReferral(buyer),
            amount: f.referralBuyerFee
        });
        feeLists[7] = TransferARA({
            receiver: m().getReferral(info.buyItNow.owner),
            amount: f.referralSellerFee
        });

        return feeLists;
    }

    function calculateRedeemFeeStruct(NFTInfo memory info, uint256 auctionValue)
        public
        view
        returns (NFTRedeemFee memory fees)
    {
        NFTRedeemFee memory f = NFTRedeemFee({
            value: max(
                auctionValue,
                max(info.buyItNow.value, info.offer.value)
            ),
            _founderFee: 0,
            founderFee: 0,
            referralFounderFee: 0,
            platformFounderFee: 0,
            _custodianFee: 0,
            custodianFee: 0,
            referralCustodianFee: 0,
            platformCustodianFee: 0,
            referralOwnerFee: 0,
            platformFee: 0
        });

        f._founderFee = max(
            info.fee.founderGeneralFee,
            (f.value * info.fee.founderRedeemWeight) / info.fee.maxWeight
        );
        f.referralFounderFee = calculateFeeFromPolicy(
            f._founderFee,
            "REDEEM_NFT_REFERRAL_FOUNDER_FEE"
        );
        f.platformFounderFee = calculateFeeFromPolicy(
            f._founderFee,
            "REDEEM_NFT_PLATFORM_FOUNDER_FEE"
        );
        f.founderFee =
            f._founderFee -
            f.referralFounderFee -
            f.platformFounderFee;

        f._custodianFee = max(
            info.fee.custodianGeneralFee,
            (f.value * info.fee.custodianRedeemWeight) / info.fee.maxWeight
        );
        f.referralCustodianFee = calculateFeeFromPolicy(
            f._custodianFee,
            "REDEEM_NFT_REFERRAL_CUSTODIAN_FEE"
        );
        f.platformCustodianFee = calculateFeeFromPolicy(
            f._custodianFee,
            "REDEEM_NFT_PLATFORM_CUSTODIAN_FEE"
        );
        f.custodianFee =
            f._custodianFee -
            f.referralCustodianFee -
            f.platformCustodianFee;

        f.platformFee =
            max(
                g().getPolicy("REDEEM_NFT_PLATFORM_FEE").policyValue,
                calculateFeeFromPolicy(f.value, "REDEEM_NFT_PLATFORM_FEE")
            ) +
            f.platformFounderFee +
            f.platformCustodianFee;

        f.referralOwnerFee = calculateFeeFromPolicy(
            f.value,
            "REDEEM_NFT_REFERRAL_OWNER_FEE"
        );

        return f;
    }

    function calculateRedeemFee(NFTInfo memory info, uint256 auctionValue)
        public
        view
        returns (uint256)
    {
        NFTRedeemFee memory f = calculateRedeemFeeStruct(info, auctionValue);

        return
            f.founderFee +
            f.referralFounderFee +
            f.custodianFee +
            f.referralCustodianFee +
            f.platformFee +
            f.referralOwnerFee;
    }

    function calculateRedeemFeeLists(NFTInfo memory info, uint256 auctionValue)
        public
        view
        returns (TransferARA[] memory f)
    {
        NFTRedeemFee memory f = calculateRedeemFeeStruct(info, auctionValue);

        TransferARA[] memory feeLists = new TransferARA[](6);
        feeLists[0] = TransferARA({
            receiver: info.addr.founder,
            amount: f.founderFee
        });
        feeLists[1] = TransferARA({
            receiver: m().getReferral(info.addr.founder),
            amount: f.referralFounderFee
        });
        feeLists[2] = TransferARA({
            receiver: info.addr.custodian,
            amount: f.custodianFee
        });
        feeLists[3] = TransferARA({
            receiver: m().getReferral(info.addr.custodian),
            amount: f.referralCustodianFee
        });
        feeLists[4] = TransferARA({
            receiver: g().getManagementFundContract(),
            amount: f.platformFee
        });
        feeLists[5] = TransferARA({
            receiver: m().getReferral(info.addr.owner),
            amount: f.referralOwnerFee
        });

        return feeLists;
    }

    function calculateTransferFeeStruct(
        NFTInfo memory info,
        uint256 auctionValue
    ) public view returns (NFTTransferFee memory fees) {
        NFTTransferFee memory f = NFTTransferFee({
            value: max(
                auctionValue,
                max(info.buyItNow.value, info.offer.value)
            ),
            _founderFee: 0,
            founderFee: 0,
            referralFounderFee: 0,
            platformFounderFee: 0,
            _custodianFee: 0,
            custodianFee: 0,
            referralCustodianFee: 0,
            platformCustodianFee: 0,
            referralSenderFee: 0,
            referralReceiverFee: 0,
            platformFee: 0
        });

        f._founderFee = max(
            info.fee.founderGeneralFee,
            (f.value * info.fee.founderWeight) / info.fee.maxWeight
        );
        f.referralFounderFee = calculateFeeFromPolicy(
            f._founderFee,
            "TRANSFER_NFT_REFERRAL_FOUNDER_FEE"
        );
        f.platformFounderFee = calculateFeeFromPolicy(
            f._founderFee,
            "TRANSFER_NFT_PLATFORM_FOUNDER_FEE"
        );
        f.founderFee =
            f._founderFee -
            f.referralFounderFee -
            f.platformFounderFee;

        f._custodianFee = max(
            info.fee.custodianGeneralFee,
            (f.value * info.fee.custodianRedeemWeight) / info.fee.maxWeight
        );
        f.referralCustodianFee = calculateFeeFromPolicy(
            f._custodianFee,
            "TRANSFER_NFT_REFERRAL_CUSTODIAN_FEE"
        );
        f.platformCustodianFee = calculateFeeFromPolicy(
            f._custodianFee,
            "TRANSFER_NFT_PLATFORM_CUSTODIAN_FEE"
        );
        f.custodianFee =
            f._custodianFee -
            f.referralCustodianFee -
            f.platformCustodianFee;

        f.platformFee =
            max(
                g().getPolicy("TRANSFER_NFT_PLATFORM_FEE").policyValue,
                calculateFeeFromPolicy(f.value, "TRANSFER_NFT_PLATFORM_FEE")
            ) +
            f.platformFounderFee +
            f.platformCustodianFee;

        f.referralSenderFee = calculateFeeFromPolicy(
            f.value,
            "TRANSFER_NFT_REFERRAL_SENDER_FEE"
        );

        f.referralReceiverFee = calculateFeeFromPolicy(
            f.value,
            "TRANSFER_NFT_REFERRAL_RECEIVER_FEE"
        );

        return f;
    }

    function calculateTransferFee(NFTInfo memory info, uint256 auctionValue)
        public
        view
        returns (uint256)
    {
        NFTTransferFee memory f = calculateTransferFeeStruct(
            info,
            auctionValue
        );

        return
            f.founderFee +
            f.referralFounderFee +
            f.custodianFee +
            f.referralCustodianFee +
            f.platformFee +
            f.referralSenderFee +
            f.referralReceiverFee;
    }

    function calculateTransferFeeLists(
        NFTInfo memory info,
        uint256 auctionValue,
        address sender,
        address receiver
    ) public view returns (TransferARA[] memory f) {
        NFTTransferFee memory f = calculateTransferFeeStruct(
            info,
            auctionValue
        );

        TransferARA[] memory feeLists = new TransferARA[](7);
        feeLists[0] = TransferARA({
            receiver: info.addr.founder,
            amount: f.founderFee
        });
        feeLists[1] = TransferARA({
            receiver: m().getReferral(info.addr.founder),
            amount: f.referralFounderFee
        });
        feeLists[2] = TransferARA({
            receiver: info.addr.custodian,
            amount: f.custodianFee
        });
        feeLists[3] = TransferARA({
            receiver: m().getReferral(info.addr.custodian),
            amount: f.referralCustodianFee
        });
        feeLists[4] = TransferARA({
            receiver: g().getManagementFundContract(),
            amount: f.platformFee
        });
        feeLists[5] = TransferARA({
            receiver: m().getReferral(sender),
            amount: f.referralSenderFee
        });
        feeLists[6] = TransferARA({
            receiver: m().getReferral(receiver),
            amount: f.referralReceiverFee
        });

        return feeLists;
    }

    function requireCustodianSign(NFTInfo memory info, address sender) public {
        require(
            info.exists &&
                !info.status.custodianSign &&
                sender == info.addr.custodian
        );
    }

    function requirePayFeeAndClaimToken(NFTInfo memory info, address sender)
        public
        view
    {
        require(
            info.exists &&
                info.status.custodianSign &&
                !info.status.claim &&
                (info.addr.founder == sender ||
                    (info.addr.custodian == sender &&
                        block.timestamp >=
                        g()
                            .getPolicy("NFT_CUSTODIAN_CAN_CLAIM_DURATION")
                            .policyValue)) &&
                t().balanceOf(sender) >= info.fee.auditFee + info.fee.mintFee
        );
    }

    function requireOpenAuction(
        bool isOwner,
        NFTStatus memory status,
        address sender
    ) public view {
        require(
            isOwner &&
                m().isMember(sender) &&
                !status.auction &&
                !status.buyItNow &&
                !status.offer &&
                !status.lockInCollection &&
                !status.redeem &&
                !status.freeze
        );
    }

    function requireBidAuction(
        NFTStatus memory status,
        NFTAuction memory auction,
        address sender,
        uint256 bidValue,
        uint256 maxBid,
        uint256 minBidValue
    ) public view {
        require(
            status.auction &&
                m().isMember(sender) &&
                (
                    auction.bidder != sender
                        ? t().balanceOf(sender) >= maxBid
                        : t().balanceOf(sender) >=
                            maxBid -
                                (auction.meetReservePrice ? auction.maxBid : 0)
                ) &&
                (
                    auction.totalBid == 0
                        ? maxBid >= auction.startingPrice
                        : maxBid >= minBidValue
                ) &&
                bidValue <= maxBid &&
                (block.timestamp < auction.closeAuctionTimestamp)
        );
    }

    function requireOpenBuyItNow(
        NFTInfo memory info,
        bool isOwner,
        address sender,
        uint256 value,
        uint256 platformFee,
        uint256 referralFee
    ) public view {
        require(
            info.exists &&
                isOwner &&
                !info.status.auction &&
                !info.status.buyItNow &&
                !info.status.lockInCollection &&
                !info.status.redeem &&
                !info.status.freeze &&
                m().isMember(sender) &&
                value > 0 &&
                t().balanceOf(sender) >= platformFee + referralFee
        );
    }

    function requireChangeBuyItNowPrice(
        NFTInfo memory info,
        address sender,
        uint256 value
    ) public {
        require(
            info.exists &&
                info.status.buyItNow &&
                info.buyItNow.owner == sender &&
                value > 0
        );
    }

    function requireCloseBuyItNow(NFTInfo memory info, address sender) public {
        require(
            info.exists && info.status.buyItNow && info.buyItNow.owner == sender
        );
    }

    function requireBuyFromBuyItNow(NFTInfo memory info, address sender)
        public
        view
    {
        require(
            info.exists &&
                info.status.buyItNow &&
                t().balanceOf(sender) >= info.buyItNow.value &&
                m().isMember(sender)
        );
    }

    function requireOpenOffer(
        bool isOwner,
        NFTInfo memory info,
        uint256 bidValue,
        address sender
    ) public view {
        require(
            info.exists &&
                !isOwner &&
                info.status.claim &&
                !info.status.auction &&
                !info.status.lockInCollection &&
                !info.status.redeem &&
                !info.status.freeze &&
                (bidValue > info.offer.value || !info.status.offer) &&
                t().balanceOf(sender) >=
                (
                    sender == info.offer.bidder && info.status.offer
                        ? bidValue - info.offer.value
                        : bidValue
                ) &&
                m().isMember(sender)
        );
    }

    function requireRevertOffer(
        NFTInfo memory info,
        bool isOwner,
        address sender
    ) public {
        require(
            info.exists &&
                info.status.offer &&
                (block.timestamp >= info.offer.closeOfferTimestamp ||
                    isOwner ||
                    info.offer.bidder == sender)
        );
    }

    function requireRedeem(NFTInfo memory info, bool isOwner) public view {
        require(
            info.exists &&
                isOwner &&
                !info.status.lockInCollection &&
                !info.status.auction &&
                !info.status.offer &&
                !info.status.redeem
        );
    }

    function requireRevertRedeem(NFTInfo memory info, address sender)
        public
        view
    {
        require(
            info.addr.owner == sender &&
                info.status.redeem &&
                !info.status.freeze &&
                block.timestamp >=
                info.redeemTimestamp +
                    g().getPolicy("REDEEM_NFT_REVERT_DURATION").policyValue
        );
    }

    function requireTransfer(
        NFTInfo memory info,
        bool isOwner,
        bool isSenderCorrect
    ) public view {
        require(
            info.exists &&
                isOwner &&
                isSenderCorrect &&
                !info.status.lockInCollection &&
                !info.status.auction &&
                !info.status.redeem &&
                !info.status.freeze
        );
    }

    function isValidCollection(address addr) public view returns (bool) {
        return cf().isValidCollection(addr);
    }
}
