// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";
// import "../../shared/interfaces/IERC165.sol";
import "../../shared/interfaces/IERC721.sol";
import "../../shared/interfaces/IERC721Receiver.sol";

contract AssetFacet is IERC721 {
    AppStorage internal s;

    function init(
        address _owner,
        string memory _name,
        string memory _symbol
    ) external {
        require(s.owner == address(0), "AssetFacet: already init");
        s.owner = _owner;
        s.name = _name;
        s.symbol = _symbol;
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
        return s.infos[tokenId].tokenURI;
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
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
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
            AssetFacet.ownerOf(tokenId) == from,
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
}
