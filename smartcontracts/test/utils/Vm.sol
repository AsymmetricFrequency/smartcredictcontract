// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @dev Minimal Foundry cheatcode interface used by the tests. Vendored so the project
///      compiles and tests run with no forge-std submodule.
interface Vm {
    function warp(uint256 timestamp) external;
    function prank(address sender) external;
    function expectRevert() external;
    function expectRevert(bytes4 revertData) external;
}

address constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
