// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/*
 * @title IRebased
 * @notice Interface for the Rebased cross-chain reader
 */

interface IRebased {
    // ═══════════════════════════════════════════════════════════════════════════
    // STRUCTS
    // ═══════════════════════════════════════════════════════════════════════════

    struct ReadRequest {
        uint16 appRequestLabel;
        uint32 targetEid;
        bool isBlockNum;
        uint64 blockNumOrTimestamp;
        uint16 confirmations;
        address to;
    }

    struct ComputeRequest {
        uint8 computeSetting;
        uint32 targetEid;
        bool isBlockNum;
        uint64 blockNumOrTimestamp;
        uint16 confirmations;
        address to;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════

    function syncRebaseData(bytes calldata extraOps) external payable;
    function lastTotalSupply() external view returns (uint256);
    function lastTotalShares() external view returns (uint256);
}

