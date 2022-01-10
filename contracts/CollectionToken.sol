pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ARAToken.sol";
import "./Governance.sol";
import "./Member.sol";
import "./BancorFormula.sol";
import "./NFTFactory.sol";

contract CollectionToken is ERC20 {
    address private governanceContract;

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

    struct CollectionInfo {
        address collector;
        uint256 maxWeight;
        uint256 collateralWeight;
        uint256 collectorFeeWeight;
        uint256 dummyCollateralValue;
        uint32 totalNft;
        uint32 totalShareholder;
        bool exists;
        bool isAuction;
        bool isFreeze;
        string tokenURI;
    }

    struct TransferARA {
        address receiver;
        uint256 amount;
    }

    mapping(uint32 => uint256) nfts;
    mapping(uint32 => address) targetPriceVotersAddress;
    mapping(address => CollectionTargetPriceVoteInfo) targetPriceVotes;
    mapping(uint32 => CollectionAuctionBid) bids;
    mapping(address => uint32) shareholderIndexs;
    mapping(uint32 => CollectionShareholder) shareholders;

    CollectionTargetPrice public targetPrice;
    CollectionAuction public auction;
    CollectionInfo public info;

    constructor(
        address _governanceContract,
        address _collector,
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        uint256 _initialValue,
        uint256 _maxWeight,
        uint256 _collateralWeight,
        uint256 _collectorFeeWeight
    ) ERC20(_name, _symbol) {
        governanceContract = _governanceContract;
        require(
            _initialValue > 0 &&
                m().isMember(_collector) &&
                msg.sender == g().getCollectionFactoryContract()
        );

        info = CollectionInfo({
            collector: _collector,
            maxWeight: _maxWeight,
            collateralWeight: _collateralWeight,
            collectorFeeWeight: _collectorFeeWeight,
            dummyCollateralValue: (_initialValue * _collateralWeight) /
                _maxWeight,
            totalNft: 0,
            totalShareholder: 1,
            exists: false,
            isAuction: false,
            isFreeze: false,
            tokenURI: _tokenURI
        });

        targetPrice = CollectionTargetPrice({
            price: 0,
            totalSum: 0,
            totalVoteToken: 0,
            totalVoter: 0,
            totalVoterIndex: 0
        });

        shareholders[0].addr = msg.sender;
        shareholders[0].exists = true;
        shareholderIndexs[msg.sender] = 0;
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

    function n() private returns (NFTFactory) {
        return NFTFactory(g().getNFTFactoryContract());
    }

    function max(uint256 x, uint256 y) internal view returns (uint256) {
        return x > y ? x : y;
    }

    function min(uint256 x, uint256 y) internal view returns (uint256) {
        return x < y ? x : y;
    }

    function getInfo() public view returns (CollectionInfo memory i) {
        return info;
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
                !info.exists &&
                info.collector == _collector
        );

        for (uint32 i = 0; i < _totalNft; i++) {
            require(n().ownerOf(_nfts[i]) == address(this));
            nfts[i] = _nfts[i];
        }

        info.totalNft = _totalNft;
        _mint(_collector, _initialAmount);

        info.exists = true;
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

    function transferARAFromContract(TransferARA[] memory lists, uint8 length)
        private
    {
        for (uint8 i = 0; i < length; i++) {
            if (lists[i].amount > 0) {
                t().transfer(
                    lists[i].receiver,
                    min(lists[i].amount, t().balanceOf(address(this)))
                );
            }
        }
    }

    function buy(uint256 amount) public payable {
        require(
            m().isMember(msg.sender) &&
                t().balanceOf(msg.sender) >= amount &&
                !info.isAuction &&
                !info.isFreeze
        );

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
            platformFee -
            referralInvestorFee -
            referralCollectorFee;
        uint256 mintAmount = b().purchaseTargetAmount(
            totalSupply(),
            info.dummyCollateralValue + t().balanceOf(address(this)),
            uint32(info.collateralWeight),
            buyAmount
        );

        t().transferFrom(msg.sender, address(this), amount);

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

        transferARAFromContract(feeLists, 4);

        if (mintAmount > 0) {
            _mint(msg.sender, mintAmount);
        }

        if (!shareholders[shareholderIndexs[msg.sender]].exists) {
            shareholderIndexs[msg.sender] = info.totalShareholder;
            shareholders[shareholderIndexs[msg.sender]].exists = true;
            shareholders[shareholderIndexs[msg.sender]].addr = msg.sender;
            info.totalShareholder += 1;
        }
    }

    function sell(uint256 amount) public payable {
        require(
            m().isMember(msg.sender) &&
                balanceOf(msg.sender) >= amount &&
                shareholders[shareholderIndexs[msg.sender]].exists &&
                !info.isAuction &&
                !info.isFreeze
        );

        uint256 burnAmount = b().saleTargetAmount(
            totalSupply(),
            info.dummyCollateralValue + t().balanceOf(address(this)),
            uint32(info.collateralWeight),
            amount
        );

        uint256 withdrawAmount = min(t().balanceOf(address(this)), burnAmount);
        info.dummyCollateralValue -= (burnAmount - withdrawAmount);

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

        _burn(msg.sender, amount);

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
            receiver: m().getReferral(msg.sender),
            amount: referralInvestorFee
        });
        feeLists[3] = TransferARA({
            receiver: m().getReferral(info.collector),
            amount: referralCollectorFee
        });
        feeLists[4] = TransferARA({receiver: msg.sender, amount: sellAmount});
        transferARAFromContract(feeLists, 5);
    }

    function burn(uint256 amount) public payable {
        require(
            m().isMember(msg.sender) &&
                balanceOf(msg.sender) >= amount &&
                amount > 0 &&
                !info.isAuction &&
                !info.isFreeze
        );

        _burn(msg.sender, amount);
    }

    // f(inputARA) -> outputCollectionToken
    function calculatePurchaseReturn(uint256 amount)
        public
        view
        returns (uint256)
    {
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
            totalSupply(),
            currentCollateral(),
            uint32(info.collateralWeight),
            buyAmount
        );

        return mintAmount;
    }

    // f(inputCollectionToken) -> outputARA
    function calculateSaleReturn(uint256 amount) public view returns (uint256) {
        uint256 burnAmount = b().saleTargetAmount(
            totalSupply(),
            currentCollateral(),
            uint32(info.collateralWeight),
            amount
        );

        uint256 withdrawAmount = min(t().balanceOf(address(this)), burnAmount);

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
            collectorFee -
            platformFee -
            referralInvestorFee -
            referralCollectorFee;

        return sellAmount;
    }

    // f(outputCollectionToken) -> inputARA
    function calculateFundCost(uint256 amount) public view returns (uint256) {
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
                totalSupply(),
                currentCollateral(),
                uint32(info.collateralWeight),
                adjAmount
            );
    }

    // f(outputARA) -> inputCollectionToken
    function calculateLiquidateCost(uint256 amount)
        public
        view
        returns (uint256)
    {
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
                totalSupply(),
                currentCollateral(),
                uint32(info.collateralWeight),
                adjAmount
            );
    }

    function currentCollateral() public view returns (uint256) {
        return (info.dummyCollateralValue + t().balanceOf(address(this)));
    }

    function currentValue() public view returns (uint256) {
        return (currentCollateral() * info.maxWeight) / info.collateralWeight;
    }

    function setTargetPrice(uint256 price, bool vote) public {
        require(
            m().isMember(msg.sender) &&
                balanceOf(msg.sender) > 0 &&
                !info.isAuction &&
                !info.isFreeze
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
            _transfer(
                address(this),
                m().getReferral(info.collector),
                collectorFee
            );
        }

        _transfer(address(this), to, transferAmount);

        if (!shareholders[shareholderIndexs[to]].exists) {
            shareholderIndexs[to] = info.totalShareholder;
            shareholders[shareholderIndexs[to]].exists = true;
            shareholders[shareholderIndexs[to]].addr = to;
            info.totalShareholder += 1;
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
                !info.isAuction &&
                !info.isFreeze
        );

        info.isAuction = true;

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
                info.isAuction &&
                !info.isFreeze &&
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
            info.isAuction &&
                !info.isFreeze &&
                block.timestamp >= auction.closeAuctionTimestamp
        );

        info.isAuction = false;
        info.isFreeze = true;

        for (uint32 i = 0; i < info.totalNft; i++) {
            n().transferFrom(address(this), auction.bidder, nfts[i]);
        }

        uint256 totalCollateral = t().balanceOf(address(this));
        uint256 remainCollateral = totalCollateral;

        for (uint32 i = 0; i < info.totalShareholder; i++) {
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
