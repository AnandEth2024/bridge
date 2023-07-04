// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ICompliTo {
    function verifyTransfer(
        address from,
        address to,
        uint id,
        uint value,
        uint nonce,
        bytes memory data
    ) external view returns (bool status);
}




