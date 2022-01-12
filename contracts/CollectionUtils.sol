pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ARAToken.sol";
import "./CollectionDataType.sol";
import "./Governance.sol";
import "./Member.sol";
import "./NFTFactory.sol";
import "./BancorFormula.sol";

contract CollectionUtils is CollectionDataType {
    address private governanceContract;

    constructor(address _governanceContract) {
        governanceContract = _governanceContract;
    }

    function g() private view returns (Governance) {
        return Governance(governanceContract);
    }

    function m() private view returns (Member) {
        return Member(g().getMemberContract());
    }

    function t() private view returns (ARAToken) {
        return ARAToken(g().getARATokenContract());
    }

    function b() private view returns (BancorFormula) {
        return BancorFormula(g().getBancorFormulaContract());
    }

    function max(uint256 x, uint256 y) public view returns (uint256) {
        return x > y ? x : y;
    }

    function min(uint256 x, uint256 y) public view returns (uint256) {
        return x < y ? x : y;
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

    function requireBuy(
        address sender,
        uint256 amount,
        CollectionInfo memory info
    ) public view {
        require(
            m().isMember(sender) &&
                t().balanceOf(sender) >= amount &&
                !info.auction &&
                !info.freeze
        );
    }

    function calculateBuyTransferFeeLists(
        uint256 amount,
        address sender,
        CollectionInfo memory info
    ) public view returns (TransferARA[] memory f) {
        uint256 collectorFee = (amount * info.collectorFeeWeight) /
            info.maxWeight;
        uint256 platformFee = calculateFeeFromPolicy(
            amount,
            "BUY_COLLECTION_PLATFORM_FEE"
        );
        uint256 referralInvestorFee = calculateFeeFromPolicy(
            amount,
            "BUY_COLLECTION_REFERRAL_INVESTOR_FEE"
        );
        uint256 referralCollectorFee = calculateFeeFromPolicy(
            amount,
            "BUY_COLLECTION_REFERRAL_COLLECTOR_FEE"
        );

        TransferARA[] memory feeLists = new TransferARA[](4);
        feeLists[0] = TransferARA({
            receiver: info.collector,
            amount: collectorFee
        });
        feeLists[1] = TransferARA({
            receiver: g().getManagementFundContract(),
            amount: platformFee
        });
        feeLists[2] = TransferARA({
            receiver: m().getReferral(msg.sender),
            amount: referralInvestorFee
        });
        feeLists[3] = TransferARA({
            receiver: m().getReferral(info.collector),
            amount: referralCollectorFee
        });
    }

    function requireSell(
        address sender,
        uint256 amount,
        CollectionInfo memory info,
        bool hasEnoughtToken,
        bool isShareholderExists
    ) public view {
        require(
            m().isMember(sender) &&
                hasEnoughtToken &&
                isShareholderExists &&
                !info.auction &&
                !info.freeze
        );
    }

    function calculateSellTransferFeeLists(
        uint256 withdrawAmount,
        address sender,
        CollectionInfo memory info
    ) public view returns (TransferARA[] memory f) {
        uint256 collectorFee = (withdrawAmount * info.collectorFeeWeight) /
            info.maxWeight;
        uint256 platformFee = calculateFeeFromPolicy(
            withdrawAmount,
            "SELL_COLLECTION_PLATFORM_FEE"
        );
        uint256 referralInvestorFee = calculateFeeFromPolicy(
            withdrawAmount,
            "SELL_COLLECTION_REFERRAL_INVESTOR_FEE"
        );
        uint256 referralCollectorFee = calculateFeeFromPolicy(
            withdrawAmount,
            "SELL_COLLECTION_REFERRAL_COLLECTOR_FEE"
        );
        uint256 sellAmount = withdrawAmount -
            platformFee -
            referralInvestorFee -
            referralCollectorFee;
        TransferARA[] memory feeLists = new TransferARA[](5);
        feeLists[0] = TransferARA({
            receiver: info.collector,
            amount: collectorFee
        });
        feeLists[1] = TransferARA({
            receiver: g().getManagementFundContract(),
            amount: platformFee
        });
        feeLists[2] = TransferARA({
            receiver: m().getReferral(sender),
            amount: referralInvestorFee
        });
        feeLists[3] = TransferARA({
            receiver: m().getReferral(info.collector),
            amount: referralCollectorFee
        });
        feeLists[4] = TransferARA({receiver: sender, amount: sellAmount});

        return feeLists;
    }

    function calculatePurchaseReturn(
        uint256 amount,
        CollectionInfo memory info,
        uint256 totalSupply,
        uint256 currentCollateral
    ) public view returns (uint256) {
        uint256 collectorFee = (amount * info.collectorFeeWeight) /
            info.maxWeight;
        uint256 platformFee = calculateFeeFromPolicy(
            amount,
            "BUY_COLLECTION_PLATFORM_FEE"
        );
        uint256 referralInvestorFee = calculateFeeFromPolicy(
            amount,
            "BUY_COLLECTION_REFERRAL_INVESTOR_FEE"
        );
        uint256 referralCollectorFee = calculateFeeFromPolicy(
            amount,
            "BUY_COLLECTION_REFERRAL_COLLECTOR_FEE"
        );
        uint256 buyAmount = amount -
            collectorFee -
            platformFee -
            referralInvestorFee -
            referralCollectorFee;
        uint256 mintAmount = b().purchaseTargetAmount(
            totalSupply,
            currentCollateral,
            uint32(info.collateralWeight),
            buyAmount
        );

        return mintAmount;
    }

    function calculateBurnAmount(
        uint256 amount,
        CollectionInfo memory info,
        uint256 totalSupply,
        uint256 currentCollateral
    ) public view returns (uint256) {
        return
            b().saleTargetAmount(
                totalSupply,
                currentCollateral,
                uint32(info.collateralWeight),
                amount
            );
    }

    function calculateWithdrawAmount(uint256 burnAmount)
        public
        view
        returns (uint256)
    {
        return min(t().balanceOf(address(this)), burnAmount);
    }

    // f(inputCollectionToken) -> outputARA
    function calculateSaleReturn(
        uint256 amount,
        CollectionInfo memory info,
        uint256 totalSupply,
        uint256 currentCollateral
    ) public view returns (uint256) {
        uint256 withdrawAmount = calculateWithdrawAmount(
            calculateBurnAmount(amount, info, totalSupply, currentCollateral)
        );

        uint256 collectorFee = (withdrawAmount * info.collectorFeeWeight) /
            info.maxWeight;
        uint256 platformFee = calculateFeeFromPolicy(
            withdrawAmount,
            "SELL_COLLECTION_PLATFORM_FEE"
        );
        uint256 referralInvestorFee = calculateFeeFromPolicy(
            withdrawAmount,
            "SELL_COLLECTION_REFERRAL_INVESTOR_FEE"
        );
        uint256 referralCollectorFee = calculateFeeFromPolicy(
            withdrawAmount,
            "SELL_COLLECTION_REFERRAL_COLLECTOR_FEE"
        );
        return
            withdrawAmount -
            collectorFee -
            platformFee -
            referralInvestorFee -
            referralCollectorFee;
    }

    // f(outputCollectionToken) -> inputARA
    function calculateFundCost(
        uint256 amount,
        CollectionInfo memory info,
        uint256 totalSupply,
        uint256 currentCollateral
    ) public view returns (uint256) {
        uint256 collectorFee = (amount * info.collectorFeeWeight) /
            info.maxWeight;
        uint256 platformFee = calculateFeeFromPolicy(
            amount,
            "BUY_COLLECTION_PLATFORM_FEE"
        );
        uint256 referralInvestorFee = calculateFeeFromPolicy(
            amount,
            "BUY_COLLECTION_REFERRAL_INVESTOR_FEE"
        );
        uint256 referralCollectorFee = calculateFeeFromPolicy(
            amount,
            "BUY_COLLECTION_REFERRAL_COLLECTOR_FEE"
        );
        uint256 adjAmount = amount +
            collectorFee +
            platformFee +
            referralInvestorFee +
            referralCollectorFee;

        return
            b().fundCost(
                totalSupply,
                currentCollateral,
                uint32(info.collateralWeight),
                adjAmount
            );
    }

    // f(outputARA) -> inputCollectionToken
    function calculateLiquidateCost(
        uint256 amount,
        CollectionInfo memory info,
        uint256 totalSupply,
        uint256 currentCollateral
    ) public view returns (uint256) {
        uint256 collectorFee = (amount * info.collectorFeeWeight) /
            info.maxWeight;
        uint256 platformFee = calculateFeeFromPolicy(
            amount,
            "SELL_COLLECTION_PLATFORM_FEE"
        );
        uint256 referralInvestorFee = calculateFeeFromPolicy(
            amount,
            "SELL_COLLECTION_REFERRAL_INVESTOR_FEE"
        );
        uint256 referralCollectorFee = calculateFeeFromPolicy(
            amount,
            "SELL_COLLECTION_REFERRAL_COLLECTOR_FEE"
        );
        uint256 adjAmount = amount +
            collectorFee +
            platformFee +
            referralInvestorFee +
            referralCollectorFee;

        return
            b().liquidateCost(
                totalSupply,
                currentCollateral,
                uint32(info.collateralWeight),
                adjAmount
            );
    }
}
