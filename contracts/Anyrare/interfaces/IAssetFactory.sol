// SPDX-License-Identifier: MIT
interface IAssetFactory {
    struct AssetMintArgs {
        address founder;
        address custodian;
        string tokenURI;
        uint256 maxWeight;
        uint256 founderWeight;
        uint256 founderRedeemWeight;
        uint256 founderGeneralFee;
        uint256 auditFee;
        uint256 custodianWeight;
        uint256 custodianGeneralFee;
        uint256 custodianRedeemWeight;
    }

    struct AssetTransferFee {
        uint256 value;
        uint256 _founderFee;
        uint256 founderFee;
        uint256 referralFounderFee;
        uint256 platformFounderFee;
        uint256 _custodianFee;
        uint256 custodianFee;
        uint256 referralCustodianFee;
        uint256 platformCustodianFee;
        uint256 referralSenderFee;
        uint256 referralReceiverFee;
        uint256 platformFee;
    }

    struct AssetBuyItNowTransferFee {
        uint256 _founderFee;
        uint256 founderFee;
        uint256 referralFounderFee;
        uint256 platformFounderFee;
        uint256 _custodianFee;
        uint256 custodianFee;
        uint256 referralCustodianFee;
        uint256 platformCustodianFee;
        uint256 sellerFee;
        uint256 referralSellerFee;
        uint256 referralBuyerFee;
        uint256 platformFee;
    }

    struct AssetRedeemFee {
        uint256 value;
        uint256 _founderFee;
        uint256 founderFee;
        uint256 referralFounderFee;
        uint256 platformFounderFee;
        uint256 _custodianFee;
        uint256 custodianFee;
        uint256 referralCustodianFee;
        uint256 platformCustodianFee;
        uint256 referralOwnerFee;
        uint256 platformFee;
    }

    struct AssetOfferTransferFee {
        uint256 _founderFee;
        uint256 founderFee;
        uint256 referralFounderFee;
        uint256 platformFounderFee;
        uint256 _custodianFee;
        uint256 custodianFee;
        uint256 referralCustodianFee;
        uint256 platformCustodianFee;
        uint256 sellerFee;
        uint256 referralSellerFee;
        uint256 referralBuyerFee;
        uint256 platformFee;
    }

    struct AssetAuctionTransferFee {
        uint256 _founderFee;
        uint256 founderFee;
        uint256 referralFounderFee;
        uint256 platformFounderFee;
        uint256 _custodianFee;
        uint256 custodianFee;
        uint256 referralCustodianFee;
        uint256 platformCustodianFee;
        uint256 sellerFee;
        uint256 referralSellerFee;
        uint256 referralBuyerFee;
        uint256 platformFee;
    }
}
