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
        NFTFee memory fee,
        NFTAddress memory addr,
        NFTAuction memory auction
    ) public view returns (TransferARA[] memory f) {
        uint256 founderRoyaltyFee = (auction.value * fee.founderWeight) /
            fee.maxWeight;
        uint256 custodianFee = (auction.value * fee.custodianWeight) /
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
        NFTFee memory fee,
        NFTAddress memory addr,
        NFTOffer memory offer
    ) public view returns (TransferARA[] memory f) {
        uint256 founderRoyaltyFee = (offer.value * fee.founderWeight) /
            fee.maxWeight;
        uint256 custodianFee = (offer.value * fee.custodianWeight) /
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
        NFTFee memory fee,
        NFTAddress memory addr,
        NFTBuyItNow memory buyItNow,
        address buyer
    ) public view returns (TransferARA[] memory f) {
        uint256 founderRoyaltyFee = (buyItNow.value * fee.founderWeight) /
            fee.maxWeight;
        uint256 custodianFee = (buyItNow.value * fee.custodianWeight) /
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
        NFTFee memory fee,
        uint256 auctionValue,
        uint256 buyValue,
        uint256 offerValue
    ) public view returns (uint256) {
        uint256 value = max(auctionValue, max(buyValue, offerValue));
        uint256 founderFee = max(
            fee.founderGeneralFee,
            (value * fee.founderRedeemWeight) / fee.maxWeight
        );
        uint256 custodianFee = max(
            fee.custodianGeneralFee,
            (value * fee.custodianRedeemWeight) / fee.maxWeight
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

    function calculateRedeemFeeLists(
        NFTAddress memory addr,
        NFTFee memory fee,
        uint256 auctionValue,
        uint256 buyValue,
        uint256 offerValue
    ) public view returns (TransferARA[] memory f) {
        uint256 value = max(auctionValue, max(buyValue, offerValue));
        uint256 founderFee = max(
            fee.founderGeneralFee,
            (value * fee.founderRedeemWeight) / fee.maxWeight
        );
        uint256 custodianFee = max(
            fee.custodianGeneralFee,
            (value * fee.custodianRedeemWeight) / fee.maxWeight
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
        NFTFee memory fee,
        uint256 auctionValue,
        uint256 buyValue,
        uint256 offerValue
    ) public view returns (uint256) {
        uint256 value = max(auctionValue, max(buyValue, offerValue));
        uint256 founderFee = max(
            fee.founderGeneralFee,
            (value * fee.founderWeight) / fee.maxWeight
        );
        uint256 custodianFee = max(
            fee.custodianGeneralFee,
            (value * fee.custodianWeight) / fee.maxWeight
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
        NFTAddress memory addr,
        NFTFee memory fee,
        uint256 auctionValue,
        uint256 buyValue,
        uint256 offerValue,
        address sender,
        address receiver
    ) public view returns (TransferARA[] memory f) {
        uint256 value = max(auctionValue, max(buyValue, offerValue));

        TransferARA[] memory feeLists = new TransferARA[](5);
        feeLists[0] = TransferARA({
            receiver: addr.founder,
            amount: max(
                fee.founderGeneralFee,
                (value * fee.founderWeight) / fee.maxWeight
            )
        });
        feeLists[1] = TransferARA({
            receiver: addr.custodian,
            amount: max(
                fee.custodianGeneralFee,
                (value * fee.custodianWeight) / fee.maxWeight
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

    function requirePayFeeAndClaimToken(
        bool exists,
        NFTStatus memory status,
        NFTAddress memory addr,
        NFTFee memory fee,
        address sender
    ) public view {
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
        bool exists,
        bool isOwner,
        NFTStatus memory status,
        address sender,
        uint256 value,
        uint256 platformFee,
        uint256 referralFee
    ) public view {
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
    ) public view {
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
    ) public view {
        require(
            exists &&
                !isOwner &&
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
    ) public view {
        require(
            exists &&
                isOwner &&
                !status.lockInCollection &&
                !status.auction &&
                !status.offer &&
                !status.redeem
        );
    }

    function requireRevertRedeem(
        NFTAddress memory addr,
        NFTStatus memory status,
        uint256 redeemTimestamp,
        address sender
    ) public view {
        require(
            addr.owner == sender &&
                status.redeem &&
                !status.freeze &&
                block.timestamp >=
                redeemTimestamp +
                    g().getPolicy("REDEEM_NFT_REVERT_DURATION").policyValue
        );
    }

    function requireTransfer(
        bool exists,
        NFTStatus memory status,
        bool isOwner,
        bool isSenderCorrect
    ) public view {
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
