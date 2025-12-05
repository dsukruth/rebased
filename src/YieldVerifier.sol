// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * @title YieldVerifier
 * @author Rebased Protocol Team
 * @notice Beacon chain oracle report verifier using EIP-4788
 */

interface IOracleReporter {
    function getLastCompletedReport() external view returns (
        uint256 epochId,
        uint256 beaconBalance,
        uint256 beaconValidators,
        uint256 rewardsVaultBalance,
        uint256 exitedValidatorsCount,
        uint256 timestamp
    );

    function getLastCompletedEpochId() external view returns (uint256);
}

contract ChainConstants {
    // ═══════════════════════════════════════════════════════════════════════════
    // BEACON CHAIN PARAMETERS
    // ═══════════════════════════════════════════════════════════════════════════

    uint256 internal constant SLOT_DURATION = 12;
    uint256 internal constant SLOTS_IN_EPOCH = 32;
    uint256 internal constant EPOCH_DURATION = SLOT_DURATION * SLOTS_IN_EPOCH;
    uint256 internal constant GENESIS_TIME = 1606824023;
    uint256 internal constant MERGE_TIME = 1663224162;
    uint256 internal constant MERGE_BLOCK = 15537393;

    // ═══════════════════════════════════════════════════════════════════════════
    // VALIDATION
    // ═══════════════════════════════════════════════════════════════════════════

    function validateEpochConsistency(
        uint256 epochId,
        uint256 blockNum,
        uint256 blockTime
    ) public pure returns (bool) {
        if (blockNum < MERGE_BLOCK || blockTime < MERGE_TIME) {
            return false;
        }

        uint256 epochsFromGenesis = (blockTime - GENESIS_TIME) / EPOCH_DURATION;
        uint256 minEpoch = epochsFromGenesis > 2 ? epochsFromGenesis - 2 : 0;
        uint256 maxEpoch = epochsFromGenesis + 1;

        uint256 blocksSinceMerge = blockNum - MERGE_BLOCK;
        uint256 epochsFromBlocks = blocksSinceMerge * SLOT_DURATION / EPOCH_DURATION;

        bool inTimeRange = epochId >= minEpoch && epochId <= maxEpoch;
        bool inBlockRange = epochId >= epochsFromBlocks - 3 && epochId <= epochsFromBlocks + 3;

        uint256 epochStart = GENESIS_TIME + (epochId * EPOCH_DURATION);
        bool validTiming = epochStart <= blockTime;
        bool reasonableDuration = blockTime - epochStart <= EPOCH_DURATION * 3;

        return inTimeRange && inBlockRange && validTiming && reasonableDuration;
    }

    function currentEpochEstimate(uint256 blockTime) public pure returns (uint256) {
        require(blockTime >= GENESIS_TIME, "InvalidTimestamp");
        return (blockTime - GENESIS_TIME) / EPOCH_DURATION;
    }
}

contract YieldVerifier is ChainConstants {
    // ═══════════════════════════════════════════════════════════════════════════
    // ERRORS & EVENTS
    // ═══════════════════════════════════════════════════════════════════════════

    error BlockRootNotFound();

    event ReportValidated(
        uint256 indexed epochId,
        uint256 balance,
        bytes32 blockRoot,
        uint256 blockNum
    );

    // ═══════════════════════════════════════════════════════════════════════════
    // STATE
    // ═══════════════════════════════════════════════════════════════════════════

    address public immutable rootProvider;
    mapping(uint256 => bool) public validatedEpochs;
    uint256 public latestBalance;
    uint256 public latestEpoch;

    // ═══════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════════════

    constructor(address provider_) {
        rootProvider = provider_;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // VERIFICATION
    // ═══════════════════════════════════════════════════════════════════════════

    function submitReport(
        uint256 blockNum,
        uint256 blockTime,
        uint256 epochId,
        uint256 balance,
        uint256 validators
    ) external {
        require(epochId > latestEpoch, "StaleEpoch");
        require(!validatedEpochs[epochId], "AlreadyValidated");

        bytes32 root = _fetchBlockRoot(uint64(blockTime));
        require(root != bytes32(0), "InvalidRoot");
        require(validateEpochConsistency(epochId, blockNum, blockTime), "EpochMismatch");

        validatedEpochs[epochId] = true;
        latestBalance = balance;
        latestEpoch = epochId;

        emit ReportValidated(epochId, balance, root, blockNum);
    }

    function _fetchBlockRoot(uint64 blockTime) internal view returns (bytes32 root) {
        (bool ok, bytes memory data) = rootProvider.staticcall(abi.encode(blockTime));
        if (!ok || data.length == 0) revert BlockRootNotFound();
        root = abi.decode(data, (bytes32));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // LEGACY COMPATIBILITY
    // ═══════════════════════════════════════════════════════════════════════════

    function verifyReport(uint256 b, uint256 t, uint256 e, uint256 bal, uint256 v) external {
        this.submitReport(b, t, e, bal, v);
    }

    function lastVerifiedBalance() external view returns (uint256) { return latestBalance; }
    function lastVerifiedEpoch() external view returns (uint256) { return latestEpoch; }
    function verifiedEpochs(uint256 e) external view returns (bool) { return validatedEpochs[e]; }
    function isEpochConsistent(uint256 e, uint256 b, uint256 t) external pure returns (bool) {
        return validateEpochConsistency(e, b, t);
    }
    function estimateCurrentEpoch(uint256 t) external pure returns (uint256) {
        return currentEpochEstimate(t);
    }
}

