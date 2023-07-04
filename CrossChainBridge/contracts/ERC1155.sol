// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IAxelarGateway } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import { IAxelarGasService } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
// import { AxelarGasService } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/gas-service/AxelarGasService.sol";
import { IERC1155CrossChain } from './interfaces/IERC1155Crosschain.sol';
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { AxelarExecutable } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import { StringToAddress, AddressToString } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/AddressString.sol";


contract ERC1155CrossChain is AxelarExecutable, ERC1155,IERC1155CrossChain{
    using StringToAddress for string;
    using AddressToString for address;
    error AlreadyInitialized();

    event FalseSender(string sourceChain, string sourceAddress);

    IAxelarGasService public immutable gasService;

    constructor(
        address gateway_,
        address gasReceiver_,
        string memory uri_
    ) AxelarExecutable(gateway_) ERC1155(uri_) {
        gasService = IAxelarGasService(gasReceiver_);
    }


    // This is for testing.
    function giveMe(uint256 tokenId, uint256 amount) external {
        _mint(msg.sender, tokenId, amount, "");
    }

    function transferRemote(
        string calldata destinationChain,
        address destinationAddress,
        uint256 tokenId,
        uint256 amount
    ) external payable  {
        require(msg.value > 0, 'Gas payment is required');
        _burn(msg.sender, tokenId, amount);
        bytes memory payload = abi.encode(msg.sender, tokenId, amount);
        // console.logAddress(msg.sender);
        string memory stringAddress = address(this).toString();
            gasService.payNativeGasForContractCall{ value: msg.value }(
                address(this),
                destinationChain,
                stringAddress,
                payload,
                msg.sender
            );
        gateway.callContract(destinationChain, stringAddress, payload);
    }

    function _execute(
        string calldata, /*sourceChain*/
        string calldata sourceAddress,
        bytes calldata payload
    ) internal override {
        // Address=sourceAddress.toAddress();
        if (sourceAddress.toAddress() != address(this)) {
            emit FalseSender(sourceAddress, sourceAddress);
            return;
        }
        (address to, uint256 tokenId, uint256 amount) = abi.decode(payload, (address, uint256, uint256));
        _mint(to, tokenId, amount, "");
    }

    function contractId() external pure returns (bytes32) {
        return keccak256("example");
    }
}
