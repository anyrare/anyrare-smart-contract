pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Member.sol";
import "./Governance.sol";
import "./converter/BancorFormula.sol";

contract CollectionToken is ERC20 {
    address private governanceContract;
    address private bancorFormulaContract;
    address public collectorAddr;

    uint256 public maxWeight;
    uint256 public collateralWeight;
    uint256 public collectorFeeWeight;
    uint32 public totalNft;

    uint256 public targetPrice;
    bool isAuction;
    bool isFreeze;

    mapping(uint32 => uint256) nfts;

    constructor(
        address _governanceContract,
        address _bancorFormulaContract,
        address _collectorAddr,
        string memory _name,
        string memory _symbol,
        uint256 _targetPrice,
        uint256 _initialAmount,
        uint32 _totalNft,
        uint256[] memory _nfts
    ) ERC20(_name, _symbol) {
        governanceContract = _governanceContract;
        require(
            _targetPrice > 0 && _initialAmount > 0 && isMember(_collectorAddr),
            "70"
        );

        for (uint32 i = 0; i < _totalNft; i++) {
            require(n().ownerOf(_nfts[i]) == msg.sender, "71");
        }

        // Check permission
        for (uint32 i = 0; i < _totalNft; i++) {
            n().transferFrom(msg.sender, address(this), _nfts[i]);
        }

        bancorFormulaContract = _bancorFormulaContract;
        collectorAddr = _collectorAddr;
        targetPrice = _targetPrice;
        totalNft = _totalNft;
        isAuction = false;
        isFreeze = false;

        _mint(collectorAddr, _initialAmount);
    }

    function g() private view returns (Governance) {
        return Governance(governanceContract);
    }

    function m() private view returns (Member) {
        return Member(g().getMemberContract());
    }

    function b() private view returns (BancorFormula) {
        return BancorFormula(bancorFormulaContract);
    }

    function c() private view returns (ERC20) {
        return ERC20(g().getARATokenContract());
    }

    function n() private view returns (ERC721) {
        return ERC721(g().getNFTFactoryContract());
    }

    function isMember(address account) private view returns (bool) {
        return m().isMember(account);
    }

    function max(uint256 a, uint256 b) private view returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) private view returns (uint256) {
        return a < b ? a : b;
    }

    function buy(uint256 amount) public payable {
        require(
            isMember(msg.sender) &&
                c().balanceOf(msg.sender) >= amount &&
                !isAuction &&
                !isFreeze,
            "72"
        );

        uint256 collectorFee = (amount * collectorFeeWeight) / maxWeight;
        uint256 platformFee = (amount *
            g().getPolicy("BUY_COLLECTION_PLATFORM_FEE").policyWeight) /
            g().getPolicy("BUY_COLLECTION_PLATFORM_FEE").maxWeight;
        uint256 referralBuyerFee = (amount *
            g().getPolicy("BUY_COLLECTION_REFERRAL_BUYER_FEE").policyWeight) /
            g().getPolicy("BUY_COLLECTION_REFERRAL_BUYER_FEE").maxWeight;
        uint256 referralSellerFee = (amount *
            g().getPolicy("BUY_COLLECTION_REFERRAL_SELLER_FEE").policyWeight) /
            g().getPolicy("BUY_COLLECTION_REFERRAL_SELLER_FEE").maxWeight;
        uint256 buyAmount = amount -
            platformFee -
            referralBuyerFee -
            referralSellerFee;
        uint256 mintAmount = b().purchaseTargetAmount(
            totalSupply(),
            targetPrice + c().balanceOf(address(this)),
            uint32(collateralWeight),
            buyAmount
        );

        c().transferFrom(msg.sender, address(this), amount);

        if (collectorFee > 0) {
            c().transferFrom(address(this), collectorAddr, collectorFee);
        }
        if (platformFee > 0) {
            c().transferFrom(
                address(this),
                g().getManagementFundContract(),
                platformFee
            );
        }
        if (referralBuyerFee > 0) {
            c().transferFrom(
                address(this),
                m().getReferral(msg.sender),
                referralBuyerFee
            );
        }
        if (referralSellerFee > 0) {
            c().transferFrom(
                address(this),
                m().getReferral(collectorAddr),
                referralSellerFee
            );
        }
        if (mintAmount > 0) {
            _mint(msg.sender, mintAmount);
        }
    }

    function sell(uint256 amount) public payable {
        require(
            isMember(msg.sender) &&
                balanceOf(msg.sender) >= amount &&
                !isAuction &&
                !isFreeze,
            "73"
        );

        uint256 withdrawAmount = max(
            0,
            b().purchaseTargetAmount(
                totalSupply(),
                targetPrice + c().balanceOf(address(this)),
                uint32(collateralWeight),
                amount
            )
        );
        uint256 collectorFee = (withdrawAmount * collectorFeeWeight) /
            maxWeight;
        uint256 platformFee = (withdrawAmount *
            g().getPolicy("SELL_COLLECTION_PLATFORM_FEE").policyWeight) /
            g().getPolicy("SELL_COLLECTION_PLATFORM_FEE").maxWeight;
        uint256 referralBuyerFee = (withdrawAmount *
            g().getPolicy("SELL_COLLECTION_REFERRAL_BUYER_FEE").policyWeight) /
            g().getPolicy("SELL_COLLECTION_REFERRAL_BUYER_FEE").maxWeight;
        uint256 referralSellerFee = (withdrawAmount *
            g().getPolicy("SELL_COLLECTION_REFERRAL_SELLER_FEE").policyWeight) /
            g().getPolicy("SELL_COLLECTION_REFERRAL_SELLER_FEE").maxWeight;
        uint256 sellAmount = withdrawAmount -
            platformFee -
            referralBuyerFee -
            referralSellerFee;

        _burn(msg.sender, amount);

        if (collectorFee > 0) {
            c().transferFrom(address(this), collectorAddr, collectorFee);
        }
        if (platformFee > 0) {
            c().transferFrom(
                address(this),
                g().getManagementFundContract(),
                platformFee
            );
        }
        if (referralBuyerFee > 0) {
            c().transferFrom(
                address(this),
                m().getReferral(msg.sender),
                referralBuyerFee
            );
        }
        if (referralSellerFee > 0) {
            c().transferFrom(
                address(this),
                m().getReferral(collectorAddr),
                referralSellerFee
            );
        }
        if (sellAmount > 0) {
            c().transferFrom(address(this), msg.sender, sellAmount);
        }
    }

    function burn(uint256 amount) public payable {
        require(
            isMember(msg.sender) &&
                balanceOf(msg.sender) >= amount &&
                amount > 0 && !isAuction && !isFreeze,
            "74"
        );

        _burn(msg.sender, amount);
    }
}
