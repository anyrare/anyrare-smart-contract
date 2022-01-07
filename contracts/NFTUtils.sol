pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Utils.sol";
import "./NFTDataType.sol";

contract NFTUtils is NFTDataType {
    address private governanceContract;

    constructor(address _governanceContract) {
        governanceContract = _governanceContract;
    }

    function g() private returns (Governance) {
        return Governance(governanceContract);
    }

    function u() private returns (Utils) {
        return Utils(g().getUtilsContract());
    }

    function processAuctionTransferFee(
        NFTInfoFee memory fee,
        NFTInfoAddress memory addr,
        NFTAuction memory auction
    ) public payable {
        require(msg.sender == g().getNFTFactoryContract(), "11");

        uint256 founderRoyaltyFee = (auction.value * fee.founderRoyaltyWeight) /
            fee.maxWeight;
        uint256 custodianFee = (auction.value * fee.custodianFeeWeight) /
            fee.maxWeight;
        uint256 platformFee = u().calculateFeeFromPolicy(
            auction.value,
            "CLOSE_AUCTION_NFT_PLATFORM_FEE"
        );
        uint256 referralBuyerFee = u().calculateFeeFromPolicy(
            auction.value,
            "CLOSE_AUCTION_NFT_REFERRAL_BUYER_FEE"
        );
        uint256 referralSellerFee = u().calculateFeeFromPolicy(
            auction.value,
            "CLOSE_AUCTION_NFT_REFERRAL_SELLER_FEE"
        );

        u().transferARA(
            g().getNFTFactoryContract(),
            addr.founder,
            founderRoyaltyFee
        );
        u().transferARA(
            g().getNFTFactoryContract(),
            addr.custodian,
            custodianFee
        );
        u().transferARA(
            g().getNFTFactoryContract(),
            u().getManagementFundContract(),
            platformFee
        );
        u().transferARA(
            g().getNFTFactoryContract(),
            u().getReferral(auction.bidder),
            referralBuyerFee
        );
        u().transferARA(
            g().getNFTFactoryContract(),
            u().getReferral(auction.owner),
            referralSellerFee
        );
        u().transferARA(
            g().getNFTFactoryContract(),
            auction.owner,
            auction.value -
                founderRoyaltyFee -
                custodianFee -
                platformFee -
                referralBuyerFee -
                referralSellerFee
        );
        u().transferARA(
            g().getNFTFactoryContract(),
            auction.bidder,
            auction.maxBid - auction.value
        );
    }

    function buyFromBuyItNowTransferFee(
        NFTInfoFee memory fee,
        NFTInfoAddress memory addr,
        NFTBuyItNow memory buyItNow
    ) public payable {
        require(msg.sender == g().getNFTFactoryContract(), "11");

        uint256 founderRoyaltyFee = (buyItNow.value *
            fee.founderRoyaltyWeight) / fee.maxWeight;
        uint256 custodianFee = (buyItNow.value * fee.custodianFeeWeight) /
            fee.maxWeight;
        uint256 platformFee = u().calculateFeeFromPolicy(
            buyItNow.value,
            "BUY_IT_NOW_NFT_PLATFORM_FEE"
        );
        uint256 referralBuyerFee = u().calculateFeeFromPolicy(
            buyItNow.value,
            "BUY_IT_NOW_NFT_REFERRAL_BUYER_FEE"
        );
        uint256 referralSellerFee = u().calculateFeeFromPolicy(
            buyItNow.value,
            "BUY_IT_NOW_NFT_REFERRAL_SELLER_FEE"
        );

        u().transferARA(
            g().getNFTFactoryContract(),
            addr.founder,
            (buyItNow.value * fee.founderRoyaltyWeight) / fee.maxWeight
        );
        u().transferARA(
            g().getNFTFactoryContract(),
            addr.custodian,
            custodianFee
        );
        u().transferARA(
            g().getNFTFactoryContract(),
            u().getManagementFundContract(),
            platformFee
        );
        u().transferARA(
            g().getNFTFactoryContract(),
            u().getReferral(msg.sender),
            referralBuyerFee
        );
        u().transferARA(
            g().getNFTFactoryContract(),
            u().getReferral(buyItNow.owner),
            referralSellerFee
        );

        u().transferARA(
            g().getNFTFactoryContract(),
            buyItNow.owner,
            buyItNow.value -
                founderRoyaltyFee -
                custodianFee -
                platformFee -
                referralBuyerFee -
                referralSellerFee
        );
    }

    function acceptOfferTransferFee(
        NFTInfoFee memory fee,
        NFTInfoAddress memory addr,
        NFTOffer memory offer
    ) public payable {
        require(msg.sender == g().getNFTFactoryContract(), "11");

        uint256 founderRoyaltyFee = (offer.value * fee.founderRoyaltyWeight) /
            fee.maxWeight;
        uint256 custodianFee = (offer.value * fee.custodianFeeWeight) /
            fee.maxWeight;
        uint256 platformFee = u().calculateFeeFromPolicy(
            offer.value,
            "OFFER_NFT_PLATFORM_FEE"
        );
        uint256 referralBuyerFee = u().calculateFeeFromPolicy(
            offer.value,
            "OFFER_NFT_REFERRAL_BUYER_FEE"
        );
        uint256 referralSellerFee = u().calculateFeeFromPolicy(
            offer.value,
            "OFFER_NFT_REFERRAL_SELLER_FEE"
        );

        u().transferARA(
            g().getNFTFactoryContract(),
            addr.founder,
            founderRoyaltyFee
        );
        u().transferARA(
            g().getNFTFactoryContract(),
            addr.custodian,
            custodianFee
        );
        u().transferARA(
            g().getNFTFactoryContract(),
            u().getManagementFundContract(),
            platformFee
        );
        u().transferARA(
            g().getNFTFactoryContract(),
            u().getReferral(offer.bidder),
            referralBuyerFee
        );
        u().transferARA(
            g().getNFTFactoryContract(),
            u().getReferral(offer.owner),
            referralSellerFee
        );
        u().transferARA(
            g().getNFTFactoryContract(),
            offer.owner,
            offer.value -
                founderRoyaltyFee -
                custodianFee -
                platformFee -
                referralBuyerFee -
                referralSellerFee
        );
    }
}
