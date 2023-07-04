// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IERC1155CrossChain is IERC1155 {
    function transferRemote(
        string calldata destinationChain,
        address destinationAddress,
        uint256 tokenId,
        uint256 amount
    ) external payable;
}