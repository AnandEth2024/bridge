// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// /*
//  *    ████████╗ █████╗ ███████╗███████╗███████╗████████╗███████╗
//  *    ╚══██╔══╝██╔══██╗██╔════╝██╔════╝██╔════╝╚══██╔══╝██╔════╝
//  *       ██║   ███████║███████╗███████╗█████╗     ██║   ███████╗
//  *       ██║   ██╔══██║╚════██║╚════██║██╔══╝     ██║   ╚════██║
//  *       ██║   ██║  ██║███████║███████║███████╗   ██║   ███████║
//  *       ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝   ╚═╝   ╚══════╝
//  *
//  * Real Estate NFT & Tokenization Solution
//  * for more info https://tassets.com/
//  */

// /**
//  * @title Compliance Contract for ERC 105 Protocol token.
//  * @author Abhinav
//  */

// // import {ERC1155VerifySignature} from "./ERC1155VerifySignature.sol";
// import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
// import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
// import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
// import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// contract CompliTo is
//     EIP712Upgradeable,
//     UUPSUpgradeable,
//     AccessControlUpgradeable
// {
//     bytes32 public constant EIP712_DOMAIN_TYPEHASH =
//         keccak256(
//             "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
//         );
//     bytes32 public constant EIP712_SET_TRANSFER_APPROVAL_TYPEHASH =
//         keccak256(
//             "SetTransferApproval(address from,address to,uint256 id,uint256 value,uint256 nonce)"
//         );

//     mapping(address => mapping(uint => uint)) internal _nonces;

//     /// @custom:oz-upgrades-unsafe-allow constructor
//     constructor() {
//         _disableInitializers();
//     }

//     address public owner;

//     function initialize() public initializer {
//         __AccessControl_init();
//         _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
//         __EIP712_init_unchained("CompliTo", "1");
//         owner = msg.sender;
//     }

//     function getNonce(uint id) public view returns (uint) {
//         return _nonces[msg.sender][id];
//     }

//     function increaseNonce(address account, uint id) internal {
//         _nonces[account][id]++;
//     }

//     /**
//      * @dev Retrieves the nonce associated with a given address.
//      * @param _account The address for which the nonce is to be retrieved.
//      * @return The nonce value associated with the given address.
//      */

//     function getNonceFor(address _account, uint id) public view returns (uint) {
//         return _nonces[_account][id];
//     }

//     function _generateHashType(
//         address _from,
//         address _to,
//         uint _id,
//         uint _value,
//         uint _nonce
//     ) internal view returns (bytes32 digest) {
//         digest = _hashTypedDataV4(
//             keccak256(
//                 abi.encode(
//                     EIP712_SET_TRANSFER_APPROVAL_TYPEHASH,
//                     _from,
//                     _to,
//                     _id,
//                     _value,
//                     _nonce
//                 )
//             )
//         );
//     }

//     function verifySignature(
//         address _from,
//         address _to,
//         address _signer,
//         uint _id,
//         uint _value,
//         uint _nonce,
//         bytes memory _signature
//     ) public view returns (bool status) {
//         bytes32 digest = _hashTypedDataV4(
//             keccak256(
//                 abi.encode(
//                     EIP712_SET_TRANSFER_APPROVAL_TYPEHASH,
//                     _from,
//                     _to,
//                     _id,
//                     _value,
//                     _nonce
//                 )
//             )
//         );
//         return _signer == ECDSAUpgradeable.recover(digest, _signature);
//     }

//     function isValidSignature(
//         address _signer,
//         bytes32 _hash,
//         bytes memory _signature
//     ) public pure returns (bool) {
//         return _signer == ECDSAUpgradeable.recover(_hash, _signature);
//     }

//     mapping(bytes32 => bytes) internal _transferApproval;

//     function verifyTransfer(
//         address from,
//         address to,
//         uint id,
//         uint value,
//         uint nonce,
//         bytes memory data
//     ) external view returns (bool status) {
//         bytes32 digest = _generateHashType(from, to, id, value, nonce);
//         if (data.length > 0) {
//             return owner == ECDSAUpgradeable.recover(digest, data);
//         } else {
//             return
//                 owner ==
//                 ECDSAUpgradeable.recover(digest, getComplianceApproval(digest));
//         }
//     }

//     /**
//      * @dev Retrieves the signature associated with hash
//      *
//      * @param _hash  Typed structured data hash for which the associated signature is being retrieved.
//      * @return signature The signature associated with the given hash.
//      */
//     function getComplianceApproval(
//         bytes32 _hash
//     ) public view returns (bytes memory signature) {
//         signature = _transferApproval[_hash];
//         return signature;
//     }

//     /**
//      * @dev Sets the compliance approval for a given hash by storing the corresponding signature.
//      *
//      * @param _hash The hash value for which the compliance approval is being set.
//      * @param _signature The signature associated with the hash.
//      *
//      */
//     function setComplianceApproval(
//         bytes32 _hash,
//         bytes calldata _signature
//     ) public {
//         _transferApproval[_hash] = _signature;
//     }

//     function setComplianceApprovals(
//         bytes32[] calldata _hash,
//         bytes[] calldata _signature
//     ) public {
//         for (uint i = 0; i < _hash.length; i++) {
//             _transferApproval[_hash[i]] = _signature[i];
//         }
//     }

//     function _removeComplianceApproval(bytes32 _hash) internal {
//         delete _transferApproval[_hash];
//     }

//     function _authorizeUpgrade(
//         address newImplementation
//     ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
// }