// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CreditCertificateRegistry} from "../src/CreditCertificateRegistry.sol";

/// @dev Minimal cheatcode surface (vendored so the project needs no forge-std submodule).
interface Vm {
    function envUint(string calldata name) external view returns (uint256);
    function envOr(string calldata name, address defaultValue) external view returns (address);
    function addr(uint256 privateKey) external view returns (address);
    function startBroadcast(uint256 privateKey) external;
    function stopBroadcast() external;
}

/// @notice Deploys CreditCertificateRegistry (contract #1).
/// @dev Usage:
///        forge script script/Deploy.s.sol:Deploy \
///          --rpc-url $RPC_URL --broadcast
///      Env:
///        PRIVATE_KEY  (required) deployer key
///        ISSUER       (optional) issuer address; defaults to the deployer
contract Deploy {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function run() external returns (CreditCertificateRegistry registry) {
        uint256 deployerPk = vm.envUint("PRIVATE_KEY");
        address issuer = vm.envOr("ISSUER", vm.addr(deployerPk));

        vm.startBroadcast(deployerPk);
        registry = new CreditCertificateRegistry(issuer);
        vm.stopBroadcast();
    }
}
