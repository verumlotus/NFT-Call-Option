// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/**
 * Interface for IERC20 tokens that implement EIP 2612 Permit
 * @author verum
 */
interface IERC20Permit {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}