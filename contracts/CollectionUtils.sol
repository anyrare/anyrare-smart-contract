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

    function calculatePurchaseFeeStruct(
        uint256 amount,
        uint256 collectorFeeWeight,
        uint256 maxWeight
    ) private view returns (CollectionPurchaseFee memory fees) {
        CollectionPurchaseFee memory f = CollectionPurchaseFee({
            _collectorFee: (amount * collectorFeeWeight) / maxWeight,
            platformCollectorFee: 0,
            referralCollectorFee: 0,
            collectorFee: 0,
            platformFee: 0,
            referralInvestorFee: calculateFeeFromPolicy(
                amount,
                "BUY_COLLECTION_REFERRAL_INVESTOR_FEE"
            )
        });

        f.platformCollectorFee = calculateFeeFromPolicy(
            f._collectorFee,
            "BUY_COLLECTION_PLATFORM_COLLECTOR_FEE"
        );
        f.referralCollectorFee = calculateFeeFromPolicy(
            f._collectorFee,
            "BUY_COLLECTION_REFERRAL_COLLECTOR_FEE"
        );
        f.collectorFee =
            f._collectorFee -
            f.platformCollectorFee -
            f.referralCollectorFee;
        f.referralInvestorFee = calculateFeeFromPolicy(
            amount,
            "BUY_COLLECTION_REFERRAL_INVESTOR_FEE"
        );
        f.platformFee =
            calculateFeeFromPolicy(amount, "BUY_COLLECTION_PLATFORM_FEE") +
            f.platformCollectorFee;

        return f;
    }

    function calculateBuyTransferFeeLists(
        uint256 amount,
        address sender,
        CollectionInfo memory info
    ) public view returns (TransferARA[] memory fees) {
        CollectionPurchaseFee memory f = calculatePurchaseFeeStruct(
            amount,
            info.collectorFeeWeight,
            info.maxWeight
        );

        TransferARA[] memory feeLists = new TransferARA[](4);
        feeLists[0] = TransferARA({
            receiver: info.collector,
            amount: f.collectorFee
        });
        feeLists[1] = TransferARA({
            receiver: g().getManagementFundContract(),
            amount: f.platformFee
        });
        feeLists[2] = TransferARA({
            receiver: m().getReferral(sender),
            amount: f.referralInvestorFee
        });
        feeLists[3] = TransferARA({
            receiver: m().getReferral(info.collector),
            amount: f.referralCollectorFee
        });

        return feeLists;
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

    function calculateSaleFeeStruct(
        uint256 amount,
        uint256 collectorFeeWeight,
        uint256 maxWeight
    ) private view returns (CollectionSaleFee memory fees) {
        CollectionSaleFee memory f = CollectionSaleFee({
            _collectorFee: (amount * collectorFeeWeight) / maxWeight,
            platformCollectorFee: 0,
            referralCollectorFee: 0,
            collectorFee: 0,
            platformFee: 0,
            referralInvestorFee: calculateFeeFromPolicy(
                amount,
                "SELL_COLLECTION_REFERRAL_INVESTOR_FEE"
            )
        });

        f.platformCollectorFee = calculateFeeFromPolicy(
            f._collectorFee,
            "SELL_COLLECTION_PLATFORM_COLLECTOR_FEE"
        );
        f.referralCollectorFee = calculateFeeFromPolicy(
            f._collectorFee,
            "SELL_COLLECTION_REFERRAL_COLLECTOR_FEE"
        );
        f.collectorFee =
            f._collectorFee -
            f.platformCollectorFee -
            f.referralCollectorFee;
        f.platformFee =
            calculateFeeFromPolicy(amount, "SELL_COLLECTION_PLATFORM_FEE") +
            f.platformCollectorFee;

        return f;
    }

    function calculateSellTransferFeeLists(
        uint256 withdrawAmount,
        address sender,
        CollectionInfo memory info
    ) public view returns (TransferARA[] memory f) {
        CollectionSaleFee memory f = calculateSaleFeeStruct(
            withdrawAmount,
            info.collectorFeeWeight,
            info.maxWeight
        );

        uint256 sellAmount = withdrawAmount -
            f.platformFee -
            f.referralInvestorFee -
            f.referralCollectorFee;

        TransferARA[] memory feeLists = new TransferARA[](5);
        feeLists[0] = TransferARA({
            receiver: info.collector,
            amount: f.collectorFee
        });
        feeLists[1] = TransferARA({
            receiver: g().getManagementFundContract(),
            amount: f.platformFee
        });
        feeLists[2] = TransferARA({
            receiver: m().getReferral(sender),
            amount: f.referralInvestorFee
        });
        feeLists[3] = TransferARA({
            receiver: m().getReferral(info.collector),
            amount: f.referralCollectorFee
        });
        feeLists[4] = TransferARA({receiver: sender, amount: sellAmount});

        return feeLists;
    }

    function _calculatePurchaseReturn(
        uint256 amount,
        uint256 collectorFeeWeight,
        uint256 collateralWeight,
        uint256 maxWeight,
        uint256 totalSupply,
        uint256 currentCollateral
    ) public view returns (uint256) {
        CollectionPurchaseFee memory f = calculatePurchaseFeeStruct(
            amount,
            collectorFeeWeight,
            maxWeight
        );

        uint256 buyAmount = amount -
            f.collectorFee -
            f.platformFee -
            f.referralInvestorFee -
            f.referralCollectorFee;

        uint256 mintAmount = b().purchaseTargetAmount(
            totalSupply,
            currentCollateral,
            uint32(collateralWeight),
            buyAmount
        );

        return mintAmount;
    }

    function calculatePurchaseReturn(
        uint256 amount,
        CollectionInfo memory info,
        uint256 totalSupply,
        uint256 currentCollateral
    ) public view returns (uint256) {
        return
            _calculatePurchaseReturn(
                amount,
                info.collectorFeeWeight,
                info.collateralWeight,
                info.maxWeight,
                totalSupply,
                currentCollateral
            );
    }

    function _calculateBurnAmount(
        uint256 amount,
        uint256 collateralWeight,
        uint256 totalSupply,
        uint256 currentCollateral
    ) public view returns (uint256) {
        return
            b().saleTargetAmount(
                totalSupply,
                currentCollateral,
                uint32(collateralWeight),
                amount
            );
    }

    function calculateBurnAmount(
        uint256 amount,
        CollectionInfo memory info,
        uint256 totalSupply,
        uint256 currentCollateral
    ) public view returns (uint256) {
        return
            _calculateBurnAmount(
                amount,
                info.collateralWeight,
                totalSupply,
                currentCollateral
            );
    }

    function calculateWithdrawAmount(uint256 burnAmount)
        public
        view
        returns (uint256)
    {
        return min(t().balanceOf(address(this)), burnAmount);
    }

    function _calculateSaleReturn(
        uint256 amount,
        uint256 withdrawAmount,
        uint256 collectorFeeWeight,
        uint256 collateralWeight,
        uint256 maxWeight,
        uint256 totalSupply,
        uint256 currentCollateral
    ) public view returns (uint256) {
        CollectionSaleFee memory f = calculateSaleFeeStruct(
            withdrawAmount,
            collectorFeeWeight,
            maxWeight
        );

        return
            withdrawAmount -
            f.collectorFee -
            f.platformFee -
            f.referralInvestorFee -
            f.referralCollectorFee;
    }

    // f(inputCollectionToken) -> outputARA
    function calculateSaleReturn(
        uint256 amount,
        CollectionInfo memory info,
        uint256 totalSupply,
        uint256 currentCollateral
    ) public view returns (uint256) {
        return
            _calculateSaleReturn(
                amount,
                calculateWithdrawAmount(
                    _calculateBurnAmount(
                        amount,
                        info.collateralWeight,
                        totalSupply,
                        currentCollateral
                    )
                ),
                info.collectorFeeWeight,
                info.collateralWeight,
                info.maxWeight,
                totalSupply,
                currentCollateral
            );
    }

    function _calculateFundCost(
        uint256 amount,
        uint256 collectorFeeWeight,
        uint256 collateralWeight,
        uint256 maxWeight,
        uint256 totalSupply,
        uint256 currentCollateral
    ) public view returns (uint256) {
        CollectionPurchaseFee memory f = calculatePurchaseFeeStruct(
            amount,
            collectorFeeWeight,
            maxWeight
        );

        uint256 adjAmount = amount -
            f.collectorFee -
            f.platformFee -
            f.referralInvestorFee -
            f.referralCollectorFee;

        return
            b().fundCost(
                totalSupply,
                currentCollateral,
                uint32(collateralWeight),
                adjAmount
            );
    }

    // f(outputCollectionToken) -> inputARA
    function calculateFundCost(
        uint256 amount,
        CollectionInfo memory info,
        uint256 totalSupply,
        uint256 currentCollateral
    ) public view returns (uint256) {
        return
            _calculateFundCost(
                amount,
                info.collectorFeeWeight,
                info.collateralWeight,
                info.maxWeight,
                totalSupply,
                currentCollateral
            );
    }

    function _calculateLiquidateCost(
        uint256 amount,
        uint256 collectorFeeWeight,
        uint256 collateralWeight,
        uint256 maxWeight,
        uint256 totalSupply,
        uint256 currentCollateral
    ) public view returns (uint256) {
        CollectionSaleFee memory f = calculateSaleFeeStruct(
            amount,
            collectorFeeWeight,
            maxWeight
        );

        uint256 adjAmount = amount +
            f.collectorFee +
            f.platformFee +
            f.referralInvestorFee +
            f.referralCollectorFee;

        return
            b().liquidateCost(
                totalSupply,
                currentCollateral,
                uint32(collateralWeight),
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
        return
            _calculateLiquidateCost(
                amount,
                info.collectorFeeWeight,
                info.collateralWeight,
                info.maxWeight,
                totalSupply,
                currentCollateral
            );
    }
}
