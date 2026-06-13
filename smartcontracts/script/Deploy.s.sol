// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CreditCertificateRegistry} from "../src/CreditCertificateRegistry.sol";
import {LendingVault} from "../src/LendingVault.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

/// @dev Minimal cheatcode surface (vendored so the project needs no forge-std submodule).
interface Vm {
    function envUint(string calldata name) external view returns (uint256);
    function envOr(string calldata name, address defaultValue) external view returns (address);
    function addr(uint256 privateKey) external view returns (address);
    function startBroadcast(uint256 privateKey) external;
    function stopBroadcast() external;
}

/// @notice Deploys both LendSignal contracts.
/// @dev Usage:
///        forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --broadcast
///      Env:
///        PRIVATE_KEY  (required) deployer key
///        ISSUER       (optional) certificate issuer; defaults to the deployer
///        ASSET        (optional) ERC20 loan asset; if unset, a MockERC20 is deployed
///        ENS_REGISTRY (optional) ENS registry address; if set, the ENS gate is wired on
contract Deploy {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function run()
        external
        returns (CreditCertificateRegistry registry, LendingVault vault, address asset)
    {
        uint256 deployerPk = vm.envUint("PRIVATE_KEY");
        address issuer = vm.envOr("ISSUER", vm.addr(deployerPk));
        asset = vm.envOr("ASSET", address(0));
        address ensRegistry = vm.envOr("ENS_REGISTRY", address(0));

        vm.startBroadcast(deployerPk);

        registry = new CreditCertificateRegistry(issuer);

        if (ensRegistry != address(0)) {
            registry.setEnsRegistry(ensRegistry);
            registry.setEnsGateEnabled(true);
        }

        if (asset == address(0)) {
            asset = address(new MockERC20("Mock USD Coin", "mUSDC", 6));
        }

        vault = new LendingVault(IERC20(asset), registry);

        vm.stopBroadcast();
    }
}
