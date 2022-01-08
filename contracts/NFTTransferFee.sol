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

    function g() private returns (Governance) {
        return Governance(governanceContract);
    }

    function m() public returns (Member) {
        return Member(g().getMemberContract());
    }

    function t() public returns (ERC20) {
        return ERC20(g().getARATokenContract());
    }

    function calculateFeeFromPolicy(uint256 value, string memory policyName)
        public
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
    ) public {
        require(exists && !custodianSign && sender == custodian, "51");
    }

    function max(uint256 x, uint256 y) private pure returns (uint256) {
        return x > y ? x : y;
    }

    function min(uint256 x, uint256 y) private pure returns (uint256) {
        return x < y ? x : y;
    }

    function calculateAuctionTransferFeeLists(
        NFTInfoFee memory fee,
        NFTInfoAddress memory addr,
        NFTAuction memory auction
    ) public returns (TransferARA[] memory f) {
        uint256 founderRoyaltyFee = (auction.value * fee.founderRoyaltyWeight) /
            fee.maxWeight;
        uint256 custodianFee = (auction.value * fee.custodianFeeWeight) /
            fee.maxWeight;
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
            receiver: addr.founder,
            amount: founderRoyaltyFee
        });
        feeLists[1] = TransferARA({
            receiver: addr.custodian,
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

    function calculateOfferTransferFeeLists(
        NFTInfoFee memory fee,
        NFTInfoAddress memory addr,
        NFTOffer memory offer
    ) public returns (TransferARA[] memory f) {
        uint256 founderRoyaltyFee = (offer.value * fee.founderRoyaltyWeight) /
            fee.maxWeight;
        uint256 custodianFee = (offer.value * fee.custodianFeeWeight) /
            fee.maxWeight;
        uint256 platformFee = calculateFeeFromPolicy(
            offer.value,
            "OFFER_NFT_PLATFORM_FEE"
        );
        uint256 referralBuyerFee = calculateFeeFromPolicy(
            offer.value,
            "OFFER_NFT_REFERRAL_BUYER_FEE"
        );
        uint256 referralSellerFee = calculateFeeFromPolicy(
            offer.value,
            "OFFER_NFT_REFERRAL_SELLER_FEE"
        );

        TransferARA[] memory feeLists = new TransferARA[](6);
        feeLists[0] = TransferARA({
            receiver: addr.founder,
            amount: founderRoyaltyFee
        });
        feeLists[1] = TransferARA({
            receiver: addr.custodian,
            amount: custodianFee
        });
        feeLists[2] = TransferARA({
            receiver: g().getManagementFundContract(),
            amount: platformFee
        });
        feeLists[3] = TransferARA({
            receiver: m().getReferral(offer.bidder),
            amount: referralBuyerFee
        });
        feeLists[4] = TransferARA({
            receiver: m().getReferral(offer.owner),
            amount: referralSellerFee
        });
        feeLists[5] = TransferARA({
            receiver: offer.owner,
            amount: offer.value -
                founderRoyaltyFee -
                custodianFee -
                platformFee -
                referralBuyerFee -
                referralSellerFee
        });

        return feeLists;
    }

    function calculateBuyItNowTransferFeeLists(
        NFTInfoFee memory fee,
        NFTInfoAddress memory addr,
        NFTBuyItNow memory buyItNow,
        address buyer
    ) public returns (TransferARA[] memory f) {
        uint256 founderRoyaltyFee = (buyItNow.value *
            fee.founderRoyaltyWeight) / fee.maxWeight;
        uint256 custodianFee = (buyItNow.value * fee.custodianFeeWeight) /
            fee.maxWeight;
        uint256 platformFee = calculateFeeFromPolicy(
            buyItNow.value,
            "BUY_IT_NOW_NFT_PLATFORM_FEE"
        );
        uint256 referralBuyerFee = calculateFeeFromPolicy(
            buyItNow.value,
            "BUY_IT_NOW_NFT_REFERRAL_BUYER_FEE"
        );
        uint256 referralSellerFee = calculateFeeFromPolicy(
            buyItNow.value,
            "BUY_IT_NOW_NFT_REFERRAL_SELLER_FEE"
        );

        TransferARA[] memory feeLists = new TransferARA[](6);
        feeLists[0] = TransferARA({
            receiver: addr.founder,
            amount: founderRoyaltyFee
        });
        feeLists[1] = TransferARA({
            receiver: addr.custodian,
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
            receiver: m().getReferral(buyItNow.owner),
            amount: referralSellerFee
        });
        feeLists[5] = TransferARA({
            receiver: buyItNow.owner,
            amount: buyItNow.value -
                founderRoyaltyFee -
                custodianFee -
                platformFee -
                referralBuyerFee -
                referralSellerFee
        });

        return feeLists;
    }

    function calculateRedeemFee(
        NFTInfoFee memory fee,
        uint256 auctionValue,
        uint256 buyValue
    ) public returns (uint256) {
        uint256 value = max(auctionValue, buyValue);
        uint256 founderFee = max(
            fee.founderRedeemFee,
            (value * fee.founderRedeemWeight) / fee.maxWeight
        );
        uint256 custodianFee = max(
            fee.custodianRedeemFee,
            (value * fee.custodianRedeemWeight) / fee.maxWeight
        );
        uint256 platformFee = max(
            g().getPolicy("REDEEM_NFT_PLATFORM_FEE").policyValue,
            calculateFeeFromPolicy(value, "REDEEM_NFT_PLATFORM_FEE")
        );
        uint256 referralFee = max(
            g().getPolicy("REDEEM_NFT_REFERRAL_FEE").policyValue,
            calculateFeeFromPolicy(value, "REDEEM_REFERRAL_FEE")
        );
        return founderFee + custodianFee + platformFee + referralFee;
    }

    function calculateRedeemFeeLists(
        NFTInfoAddress memory addr,
        NFTInfoFee memory fee,
        uint256 auctionValue,
        uint256 buyValue
    ) public returns (TransferARA[] memory f) {
        uint256 value = max(auctionValue, buyValue);
        uint256 founderFee = max(
            fee.founderRedeemFee,
            (value * fee.founderRedeemWeight) / fee.maxWeight
        );
        uint256 custodianFee = max(
            fee.custodianRedeemFee,
            (value * fee.custodianRedeemWeight) / fee.maxWeight
        );
        uint256 platformFee = max(
            g().getPolicy("REDEEM_NFT_PLATFORM_FEE").policyValue,
            calculateFeeFromPolicy(value, "REDEEM_NFT_PLATFORM_FEE")
        );
        uint256 referralFee = max(
            g().getPolicy("REDEEM_NFT_REFERRAL_FEE").policyValue,
            calculateFeeFromPolicy(value, "REDEEM_REFERRAL_FEE")
        );

        TransferARA[] memory feeLists = new TransferARA[](4);
        feeLists[0] = TransferARA({receiver: addr.founder, amount: founderFee});
        feeLists[1] = TransferARA({
            receiver: addr.custodian,
            amount: custodianFee
        });
        feeLists[2] = TransferARA({
            receiver: g().getManagementFundContract(),
            amount: platformFee
        });
        feeLists[3] = TransferARA({
            receiver: m().getReferral(addr.owner),
            amount: referralFee
        });

        return feeLists;
    }

    function calculateTransferFee(
        NFTInfoFee memory fee,
        uint256 auctionValue,
        uint256 buyValue
    ) public returns (uint256) {
        uint256 value = max(auctionValue, buyValue);
        uint256 founderFee = max(
            fee.founderRedeemFee,
            (value * fee.founderRedeemWeight) / fee.maxWeight
        );
        uint256 custodianFee = max(
            fee.custodianRedeemFee,
            (value * fee.custodianRedeemWeight) / fee.maxWeight
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
        NFTInfoAddress memory addr,
        NFTInfoFee memory fee,
        uint256 auctionValue,
        uint256 buyValue,
        address sender,
        address receiver
    ) public returns (TransferARA[] memory f) {
        uint256 value = max(auctionValue, buyValue);
        uint256 founderFee = max(
            fee.founderRedeemFee,
            (value * fee.founderRedeemWeight) / fee.maxWeight
        );
        uint256 custodianFee = max(
            fee.custodianRedeemFee,
            (value * fee.custodianRedeemWeight) / fee.maxWeight
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

        TransferARA[] memory feeLists = new TransferARA[](5);
        feeLists[0] = TransferARA({receiver: addr.founder, amount: founderFee});
        feeLists[1] = TransferARA({
            receiver: addr.custodian,
            amount: custodianFee
        });
        feeLists[2] = TransferARA({
            receiver: g().getManagementFundContract(),
            amount: platformFee
        });
        feeLists[3] = TransferARA({
            receiver: m().getReferral(sender),
            amount: referralSenderFee
        });
        feeLists[4] = TransferARA({
            receiver: m().getReferral(receiver),
            amount: referralReceiverFee
        });

        return feeLists;
    }

    function requirePayFeeAndClaimToken(
        bool exists,
        NFTStatus memory status,
        NFTInfoAddress memory addr,
        NFTInfoFee memory fee,
        address sender
    ) public {
        require(
            exists &&
                status.custodianSign &&
                !status.claim &&
                (addr.founder == sender ||
                    (addr.custodian == sender &&
                        block.timestamp >=
                        g()
                            .getPolicy("NFT_CUSTODIAN_CAN_CLAIM_DURATION")
                            .policyValue)) &&
                t().balanceOf(sender) >= fee.auditFee + fee.mintFee
        );
    }

    function requireOpenAuction(
        bool isOwner,
        NFTStatus memory status,
        address sender
    ) public {
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
    ) public {
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
        bool exists,
        bool isOwner,
        NFTStatus memory status,
        address sender,
        uint256 value,
        uint256 platformFee,
        uint256 referralFee
    ) public {
        require(
            exists &&
                isOwner &&
                !status.auction &&
                !status.buyItNow &&
                !status.lockInCollection &&
                !status.redeem &&
                !status.freeze &&
                m().isMember(sender) &&
                value > 0 &&
                t().balanceOf(sender) >= platformFee + referralFee
        );
    }

    function requireBuyFromBuyItNow(
        bool exists,
        bool buyItNow,
        uint256 value,
        address sender
    ) public {
        require(
            exists &&
                buyItNow &&
                t().balanceOf(sender) >= value &&
                m().isMember(sender)
        );
    }

    function requireOpenOffer(
        bool exists,
        bool isOwner,
        NFTStatus memory status,
        NFTOffer memory offer,
        uint256 bidValue,
        address sender
    ) public {
        require(
            exists && !isOwner &&
                status.claim &&
                !status.auction &&
                !status.lockInCollection &&
                !status.redeem &&
                !status.freeze &&
                bidValue > offer.value &&
                t().balanceOf(sender) >=
                (sender == offer.bidder ? bidValue - offer.value : bidValue) &&
                
                m().isMember(sender)
        );
    }

    function requireRedeem(
        bool exists,
        NFTStatus memory status,
        bool isOwner
    ) public {
        require(
            exists &&
                isOwner &&
                !status.lockInCollection &&
                !status.auction &&
                !status.offer &&
                !status.redeem
        );
    }

    function requireTransfer(
        bool exists,
        NFTStatus memory status,
        bool isOwner,
        bool isSenderCorrect
    ) public {
        require(
            exists &&
                isOwner &&
                isSenderCorrect &&
                !status.lockInCollection &&
                !status.auction &&
                !status.redeem &&
                !status.freeze
        );
    }
}
