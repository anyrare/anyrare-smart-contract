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
    uint256 public dummyCollateralValue;
    uint32 public totalNft;

    uint256 public targetPrice;
    uint256 public targetPriceTotalVoteToken;
    uint32 public targetPriceTotalVoter;
    bool isAuction;
    bool isFreeze;

    struct TargetPriceVoteInfo {
        uint256 targetPrice;
        uint256 voteToken;
        bool isVote;
    }

    mapping(uint32 => uint256) nfts;
    mapping(uint32 => address) targetPriceVotersAddress;
    mapping(address => TargetPriceVoteInfo) targetPriceVotes;

    constructor(
        address _governanceContract,
        address _bancorFormulaContract,
        address _collectorAddr,
        string memory _name,
        string memory _symbol,
        uint256 _initialPrice,
        uint256 _initialAmount,
        uint32 _totalNft,
        uint256[] memory _nfts
    ) ERC20(_name, _symbol) {
        governanceContract = _governanceContract;
        require(
            _initialPrice > 0 && _initialAmount > 0 && isMember(_collectorAddr),
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
        dummyCollateralValue = _initialPrice;
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

    function max(uint256 x, uint256 y) private view returns (uint256) {
        return x > y ? x : y;
    }

    function min(uint256 x, uint256 y) private view returns (uint256) {
        return x < y ? x : y;
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
        uint256 referralInvestorFee = (amount *
            g().getPolicy("BUY_COLLECTION_REFERRAL_INVESTOR_FEE").policyWeight) /
            g().getPolicy("BUY_COLLECTION_REFERRAL_INVESTOR_FEE").maxWeight;
        uint256 referralCollectorFee = (amount *
            g().getPolicy("BUY_COLLECTION_REFERRAL_COLLECTOR_FEE").policyWeight) /
            g().getPolicy("BUY_COLLECTION_REFERRAL_COLLECTOR_FEE").maxWeight;
        uint256 buyAmount = amount -
            platformFee -
            referralInvestorFee -
            referralCollectorFee;
        uint256 mintAmount = b().purchaseTargetAmount(
            totalSupply(),
            dummyCollateralValue + c().balanceOf(address(this)),
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
        if (referralInvestorFee > 0) {
            c().transferFrom(
                address(this),
                m().getReferral(msg.sender),
                referralInvestorFee
            );
        }
        if (referralCollectorFee > 0) {
            c().transferFrom(
                address(this),
                m().getReferral(collectorAddr),
                referralCollectorFee
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

        uint256 burnAmount = b().purchaseTargetAmount(
            totalSupply(),
            dummyCollateralValue + c().balanceOf(address(this)),
            uint32(collateralWeight),
            amount
        );

        uint256 withdrawAmount = min(c().balanceOf(address(this)), burnAmount);
        dummyCollateralValue -= (burnAmount - withdrawAmount);

        uint256 collectorFee = (withdrawAmount * collectorFeeWeight) /
            maxWeight;
        uint256 platformFee = (withdrawAmount *
            g().getPolicy("SELL_COLLECTION_PLATFORM_FEE").policyWeight) /
            g().getPolicy("SELL_COLLECTION_PLATFORM_FEE").maxWeight;
        uint256 referralInvestorFee = (withdrawAmount *
            g().getPolicy("SELL_COLLECTION_REFERRAL_INVESTOR_FEE").policyWeight) /
            g().getPolicy("SELL_COLLECTION_REFERRAL_INVESTOR_FEE").maxWeight;
        uint256 referralCollectorFee = (withdrawAmount *
            g().getPolicy("SELL_COLLECTION_REFERRAL_COLLECTOR_FEE").policyWeight) /
            g().getPolicy("SELL_COLLECTION_REFERRAL_COLLECTOR_FEE").maxWeight;
        uint256 sellAmount = withdrawAmount -
            platformFee -
            referralInvestorFee -
            referralCollectorFee;

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
        if (referralInvestorFee > 0) {
            c().transferFrom(
                address(this),
                m().getReferral(msg.sender),
                referralInvestorFee
            );
        }
        if (referralCollectorFee > 0) {
            c().transferFrom(
                address(this),
                m().getReferral(collectorAddr),
                referralCollectorFee
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
                amount > 0 &&
                !isAuction &&
                !isFreeze,
            "74"
        );

        _burn(msg.sender, amount);
    }

    function setTargetPrice() public {}

    function openAuction() public {}

    function bidAuction() public {}

    function processAuction() public {}

    function purchaseTargetAmount() public {}
}
