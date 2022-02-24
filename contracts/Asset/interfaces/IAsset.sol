// SPDX-License-Identifier: MIT
interface IAsset {
    struct AssetMintArgs {
        address auditor;
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
}
