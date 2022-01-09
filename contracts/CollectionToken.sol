pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Governance.sol";
import "./Member.sol";
import "./BancorFormula.sol";
import "./NFTFactory.sol";

contract CollectionToken is ERC20 {
    address private governanceContract;
    address public collector;

    uint256 public maxWeight;
    uint256 public collateralWeight;
    uint256 public collectorFeeWeight;
    uint256 public dummyCollateralValue;
    uint32 public totalNft;
    uint32 totalShareholder;

    bool exists;
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
        address _collector,
        string memory _name,
        string memory _symbol,
        uint256 _initialValue
    ) ERC20(_name, _symbol) {
        governanceContract = _governanceContract;
        require(
            _initialValue > 0 &&
                m().isMember(_collector) &&
                msg.sender == g().getCollectionFactoryContract()
        );

        collector = _collector;
        dummyCollateralValue = _initialValue;
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
    }

    function g() private view returns (Governance) {
        return Governance(governanceContract);
    }

    function m() private view returns (Member) {
        return Member(g().getMemberContract());
    }

    function t() private view returns (ERC20) {
        return ERC20(g().getARATokenContract());
    }

    function b() private returns (BancorFormula) {
        return BancorFormula(g().getBancorFormulaContract());
    }

    function n() private returns (NFTFactory) {
        return NFTFactory(g().getNFTFactoryContract());
    }

    function mint(
        address _collector,
        uint256 _initialAmount,
        uint32 _totalNft,
        uint256[] memory _nfts
    ) public {
        require(
            msg.sender == g().getCollectionFactoryContract() &&
                _initialAmount > 0 &&
                !exists &&
                collector == _collector
        );

        for (uint32 i = 0; i < _totalNft; i++) {
            require(n().ownerOf(_nfts[i]) == address(this));
            nfts[i] = _nfts[i];
        }

        totalNft = _totalNft;
        _mint(_collector, _initialAmount);

        exists = true;
    }

    function calculateFeeFromPolicy(uint256 value, string memory policyName)
        public
        returns (uint256)
    {
        return
            (value * g().getPolicy(policyName).policyWeight) /
            g().getPolicy(policyName).maxWeight;
    }

    function max(uint256 x, uint256 y) public view returns (uint256) {
        return x > y ? x : y;
    }

    function min(uint256 x, uint256 y) public view returns (uint256) {
        return x < y ? x : y;
    }

    function buy(uint256 amount) public payable {
        require(
            m().isMember(msg.sender) &&
                t().balanceOf(msg.sender) >= amount &&
                !isAuction &&
                !isFreeze
        );

        uint256 collectorFee = (amount * collectorFeeWeight) / maxWeight;
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
            platformFee -
            referralInvestorFee -
            referralCollectorFee;
        uint256 mintAmount = b().purchaseTargetAmount(
            totalSupply(),
            dummyCollateralValue + t().balanceOf(address(this)),
            uint32(collateralWeight),
            buyAmount
        );

        t().transferFrom(msg.sender, address(this), amount);

        t().transfer(collector, collectorFee);
        t().transfer(g().getManagementFundContract(), platformFee);
        t().transfer(m().getReferral(msg.sender), referralInvestorFee);
        t().transfer(m().getReferral(collector), referralCollectorFee);

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
            m().isMember(msg.sender) &&
                balanceOf(msg.sender) >= amount &&
                shareholders[shareholderIndexs[msg.sender]].exists &&
                !isAuction &&
                !isFreeze
        );

        uint256 burnAmount = b().purchaseTargetAmount(
            totalSupply(),
            dummyCollateralValue + t().balanceOf(address(this)),
            uint32(collateralWeight),
            amount
        );

        uint256 withdrawAmount = min(t().balanceOf(address(this)), burnAmount);
        dummyCollateralValue -= (burnAmount - withdrawAmount);

        uint256 collectorFee = (withdrawAmount * collectorFeeWeight) /
            maxWeight;
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

        _burn(msg.sender, amount);

        t().transfer(collector, collectorFee);
        t().transfer(g().getManagementFundContract(), platformFee);
        t().transfer(m().getReferral(msg.sender), referralInvestorFee);
        t().transfer(m().getReferral(collector), referralCollectorFee);
        t().transfer(msg.sender, sellAmount);
    }

    function burn(uint256 amount) public payable {
        require(
            m().isMember(msg.sender) &&
                balanceOf(msg.sender) >= amount &&
                amount > 0 &&
                !isAuction &&
                !isFreeze
        );

        _burn(msg.sender, amount);
    }

    // f(C) -> targetARA
    function calculatePurchaseReturn(uint256 amount) public returns (uint256) {
        uint256 collectorFee = (amount * collectorFeeWeight) / maxWeight;
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
            totalSupply(),
            dummyCollateralValue + t().balanceOf(address(this)),
            uint32(collateralWeight),
            buyAmount
        );

        return mintAmount;
    }

    // f(ARA) -> targetC
    function calculateSaleReturn(uint256 amount) public returns (uint256) {
        uint256 burnAmount = b().purchaseTargetAmount(
            totalSupply(),
            dummyCollateralValue + t().balanceOf(address(this)),
            uint32(collateralWeight),
            amount
        );

        uint256 withdrawAmount = min(t().balanceOf(address(this)), burnAmount);

        uint256 collectorFee = (withdrawAmount * collectorFeeWeight) /
            maxWeight;
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

        return sellAmount;
    }

    // f(targetARA) -> C
    function calculateFundCost(uint256 amount) public returns (uint256) {
        uint256 collectorFee = (amount * collectorFeeWeight) / maxWeight;
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
            platformFee +
            referralInvestorFee +
            referralCollectorFee;

        return
            b().fundCost(
                totalSupply(),
                t().balanceOf(address(this)),
                uint32(collateralWeight),
                adjAmount
            );
    }

    // f(targetDAI) -> ARA
    function calculateLiquidateCost(uint256 amount) public returns (uint256) {
        uint256 collectorFee = (amount * collectorFeeWeight) / maxWeight;
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
            platformFee +
            referralInvestorFee +
            referralCollectorFee;

        return
            b().fundCost(
                totalSupply(),
                t().balanceOf(address(this)),
                uint32(collateralWeight),
                adjAmount
            );
    }

    function currentPrice() public returns (uint256) {
        return
            (dummyCollateralValue + t().totalSupply()) /
            ((totalSupply() * collateralWeight) / maxWeight);
    }

    function currentTotalValue() public returns (uint256) {
        return
            ((dummyCollateralValue + t().totalSupply()) * maxWeight) /
            collateralWeight;
    }

    function setTargetPrice(uint256 price, bool vote) public {
        require(
            m().isMember(msg.sender) &&
                balanceOf(msg.sender) > 0 &&
                !isAuction &&
                !isFreeze
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
                m().isMember(msg.sender) &&
                m().isMember(to)
        );

        uint256 platformFee = calculateFeeFromPolicy(
            amount,
            "TRANSFER_COLLECTION_PLATFORM_FEE"
        );
        uint256 collectorFee = calculateFeeFromPolicy(
            amount,
            "TRANSFER_COLLECTION_COLLECTOR_FEE"
        );
        uint256 referralSenderFee = calculateFeeFromPolicy(
            amount,
            "TRANSFER_COLLECTION_REFERRAL_RECEIVER_FEE"
        );

        uint256 referralReceiverFee = calculateFeeFromPolicy(
            amount,
            "TRANSFER_COLLECTION_REFERRAL_SENDER_FEE"
        );
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
            m().isMember(msg.sender) &&
                t().balanceOf(msg.sender) >= targetPrice.price &&
                !isAuction &&
                !isFreeze
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

        t().transferFrom(msg.sender, address(this), targetPrice.price);
    }

    function bidAuction(uint256 bidValue) public payable {
        require(
            m().isMember(msg.sender) &&
                t().balanceOf(msg.sender) >= bidValue &&
                isAuction &&
                !isFreeze &&
                bidValue >=
                (auction.value * auction.nextBidWeight) /
                    auction.maxWeight +
                    auction.value
        );

        t().transferFrom(
            msg.sender,
            address(this),
            auction.bidder != msg.sender ? bidValue : bidValue - auction.value
        );

        if (auction.bidder != msg.sender && auction.bidder != address(0x0)) {
            t().transfer(auction.bidder, auction.value);
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
                block.timestamp >= auction.closeAuctionTimestamp
        );

        isAuction = false;
        isFreeze = true;

        for (uint32 i = 0; i < totalNft; i++) {
            n().transferFrom(address(this), auction.bidder, nfts[i]);
        }

        uint256 totalCollateral = t().balanceOf(address(this));
        uint256 remainCollateral = totalCollateral;

        for (uint32 i = 0; i < totalShareholder; i++) {
            uint256 shareholderBalance = balanceOf(shareholders[i].addr);
            uint256 amount = (totalCollateral * shareholderBalance) /
                totalSupply();

            if (amount > 0 && remainCollateral >= amount) {
                t().transfer(shareholders[i].addr, amount);
                remainCollateral -= amount;
            }
        }

        t().transfer(g().getManagementFundContract(), remainCollateral);
    }
}
