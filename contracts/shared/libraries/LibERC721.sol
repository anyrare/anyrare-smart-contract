// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC721Receiver.sol";

library LibERC721 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

    function checkOnERC721Received(
        address _operator,
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_to)
        }
        if (size > 0) {
            require(
                ERC721_RECEIVED ==
                    IERC721Receiver(_to).onERC721Received(
                        _operator,
                        _from,
                        _tokenId,
                        _data
                    ),
                "LibERC721: Transfer rejected/failed by _to"
            );
        }
    }
}
