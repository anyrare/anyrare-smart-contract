pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ARAToken.sol";
import "./Governance.sol";
import "./Member.sol";
import "./NFTFactory.sol";
import "./CollectionDataType.sol";
import "./CollectionUtils.sol";

contract CollectionToken is ERC20, CollectionDataType {
    address private governanceContract;

    mapping(uint32 => uint256) nfts;
    mapping(uint32 => address) targetPriceVotersAddress;
    mapping(address => CollectionTargetPriceVoteInfo) targetPriceVotes;
    mapping(uint32 => CollectionAuctionBid) bids;
    mapping(address => CollectionShareholderIndex) shareholderIndexes;
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
            auction: false,
            freeze: false,
            tokenURI: _tokenURI
        });

        targetPrice = CollectionTargetPrice({
            price: 0,
            totalSum: 0,
            totalVoteToken: 0,
            totalVoter: 0,
            totalVoterIndex: 0
        });

        shareholders[0] = CollectionShareholder({addr: _collector});
        shareholderIndexes[_collector] = CollectionShareholderIndex({
            exists: true,
            id: 0
        });
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

    function n() private returns (NFTFactory) {
        return NFTFactory(g().getNFTFactoryContract());
    }

    function cu() private view returns (CollectionUtils) {
        return CollectionUtils(g().getCollectionUtilsContract());
    }

    function getInfo() public view returns (CollectionInfo memory i) {
        return info;
    }

    function getShareholderIndex(address addr)
        public
        view
        returns (CollectionShareholderIndex memory s)
    {
        return shareholderIndexes[addr];
    }

    function getShareholder(uint32 id)
        public
        view
        returns (CollectionShareholder memory s)
    {
        return shareholders[id];
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

        _mint(_collector, _initialAmount);

        info.totalNft = _totalNft;
        info.exists = true;
    }

    function transferARAFromContract(TransferARA[] memory lists, uint8 length)
        private
    {
        for (uint8 i = 0; i < length; i++) {
            if (lists[i].amount > 0) {
                t().transfer(
                    lists[i].receiver,
                    cu().min(lists[i].amount, t().balanceOf(address(this)))
                );
            }
        }
    }

    function buy(uint256 amount) public payable {
        cu().requireBuy(msg.sender, amount, info);

        t().transferFrom(msg.sender, address(this), amount);
        transferARAFromContract(
            cu().calculateBuyTransferFeeLists(amount, msg.sender, info),
            4
        );

        uint256 mintAmount = cu().calculatePurchaseReturn(
            amount,
            info,
            totalSupply(),
            currentCollateral()
        );

        if (mintAmount > 0) {
            _mint(msg.sender, mintAmount);
        }

        if (!shareholderIndexes[msg.sender].exists) {
            shareholderIndexes[msg.sender] = CollectionShareholderIndex({
                exists: true,
                id: info.totalShareholder
            });
            shareholders[info.totalShareholder] = CollectionShareholder({
                addr: msg.sender
            });
            info.totalShareholder += 1;
        }
    }

    function sell(uint256 amount) public payable {
        cu().requireSell(
            msg.sender,
            amount,
            info,
            balanceOf(msg.sender) >= amount,
            shareholderIndexes[msg.sender].exists
            // true
        );

        _burn(msg.sender, amount);

        uint256 burnAmount = cu().calculateBurnAmount(
            amount,
            info,
            totalSupply(),
            currentCollateral()
        );
        uint256 withdrawAmount = cu().calculateWithdrawAmount(burnAmount);
        info.dummyCollateralValue -= cu().min(
            info.dummyCollateralValue,
            (burnAmount - withdrawAmount)
        );

        transferARAFromContract(
            cu().calculateSellTransferFeeLists(
                withdrawAmount,
                msg.sender,
                info
            ),
            5
        );

        if (targetPriceVotes[msg.sender].vote) {
            targetPrice.totalSum =
                targetPrice.totalSum -
                targetPriceVotes[msg.sender].price *
                cu().min(amount, targetPriceVotes[msg.sender].voteToken);
            targetPrice.totalVoteToken -= cu().min(
                amount,
                targetPriceVotes[msg.sender].voteToken
            );
            targetPrice.price =
                targetPrice.totalSum /
                targetPrice.totalVoteToken;
            targetPriceVotes[msg.sender].voteToken -= cu().min(
                amount,
                targetPriceVotes[msg.sender].voteToken
            );
        }
    }

    function burn(uint256 amount) public payable {
        require(
            m().isMember(msg.sender) &&
                balanceOf(msg.sender) >= amount &&
                amount > 0 &&
                !info.auction &&
                !info.freeze
        );

        _burn(msg.sender, amount);
    }

    // f(inputARA) -> outputCollectionToken
    function calculatePurchaseReturn(uint256 amount)
        public
        view
        returns (uint256)
    {
        return
            cu().calculatePurchaseReturn(
                amount,
                info,
                totalSupply(),
                currentCollateral()
            );
    }

    // f(inputCollectionToken) -> outputARA
    function calculateSaleReturn(uint256 amount) public view returns (uint256) {
        return
            cu().calculateSaleReturn(
                amount,
                info,
                totalSupply(),
                currentCollateral()
            );
    }

    // f(outputCollectionToken) -> inputARA
    function calculateFundCost(uint256 amount) public view returns (uint256) {
        return
            cu().calculateFundCost(
                amount,
                info,
                totalSupply(),
                currentCollateral()
            );
    }

    // f(outputARA) -> inputCollectionToken
    function calculateLiquidateCost(uint256 amount)
        public
        view
        returns (uint256)
    {
        return
            cu().calculateLiquidateCost(
                amount,
                info,
                totalSupply(),
                currentCollateral()
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
                !info.auction &&
                !info.freeze
        );

        if (!targetPriceVotes[msg.sender].vote && vote) {
            if (!targetPriceVotes[msg.sender].exists) {
                targetPriceVotersAddress[targetPrice.totalVoter] = msg.sender;
                targetPrice.totalVoterIndex += 1;
                targetPriceVotes[msg.sender].exists = true;
            }

            targetPrice.totalVoter += 1;
            targetPrice.totalVoteToken += balanceOf(msg.sender);
            targetPrice.totalSum += price * balanceOf(msg.sender);
            targetPrice.price =
                targetPrice.totalSum /
                targetPrice.totalVoteToken;

            targetPriceVotes[msg.sender].vote = true;
            targetPriceVotes[msg.sender].price = price;
            targetPriceVotes[msg.sender].voteToken = balanceOf(msg.sender);
        } else if (targetPriceVotes[msg.sender].vote && vote) {
            targetPrice.totalVoteToken =
                targetPrice.totalVoteToken -
                targetPriceVotes[msg.sender].voteToken +
                balanceOf(msg.sender);
            targetPrice.totalSum =
                targetPrice.totalSum -
                targetPriceVotes[msg.sender].price *
                targetPriceVotes[msg.sender].voteToken +
                price *
                balanceOf(msg.sender);
            targetPrice.price =
                targetPrice.totalSum /
                targetPrice.totalVoteToken;

            targetPriceVotes[msg.sender].price = price;
            targetPriceVotes[msg.sender].voteToken = balanceOf(msg.sender);
        } else if (targetPriceVotes[msg.sender].vote && !vote) {
            targetPrice.totalVoter -= 1;
            targetPrice.totalSum -=
                targetPriceVotes[msg.sender].price *
                targetPriceVotes[msg.sender].voteToken;
            targetPrice.totalVoteToken -= targetPriceVotes[msg.sender]
                .voteToken;
            targetPrice.price = targetPrice.totalVoteToken == 0
                ? 0
                : targetPrice.totalSum / targetPrice.totalVoteToken;

            targetPriceVotes[msg.sender].vote = false;
            targetPriceVotes[msg.sender].price = 0;
            targetPriceVotes[msg.sender].voteToken = 0;
        }
    }

    function transfer(address receiver, uint256 amount)
        public
        override
        returns (bool)
    {
        return transferFrom(msg.sender, receiver, amount);
    }

    function transferFrom(
        address sender,
        address receiver,
        uint256 amount
    ) public override returns (bool) {
        require(
            balanceOf(sender) >= amount &&
                m().isMember(sender) &&
                m().isMember(receiver)
        );

        uint256 platformFee = cu().calculateFeeFromPolicy(
            amount,
            "TRANSFER_COLLECTION_PLATFORM_FEE"
        );
        uint256 collectorFee = (calculateSaleReturn(amount) *
            info.collectorFeeWeight) / info.maxWeight;
        uint256 referralSenderFee = cu().calculateFeeFromPolicy(
            amount,
            "TRANSFER_COLLECTION_REFERRAL_RECEIVER_FEE"
        );

        uint256 referralReceiverFee = cu().calculateFeeFromPolicy(
            amount,
            "TRANSFER_COLLECTION_REFERRAL_SENDER_FEE"
        );
        uint256 transferAmount = amount -
            platformFee -
            collectorFee -
            referralSenderFee -
            referralReceiverFee;

        _transfer(sender, address(this), amount);

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
                m().getReferral(sender),
                referralSenderFee
            );
        }
        if (referralReceiverFee > 0) {
            _transfer(
                address(this),
                m().getReferral(receiver),
                referralReceiverFee
            );
        }
        if (collectorFee > 0) {
            _transfer(
                address(this),
                m().getReferral(info.collector),
                collectorFee
            );
        }

        _transfer(address(this), receiver, transferAmount);

        if (!shareholderIndexes[receiver].exists) {
            shareholderIndexes[receiver] = CollectionShareholderIndex({
                exists: true,
                id: info.totalShareholder
            });
            shareholders[info.totalShareholder] = CollectionShareholder({
                addr: receiver
            });
            info.totalShareholder += 1;
        }

        if (targetPriceVotes[sender].vote) {
            targetPrice.totalSum =
                targetPrice.totalSum -
                targetPriceVotes[sender].price *
                cu().min(amount, targetPriceVotes[sender].voteToken);
            targetPrice.totalVoteToken -= cu().min(
                amount,
                targetPriceVotes[sender].voteToken
            );
            targetPrice.price =
                targetPrice.totalSum /
                targetPrice.totalVoteToken;
            targetPriceVotes[sender].voteToken -= cu().min(
                amount,
                targetPriceVotes[sender].voteToken
            );
        }

        return true;
    }

    function openAuction(uint256 maxBid) public {
        require(
            m().isMember(msg.sender) &&
                t().balanceOf(msg.sender) >= targetPrice.price &&
                !info.auction &&
                !info.freeze
        );

        info.auction = true;

        auction.openAuctionTimestamp = block.timestamp;
        auction.closeAuctionTimestamp =
            block.timestamp +
            g().getPolicy("OPEN_AUCTION_COLLECTION_DURATION").policyValue;
        auction.bidder = msg.sender;
        auction.startingPrice = targetPrice.price;
        auction.value = targetPrice.price;
        auction.maxBid = maxBid;
        auction.nextBidWeight = g()
            .getPolicy("OPEN_AUCTION_COLLECTION_NEXT_BID_WEIGHT")
            .policyWeight;
        auction.maxWeight = g()
            .getPolicy("OPEN_AUCTION_COLLECTION_NEXT_BID_WEIGHT")
            .maxWeight;

        bids[auction.totalBid] = CollectionAuctionBid({
            timestamp: block.timestamp,
            value: targetPrice.price,
            bidder: msg.sender,
            autoRebid: false
        });

        auction.totalBid = 1;

        t().transferFrom(msg.sender, address(this), maxBid);
    }

    function bidAuction(uint256 bidValue, uint256 maxBid) public payable {
        uint256 minBidValue = (auction.value * auction.nextBidWeight) /
            auction.maxWeight +
            auction.value;
        require(
            m().isMember(msg.sender) &&
                (
                    auction.bidder != msg.sender
                        ? t().balanceOf(msg.sender) >= maxBid
                        : t().balanceOf(msg.sender) >= maxBid - auction.maxBid
                ) &&
                info.auction &&
                !info.freeze &&
                maxBid >= minBidValue &&
                bidValue <= maxBid &&
                (block.timestamp < auction.closeAuctionTimestamp)
        );

        if (bidValue < minBidValue && maxBid >= minBidValue) {
            bidValue = minBidValue;
        }

        if (auction.bidder != msg.sender && auction.bidder != address(0x0)) {
            t().transfer(auction.bidder, auction.value);
        }

        bids[auction.totalBid] = CollectionAuctionBid({
            timestamp: block.timestamp,
            value: bidValue,
            bidder: msg.sender,
            autoRebid: false
        });
        auction.totalBid += 1;

        if (maxBid <= auction.maxBid) {
            bids[auction.totalBid] = CollectionAuctionBid({
                timestamp: block.timestamp,
                value: maxBid,
                bidder: auction.bidder,
                autoRebid: true
            });
            auction.value = maxBid;
            auction.totalBid += 1;
        } else {
            t().transferFrom(
                msg.sender,
                address(this),
                auction.bidder != msg.sender ? maxBid : maxBid - auction.maxBid
            );

            if (
                auction.bidder != msg.sender && auction.bidder != address(0x0)
            ) {
                t().transfer(auction.bidder, auction.maxBid);
            }

            auction.bidder = msg.sender;
            auction.value = bidValue;
            auction.maxBid = maxBid;
        }

        if (
            auction.closeAuctionTimestamp <=
            block.timestamp +
                g()
                    .getPolicy("EXTENDED_AUCTION_COLLECTION_TIME_TRIGGER")
                    .policyValue
        ) {
            auction.closeAuctionTimestamp =
                block.timestamp +
                g()
                    .getPolicy("EXTENDED_AUCTION_COLLECTION_DURATION")
                    .policyValue;
        }
    }

    function processAuction() public {
        require(
            info.auction &&
                !info.freeze &&
                block.timestamp >= auction.closeAuctionTimestamp
        );

        info.auction = false;
        info.freeze = true;

        for (uint32 i = 0; i < info.totalNft; i++) {
            n().transferFromCollectionFactory(
                address(this),
                auction.bidder,
                nfts[i]
            );
        }

        if (auction.maxBid > auction.value) {
            t().transfer(auction.bidder, auction.maxBid - auction.value);
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
        if (remainCollateral > 0) {
            t().transfer(g().getManagementFundContract(), remainCollateral);
        }
    }
}
