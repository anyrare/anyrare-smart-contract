pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Member.sol";
import "./Governance.sol";
import "./BancorFormula.sol";

contract CollectionToken is ERC20 {
    address private governanceContract;
    address private bancorFormulaContract;
    address public collector;

    uint256 public maxWeight;
    uint256 public collateralWeight;
    uint256 public collectorFeeWeight;
    uint256 public dummyCollateralValue;
    uint32 public totalNft;
    uint32 totalShareholder;

    bool isAuction;
    bool isFreeze;

    struct CollectionShareholder {
        bool exists;
        address addr;
    }

    struct CollectionTargetPrice {
        uint256 price;
        uint256 totalSum;
        uint256 totalVoteToken;
        uint32 totalVoter;
        uint32 totalVoterIndex;
    }

    struct CollectionTargetPriceVoteInfo {
        uint256 price;
        uint256 voteToken;
        bool isVote;
        bool exists;
    }

    struct CollectionAuctionBid {
        uint256 timestamp;
        uint256 value;
        address bidder;
    }

    struct CollectionAuction {
        uint256 openAuctionTimestamp;
        uint256 closeAuctionTimestamp;
        address bidder;
        uint256 startingPrice;
        uint256 value;
        uint256 maxWeight;
        uint256 nextBidWeight;
        uint32 totalBid;
    }

    mapping(uint32 => uint256) nfts;
    mapping(uint32 => address) targetPriceVotersAddress;
    mapping(address => CollectionTargetPriceVoteInfo) targetPriceVotes;
    mapping(uint32 => CollectionAuctionBid) bids;
    mapping(address => uint32) shareholderIndexs;
    mapping(uint32 => CollectionShareholder) shareholders;

    CollectionTargetPrice public targetPrice;
    CollectionAuction public auction;

    constructor(
        address _governanceContract,
        address _bancorFormulaContract,
        address _collector,
        string memory _name,
        string memory _symbol,
        uint256 _initialPrice,
        uint256 _initialAmount,
        uint32 _totalNft,
        uint256[] memory _nfts
    ) ERC20(_name, _symbol) {
        governanceContract = _governanceContract;
        require(
            _initialPrice > 0 && _initialAmount > 0 && isMember(_collector),
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
        collector = _collector;
        dummyCollateralValue = _initialPrice;
        totalNft = _totalNft;
        isAuction = false;
        isFreeze = false;

        targetPrice.price = 0;
        targetPrice.totalSum = 0;
        targetPrice.totalVoteToken = 0;
        targetPrice.totalVoter = 0;
        targetPrice.totalVoterIndex = 0;

        shareholders[0].addr = msg.sender;
        shareholders[0].exists = true;
        totalShareholder = 1;
        shareholderIndexs[msg.sender] = 0;

        _mint(collector, _initialAmount);
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
            g()
                .getPolicy("BUY_COLLECTION_REFERRAL_INVESTOR_FEE")
                .policyWeight) /
            g().getPolicy("BUY_COLLECTION_REFERRAL_INVESTOR_FEE").maxWeight;
        uint256 referralCollectorFee = (amount *
            g()
                .getPolicy("BUY_COLLECTION_REFERRAL_COLLECTOR_FEE")
                .policyWeight) /
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
            c().transferFrom(address(this), collector, collectorFee);
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
                m().getReferral(collector),
                referralCollectorFee
            );
        }
        if (mintAmount > 0) {
            _mint(msg.sender, mintAmount);
        }

        if (!shareholders[shareholderIndexs[msg.sender]].exists) {
            shareholderIndexs[msg.sender] = totalShareholder;
            shareholders[shareholderIndexs[msg.sender]].exists = true;
            shareholders[shareholderIndexs[msg.sender]].addr = msg.sender;
            totalShareholder += 1;
        }
    }

    function sell(uint256 amount) public payable {
        require(
            isMember(msg.sender) &&
                balanceOf(msg.sender) >= amount &&
                shareholders[shareholderIndexs[msg.sender]].exists &&
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
            g()
                .getPolicy("SELL_COLLECTION_REFERRAL_INVESTOR_FEE")
                .policyWeight) /
            g().getPolicy("SELL_COLLECTION_REFERRAL_INVESTOR_FEE").maxWeight;
        uint256 referralCollectorFee = (withdrawAmount *
            g()
                .getPolicy("SELL_COLLECTION_REFERRAL_COLLECTOR_FEE")
                .policyWeight) /
            g().getPolicy("SELL_COLLECTION_REFERRAL_COLLECTOR_FEE").maxWeight;
        uint256 sellAmount = withdrawAmount -
            platformFee -
            referralInvestorFee -
            referralCollectorFee;

        _burn(msg.sender, amount);

        if (collectorFee > 0) {
            c().transferFrom(address(this), collector, collectorFee);
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
                m().getReferral(collector),
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

    // f(C) -> targetARA
    function calculatePurchaseReturn(uint256 amount)
        public
        view
        returns (uint256)
    {
        uint256 collectorFee = (amount * collectorFeeWeight) / maxWeight;
        uint256 platformFee = (amount *
            g().getPolicy("BUY_COLLECTION_PLATFORM_FEE").policyWeight) /
            g().getPolicy("BUY_COLLECTION_PLATFORM_FEE").maxWeight;
        uint256 referralInvestorFee = (amount *
            g()
                .getPolicy("BUY_COLLECTION_REFERRAL_INVESTOR_FEE")
                .policyWeight) /
            g().getPolicy("BUY_COLLECTION_REFERRAL_INVESTOR_FEE").maxWeight;
        uint256 referralCollectorFee = (amount *
            g()
                .getPolicy("BUY_COLLECTION_REFERRAL_COLLECTOR_FEE")
                .policyWeight) /
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

        return mintAmount;
    }

    // f(ARA) -> targetC
    function calculateSaleReturn(uint256 amount) public returns (uint256) {
        uint256 burnAmount = b().purchaseTargetAmount(
            totalSupply(),
            dummyCollateralValue + c().balanceOf(address(this)),
            uint32(collateralWeight),
            amount
        );

        uint256 withdrawAmount = min(c().balanceOf(address(this)), burnAmount);

        uint256 collectorFee = (withdrawAmount * collectorFeeWeight) /
            maxWeight;
        uint256 platformFee = (withdrawAmount *
            g().getPolicy("SELL_COLLECTION_PLATFORM_FEE").policyWeight) /
            g().getPolicy("SELL_COLLECTION_PLATFORM_FEE").maxWeight;
        uint256 referralInvestorFee = (withdrawAmount *
            g()
                .getPolicy("SELL_COLLECTION_REFERRAL_INVESTOR_FEE")
                .policyWeight) /
            g().getPolicy("SELL_COLLECTION_REFERRAL_INVESTOR_FEE").maxWeight;
        uint256 referralCollectorFee = (withdrawAmount *
            g()
                .getPolicy("SELL_COLLECTION_REFERRAL_COLLECTOR_FEE")
                .policyWeight) /
            g().getPolicy("SELL_COLLECTION_REFERRAL_COLLECTOR_FEE").maxWeight;
        uint256 sellAmount = withdrawAmount -
            platformFee -
            referralInvestorFee -
            referralCollectorFee;

        return sellAmount;
    }

    // f(targetARA) -> C
    function calculateFundCost(uint256 amount) public returns (uint256) {
        uint256 collectorFee = (amount * collectorFeeWeight) / maxWeight;
        uint256 platformFee = (amount *
            g().getPolicy("BUY_COLLECTION_PLATFORM_FEE").policyWeight) /
            g().getPolicy("BUY_COLLECTION_PLATFORM_FEE").maxWeight;
        uint256 referralInvestorFee = (amount *
            g()
                .getPolicy("BUY_COLLECTION_REFERRAL_INVESTOR_FEE")
                .policyWeight) /
            g().getPolicy("BUY_COLLECTION_REFERRAL_INVESTOR_FEE").maxWeight;
        uint256 referralCollectorFee = (amount *
            g()
                .getPolicy("BUY_COLLECTION_REFERRAL_COLLECTOR_FEE")
                .policyWeight) /
            g().getPolicy("BUY_COLLECTION_REFERRAL_COLLECTOR_FEE").maxWeight;
        uint256 adjAmount = amount +
            platformFee +
            referralInvestorFee +
            referralCollectorFee;

        return
            b().fundCost(
                totalSupply(),
                c().balanceOf(address(this)),
                uint32(collateralWeight),
                adjAmount
            );
    }

    // f(targetDAI) -> ARA
    function calculateLiquidateCost(uint256 amount)
        public
        view
        returns (uint256)
    {
        uint256 collectorFee = (amount * collectorFeeWeight) / maxWeight;
        uint256 platformFee = (amount *
            g().getPolicy("SELL_COLLECTION_PLATFORM_FEE").policyWeight) /
            g().getPolicy("SELL_COLLECTION_PLATFORM_FEE").maxWeight;
        uint256 referralInvestorFee = (amount *
            g()
                .getPolicy("SELL_COLLECTION_REFERRAL_INVESTOR_FEE")
                .policyWeight) /
            g().getPolicy("SELL_COLLECTION_REFERRAL_INVESTOR_FEE").maxWeight;
        uint256 referralCollectorFee = (amount *
            g()
                .getPolicy("SELL_COLLECTION_REFERRAL_COLLECTOR_FEE")
                .policyWeight) /
            g().getPolicy("SELL_COLLECTION_REFERRAL_COLLECTOR_FEE").maxWeight;
        uint256 adjAmount = amount +
            platformFee +
            referralInvestorFee +
            referralCollectorFee;

        return
            b().fundCost(
                totalSupply(),
                c().balanceOf(address(this)),
                uint32(collateralWeight),
                adjAmount
            );
    }

    function currentPrice() public view returns (uint256) {
        return
            (dummyCollateralValue + c().totalSupply()) /
            ((totalSupply() * collateralWeight) / maxWeight);
    }

    function currentTotalValue() public view returns (uint256) {
        return
            ((dummyCollateralValue + c().totalSupply()) * maxWeight) /
            collateralWeight;
    }

    function setTargetPrice(uint256 price, bool vote) public {
        require(
            isMember(msg.sender) &&
                balanceOf(msg.sender) > 0 &&
                !isAuction &&
                !isFreeze,
            "75"
        );

        if (!targetPriceVotes[msg.sender].isVote && vote) {
            if (!targetPriceVotes[msg.sender].exists) {
                targetPriceVotersAddress[targetPrice.totalVoter] = msg.sender;
                targetPrice.totalVoterIndex += 1;
                targetPriceVotes[msg.sender].exists = true;
            }

            targetPrice.totalVoter += 1;
            targetPrice.totalVoteToken += balanceOf(msg.sender);
            targetPrice.totalSum += price;
            targetPrice.price =
                targetPrice.totalSum /
                targetPrice.totalVoteToken;
            targetPriceVotes[msg.sender].isVote = true;
            targetPriceVotes[msg.sender].price = price;
            targetPriceVotes[msg.sender].voteToken = balanceOf(msg.sender);
        } else if (targetPriceVotes[msg.sender].isVote && vote) {
            targetPrice.totalSum =
                targetPrice.totalSum -
                targetPriceVotes[msg.sender].price +
                price;
            targetPrice.price =
                targetPrice.totalSum /
                targetPrice.totalVoteToken;
            targetPriceVotes[msg.sender].price = price;
        } else if (targetPriceVotes[msg.sender].isVote && !vote) {
            targetPrice.totalVoter -= 1;
            targetPriceVotes[msg.sender].isVote = false;
            targetPriceVotes[msg.sender].price = 0;
            targetPriceVotes[msg.sender].voteToken = 0;
        }
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        require(
            balanceOf(msg.sender) >= amount &&
                isMember(msg.sender) &&
                isMember(to),
            "76"
        );

        uint256 platformFee = (amount *
            g().getPolicy("TRANSFER_COLLECTION_PLATFORM_FEE").policyWeight) /
            g().getPolicy("TRANSFER_COLLECTION_PLATFORM_FEE").maxWeight;
        uint256 collectorFee = (amount *
            g().getPolicy("TRANSFER_COLLECTION_COLLECTOR_FEE").policyWeight) /
            g().getPolicy("TRANSFER_COLLECTION_COLLECTOR_FEE").maxWeight;
        uint256 referralSenderFee = (amount *
            g()
                .getPolicy("TRANSFER_COLLECTION_REFERRAL_RECEIVER_FEE")
                .policyWeight) /
            g()
                .getPolicy("TRANSFER_COLLECTION_REFERRAL_RECEIVER_FEE")
                .maxWeight;
        uint256 referralReceiverFee = (amount *
            g()
                .getPolicy("TRANSFER_COLLECTION_REFERRAL_SENDER_FEE")
                .policyWeight) /
            g().getPolicy("TRANSFER_COLLECTION_REFERRAL_SENDER_FEE").maxWeight;
        uint256 transferAmount = amount -
            platformFee -
            collectorFee -
            referralSenderFee -
            referralReceiverFee;

        _transfer(msg.sender, address(this), amount);

        if (platformFee > 0) {
            _transfer(
                address(this),
                g().getManagementFundContract(),
                platformFee
            );
        }
        if (referralSenderFee > 0) {
            _transfer(
                address(this),
                m().getReferral(msg.sender),
                referralSenderFee
            );
        }
        if (referralReceiverFee > 0) {
            _transfer(address(this), m().getReferral(to), referralReceiverFee);
        }
        if (collectorFee > 0) {
            _transfer(address(this), m().getReferral(collector), collectorFee);
        }

        _transfer(address(this), to, transferAmount);

        if (!shareholders[shareholderIndexs[to]].exists) {
            shareholderIndexs[to] = totalShareholder;
            shareholders[shareholderIndexs[to]].exists = true;
            shareholders[shareholderIndexs[to]].addr = to;
            totalShareholder += 1;
        }

        return true;
    }

    function transferFrom(address to, uint256 amount) public returns (bool) {
        return transfer(to, amount);
    }

    function openAuction() public {
        require(
            isMember(msg.sender) &&
                c().balanceOf(msg.sender) >= targetPrice.price &&
                !isAuction &&
                !isFreeze,
            "77"
        );

        isAuction = true;

        auction.openAuctionTimestamp = block.timestamp;
        auction.closeAuctionTimestamp =
            block.timestamp +
            g().getPolicy("OPEN_AUCTION_COLLECTION_DURATION").policyValue;
        auction.bidder = msg.sender;
        auction.startingPrice = targetPrice.price;
        auction.value = targetPrice.price;
        auction.nextBidWeight = g()
            .getPolicy("OPEN_AUCTION_COLLECTION_NEXT_BID_WEIGHT")
            .policyWeight;
        auction.maxWeight = g()
            .getPolicy("OPEN_AUCTION_COLLECTION_NEXT_BID_WEIGHT")
            .maxWeight;

        bids[auction.totalBid].timestamp = block.timestamp;
        bids[auction.totalBid].value = targetPrice.price;
        bids[auction.totalBid].bidder = msg.sender;

        auction.totalBid = 1;

        c().transferFrom(msg.sender, address(this), targetPrice.price);
    }

    function bidAuction(uint256 bidValue) public payable {
        require(
            isMember(msg.sender) &&
                c().balanceOf(msg.sender) >= bidValue &&
                isAuction &&
                !isFreeze &&
                bidValue >=
                (auction.value * auction.nextBidWeight) /
                    auction.maxWeight +
                    auction.value,
            "78"
        );

        c().transferFrom(
            msg.sender,
            address(this),
            auction.bidder != msg.sender ? bidValue : bidValue - auction.value
        );

        if (auction.bidder != msg.sender && auction.bidder != address(0x0)) {
            c().transfer(auction.bidder, auction.value);
        }

        bids[auction.totalBid].timestamp = block.timestamp;
        bids[auction.totalBid].value = bidValue;
        bids[auction.totalBid].bidder = msg.sender;

        auction.bidder = msg.sender;
        auction.value = bidValue;
        auction.totalBid += 1;
    }

    function processAuction() public {
        require(
            isAuction &&
                !isFreeze &&
                block.timestamp >= auction.closeAuctionTimestamp,
            "79"
        );

        isAuction = false;
        isFreeze = true;

        for (uint32 i = 0; i < totalNft; i++) {
            n().transferFrom(address(this), auction.bidder, nfts[i]);
        }

        uint256 totalCollateral = c().balanceOf(address(this));
        uint256 remainCollateral = totalCollateral;

        for (uint32 i = 0; i < totalShareholder; i++) {
            uint256 shareholderBalance = balanceOf(shareholders[i].addr);
            uint256 amount = (totalCollateral * shareholderBalance) /
                totalSupply();

            if (amount > 0 && remainCollateral >= amount) {
                c().transferFrom(address(this), shareholders[i].addr, amount);
                remainCollateral -= amount;
            }
        }

        if (remainCollateral > 0) {
            c().transferFrom(address(this), g().getManagementFundContract(), remainCollateral);
        }
    }
}
