pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./NFTDataType.sol";
import "./Governance.sol";
import "./Member.sol";

contract NFTTransferFee is NFTDataType {
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

    function t() public view returns (ERC20) {
        return ERC20(g().getARATokenContract());
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

    function max(uint256 x, uint256 y) private pure returns (uint256) {
        return x > y ? x : y;
    }

    function min(uint256 x, uint256 y) private pure returns (uint256) {
        return x < y ? x : y;
    }

    function calculateAuctionTransferFeeLists(
        NFTInfo memory info,
        NFTAuction memory auction
    ) public view returns (TransferARA[] memory f) {
        uint256 founderRoyaltyFee = (auction.value * info.fee.founderWeight) /
            info.fee.maxWeight;
        uint256 custodianFee = (auction.value * info.fee.custodianWeight) /
            info.fee.maxWeight;
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

        TransferARA[] memory feeLists = new TransferARA[](7);
        feeLists[0] = TransferARA({
            receiver: info.addr.founder,
            amount: founderRoyaltyFee
        });
        feeLists[1] = TransferARA({
            receiver: info.addr.custodian,
            amount: custodianFee
        });
        feeLists[2] = TransferARA({
            receiver: g().getManagementFundContract(),
            amount: platformFee
        });
        feeLists[3] = TransferARA({
            receiver: m().getReferral(auction.bidder),
            amount: referralBuyerFee
        });
        feeLists[4] = TransferARA({
            receiver: m().getReferral(auction.owner),
            amount: referralSellerFee
        });
        feeLists[5] = TransferARA({
            receiver: auction.owner,
            amount: auction.value -
                founderRoyaltyFee -
                custodianFee -
                platformFee -
                referralBuyerFee -
                referralSellerFee
        });
        feeLists[6] = TransferARA({
            receiver: auction.bidder,
            amount: auction.maxBid - auction.value
        });

        return feeLists;
    }

    function calculateOfferTransferFeeLists(NFTInfo memory info)
        public
        view
        returns (TransferARA[] memory f)
    {
        uint256 founderRoyaltyFee = (info.offer.value *
            info.fee.founderWeight) / info.fee.maxWeight;
        uint256 custodianFee = (info.offer.value * info.fee.custodianWeight) /
            info.fee.maxWeight;
        uint256 platformFee = calculateFeeFromPolicy(
            info.offer.value,
            "OFFER_NFT_PLATFORM_FEE"
        );
        uint256 referralBuyerFee = calculateFeeFromPolicy(
            info.offer.value,
            "OFFER_NFT_REFERRAL_BUYER_FEE"
        );
        uint256 referralSellerFee = calculateFeeFromPolicy(
            info.offer.value,
            "OFFER_NFT_REFERRAL_SELLER_FEE"
        );

        TransferARA[] memory feeLists = new TransferARA[](6);
        feeLists[0] = TransferARA({
            receiver: info.addr.founder,
            amount: founderRoyaltyFee
        });
        feeLists[1] = TransferARA({
            receiver: info.addr.custodian,
            amount: custodianFee
        });
        feeLists[2] = TransferARA({
            receiver: g().getManagementFundContract(),
            amount: platformFee
        });
        feeLists[3] = TransferARA({
            receiver: m().getReferral(info.offer.bidder),
            amount: referralBuyerFee
        });
        feeLists[4] = TransferARA({
            receiver: m().getReferral(info.offer.owner),
            amount: referralSellerFee
        });
        feeLists[5] = TransferARA({
            receiver: info.offer.owner,
            amount: info.offer.value -
                founderRoyaltyFee -
                custodianFee -
                platformFee -
                referralBuyerFee -
                referralSellerFee
        });

        return feeLists;
    }

    function calculateBuyItNowTransferFeeLists(
        NFTInfo memory info,
        address buyer
    ) public view returns (TransferARA[] memory f) {
        uint256 founderRoyaltyFee = (info.buyItNow.value *
            info.fee.founderWeight) / info.fee.maxWeight;
        uint256 custodianFee = (info.buyItNow.value *
            info.fee.custodianWeight) / info.fee.maxWeight;
        uint256 platformFee = calculateFeeFromPolicy(
            info.buyItNow.value,
            "BUY_IT_NOW_NFT_PLATFORM_FEE"
        );
        uint256 referralBuyerFee = calculateFeeFromPolicy(
            info.buyItNow.value,
            "BUY_IT_NOW_NFT_REFERRAL_BUYER_FEE"
        );
        uint256 referralSellerFee = calculateFeeFromPolicy(
            info.buyItNow.value,
            "BUY_IT_NOW_NFT_REFERRAL_SELLER_FEE"
        );

        TransferARA[] memory feeLists = new TransferARA[](6);
        feeLists[0] = TransferARA({
            receiver: info.addr.founder,
            amount: founderRoyaltyFee
        });
        feeLists[1] = TransferARA({
            receiver: info.addr.custodian,
            amount: custodianFee
        });
        feeLists[2] = TransferARA({
            receiver: g().getManagementFundContract(),
            amount: platformFee
        });
        feeLists[3] = TransferARA({
            receiver: m().getReferral(buyer),
            amount: referralBuyerFee
        });
        feeLists[4] = TransferARA({
            receiver: m().getReferral(info.buyItNow.owner),
            amount: referralSellerFee
        });
        feeLists[5] = TransferARA({
            receiver: info.buyItNow.owner,
            amount: info.buyItNow.value -
                founderRoyaltyFee -
                custodianFee -
                platformFee -
                referralBuyerFee -
                referralSellerFee
        });

        return feeLists;
    }

    function calculateRedeemFee(NFTInfo memory info, uint256 auctionValue)
        public
        view
        returns (uint256)
    {
        uint256 value = max(
            auctionValue,
            max(info.buyItNow.value, info.offer.value)
        );
        uint256 founderFee = max(
            info.fee.founderGeneralFee,
            (value * info.fee.founderRedeemWeight) / info.fee.maxWeight
        );
        uint256 custodianFee = max(
            info.fee.custodianGeneralFee,
            (value * info.fee.custodianRedeemWeight) / info.fee.maxWeight
        );
        uint256 platformFee = max(
            g().getPolicy("REDEEM_NFT_PLATFORM_FEE").policyValue,
            calculateFeeFromPolicy(value, "REDEEM_NFT_PLATFORM_FEE")
        );
        uint256 referralFee = max(
            g().getPolicy("REDEEM_NFT_REFERRAL_FEE").policyValue,
            calculateFeeFromPolicy(value, "REDEEM_NFT_REFERRAL_FEE")
        );
        return founderFee + custodianFee + platformFee + referralFee;
    }

    function calculateRedeemFeeLists(NFTInfo memory info, uint256 auctionValue)
        public
        view
        returns (TransferARA[] memory f)
    {
        uint256 value = max(
            auctionValue,
            max(info.buyItNow.value, info.offer.value)
        );
        uint256 founderFee = max(
            info.fee.founderGeneralFee,
            (value * info.fee.founderRedeemWeight) / info.fee.maxWeight
        );
        uint256 custodianFee = max(
            info.fee.custodianGeneralFee,
            (value * info.fee.custodianRedeemWeight) / info.fee.maxWeight
        );
        uint256 platformFee = max(
            g().getPolicy("REDEEM_NFT_PLATFORM_FEE").policyValue,
            calculateFeeFromPolicy(value, "REDEEM_NFT_PLATFORM_FEE")
        );
        uint256 referralFee = max(
            g().getPolicy("REDEEM_NFT_REFERRAL_FEE").policyValue,
            calculateFeeFromPolicy(value, "REDEEM_NFT_REFERRAL_FEE")
        );

        TransferARA[] memory feeLists = new TransferARA[](4);
        feeLists[0] = TransferARA({
            receiver: info.addr.founder,
            amount: founderFee
        });
        feeLists[1] = TransferARA({
            receiver: info.addr.custodian,
            amount: custodianFee
        });
        feeLists[2] = TransferARA({
            receiver: g().getManagementFundContract(),
            amount: platformFee
        });
        feeLists[3] = TransferARA({
            receiver: m().getReferral(info.addr.owner),
            amount: referralFee
        });

        return feeLists;
    }

    function calculateTransferFee(NFTInfo memory info, uint256 auctionValue)
        public
        view
        returns (uint256)
    {
        uint256 value = max(
            auctionValue,
            max(info.buyItNow.value, info.offer.value)
        );
        uint256 founderFee = max(
            info.fee.founderGeneralFee,
            (value * info.fee.founderWeight) / info.fee.maxWeight
        );
        uint256 custodianFee = max(
            info.fee.custodianGeneralFee,
            (value * info.fee.custodianWeight) / info.fee.maxWeight
        );
        uint256 platformFee = max(
            g().getPolicy("TRANSFER_NFT_PLATFORM_FEE").policyValue,
            calculateFeeFromPolicy(value, "TRANSFER_NFT_PLATFORM_FEE")
        );
        uint256 referralSenderFee = max(
            g().getPolicy("TRANSFER_NFT_REFERRAL_SENDER_FEE").policyValue,
            calculateFeeFromPolicy(value, "TRANSFER_NFT_REFERRAL_SENDER_FEE")
        );
        uint256 referralReceiverFee = max(
            g().getPolicy("TRANSFER_NFT_REFERRAL_RECEIVER_FEE").policyValue,
            calculateFeeFromPolicy(value, "TRANSFER_NFT_REFERRAL_RECEIVER_FEE")
        );
        return
            founderFee +
            custodianFee +
            platformFee +
            referralSenderFee +
            referralReceiverFee;
    }

    function calculateTransferFeeLists(
        NFTInfo memory info,
        uint256 auctionValue,
        address sender,
        address receiver
    ) public view returns (TransferARA[] memory f) {
        uint256 value = max(
            auctionValue,
            max(info.buyItNow.value, info.offer.value)
        );

        TransferARA[] memory feeLists = new TransferARA[](5);
        feeLists[0] = TransferARA({
            receiver: info.addr.founder,
            amount: max(
                info.fee.founderGeneralFee,
                (value * info.fee.founderWeight) / info.fee.maxWeight
            )
        });
        feeLists[1] = TransferARA({
            receiver: info.addr.custodian,
            amount: max(
                info.fee.custodianGeneralFee,
                (value * info.fee.custodianWeight) / info.fee.maxWeight
            )
        });
        feeLists[2] = TransferARA({
            receiver: g().getManagementFundContract(),
            amount: max(
                g().getPolicy("TRANSFER_NFT_PLATFORM_FEE").policyValue,
                calculateFeeFromPolicy(value, "TRANSFER_NFT_PLATFORM_FEE")
            )
        });
        feeLists[3] = TransferARA({
            receiver: m().getReferral(sender),
            amount: max(
                g().getPolicy("TRANSFER_NFT_REFERRAL_SENDER_FEE").policyValue,
                calculateFeeFromPolicy(
                    value,
                    "TRANSFER_NFT_REFERRAL_SENDER_FEE"
                )
            )
        });
        feeLists[4] = TransferARA({
            receiver: m().getReferral(receiver),
            amount: max(
                g().getPolicy("TRANSFER_NFT_REFERRAL_RECEIVER_FEE").policyValue,
                calculateFeeFromPolicy(
                    value,
                    "TRANSFER_NFT_REFERRAL_RECEIVER_FEE"
                )
            )
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
}
