// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import {AppStorage, AssetInfo, AssetAuction} from "../libraries/LibAppStorage.sol";
import {IAsset} from "../interfaces/IAsset.sol";
import {DataFacet} from "../../Anyrare/facets/DataFacet.sol";
import "../../shared/interfaces/IERC721.sol";
import "../../shared/interfaces/IERC721Receiver.sol";
import "hardhat/console.sol";

contract AssetFacet is IERC721 {
    AppStorage internal s;

    function init(
        address owner,
        string memory name,
        string memory symbol
    ) external {
        require(s.owner == address(0), "AssetFacet: already init");
        s.owner = owner;
        s.name = name;
        s.symbol = symbol;
    }

    function mint(IAsset.AssetMintArgs memory args) external {
        require(msg.sender == s.owner, "AssetFacet: no permission to mint");

        s.assets[s.totalAsset].auditor = args.auditor;
        s.assets[s.totalAsset].founder = args.founder;
        s.assets[s.totalAsset].custodian = args.custodian;
        s.assets[s.totalAsset].tokenURI = args.tokenURI;
        s.assets[s.totalAsset].maxWeight = args.maxWeight;
        s.assets[s.totalAsset].founderWeight = args.founderWeight;
        s.assets[s.totalAsset].founderRedeemWeight = args.founderRedeemWeight;
        s.assets[s.totalAsset].founderGeneralFee = args.founderGeneralFee;
        s.assets[s.totalAsset].auditFee = args.auditFee;
        s.assets[s.totalAsset].custodianWeight = args.custodianWeight;
        s.assets[s.totalAsset].custodianGeneralFee = args.custodianGeneralFee;
        s.assets[s.totalAsset].custodianRedeemWeight = args
            .custodianRedeemWeight;
        s.assets[s.totalAsset].custodianRedeemWeight = args.auditFee;
        s.owners[s.totalAsset] = args.auditor;
        s.totalAsset += 1;
    }

    function custodianSign(uint256 tokenId, address custodian) external {
        require(
            msg.sender == s.owner && s.assets[tokenId].custodian == custodian,
            "AssetFacet: no permission to sign"
        );

        s.assets[tokenId].isCustodianSign = true;
    }

    function payFeeAndClaimToken(uint256 tokenId, address founder) external {
        require(
            msg.sender == s.owner &&
                s.assets[tokenId].founder == founder &&
                s.assets[tokenId].isCustodianSign &&
                !s.assets[tokenId].isPayFeeAndClaimToken,
            "AssetFacet: no permission to claim token"
        );

        s.assets[tokenId].isPayFeeAndClaimToken = true;
        s.owners[tokenId] = founder;
        
        s.balances[founder] += 1;
        emit Transfer(address(0), founder, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return interfaceId == type(IERC721).interfaceId;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(
            owner != address(0),
            "AssetFacet: balance query for the zero address"
        );
        return s.balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = s.owners[tokenId];
        require(
            owner != address(0),
            "AssetFacet: owner query for nonexistent token"
        );
        return owner;
    }

    function name() external view override returns (string memory) {
        return s.name;
    }

    function symbol() external view override returns (string memory) {
        return s.symbol;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        return s.assets[tokenId].tokenURI;
    }

    function tokenInfo(uint256 tokenId)
        external
        view
        returns (AssetInfo memory m)
    {
        return s.assets[tokenId];
    }

    function totalAsset() external view returns (uint256) {
        return s.totalAsset;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = AssetFacet.ownerOf(tokenId);
        require(to != owner, "AssetFacet: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "AssetFacet: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "AssetFacet: approved query for nonexistent token"
        );

        return s.tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return s.operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId) || msg.sender == s.owner,
            "AssetFacet: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "AssetFacet: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "AssetFacet: transfer to non ERC721Receiver implementer"
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return s.owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = AssetFacet.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "AssetFacet: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal {
        require(
            msg.sender == s.owner && s.owner != address(0),
            "AssetFacet: no permission to mint"
        );
        require(to != address(0), "AssetFacet: mint to the zero address");
        require(!_exists(tokenId), "AssetFacet: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        s.balances[to] += 1;
        s.owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = AssetFacet.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        s.balances[owner] -= 1;
        delete s.owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            AssetFacet.ownerOf(tokenId) == from &&
                !s.assets[tokenId].isRedeem &&
                !s.assets[tokenId].isFreeze,
            "AssetFacet: transfer of token that is not own"
        );
        require(to != address(0), "AssetFacet: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        s.balances[from] -= 1;
        s.balances[to] += 1;
        s.owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        s.tokenApprovals[tokenId] = to;
        emit Approval(AssetFacet.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "ERC721: approve to caller");
        s.operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        // if (to.isContract()) {
        try
            IERC721Receiver(to).onERC721Received(
                msg.sender,
                from,
                tokenId,
                _data
            )
        returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert(
                    "AssetFacet: transfer to non ERC721Receiver implementer"
                );
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
        // } else {
        //     return true;
        // }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function setOpenAuction(
        address owner,
        uint256 tokenId,
        uint256 closeAuctionPeriodSecond,
        uint256 startingPrice,
        uint256 reservePrice,
        uint256 maxWeight,
        uint256 nextBidWeight
    ) external {
        require(
            msg.sender == s.owner && s.owners[tokenId] == msg.sender,
            "AssetFacet: no permission to set open auction"
        );

        s.auctions[tokenId][s.assets[tokenId].totalAuction] = AssetAuction({
            openAuctionTimestamp: block.timestamp,
            closeAuctionTimestamp: block.timestamp + closeAuctionPeriodSecond,
            owner: owner,
            bidder: address(0x0),
            startingPrice: startingPrice,
            reservePrice: reservePrice,
            value: 0,
            maxBid: 0,
            maxWeight: maxWeight,
            nextBidWeight: nextBidWeight,
            totalBid: 0,
            meetReservePrice: false
        });

        s.assets[tokenId].isAuction = true;
        s.assets[tokenId].totalAuction += 1;
    }
}
