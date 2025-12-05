// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/*
 * @title RebasedOFT
 * @author Rebased Protocol Team
 * @notice OFT implementation with rebasing balance mechanics
 */

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";

contract RebasedOFT is OFT {
    // ═══════════════════════════════════════════════════════════════════════════
    // STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════════════

    uint256 public cachedSupply;
    uint256 public cachedShares;
    uint256 public syncedAt;
    mapping(address => uint256) public userShares;

    // ═══════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════════════

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        address lzEndpoint,
        address admin
    ) OFT(tokenName, tokenSymbol, lzEndpoint, admin) Ownable(admin) {}

    // ═══════════════════════════════════════════════════════════════════════════
    // EXTERNAL FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════

    function balanceOf(address account) public view virtual override returns (uint256) {
        return convertSharesToEth(userShares[account]);
    }

    function setRebaseData(uint256 newSupply, uint256 newShares) external {
        cachedSupply = newSupply;
        cachedShares = newShares;
        syncedAt = block.timestamp;
    }

    function convertSharesToEth(uint256 shares) public view returns (uint256) {
        if (cachedShares == 0) return 0;
        return (shares * cachedSupply) / cachedShares;
    }

    function convertEthToShares(uint256 ethAmount) public view returns (uint256) {
        if (cachedSupply == 0) return 0;
        return (ethAmount * cachedShares) / cachedSupply;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // LEGACY COMPATIBILITY
    // ═══════════════════════════════════════════════════════════════════════════

    function lastTotalSupply() external view returns (uint256) { return cachedSupply; }
    function lastTotalShares() external view returns (uint256) { return cachedShares; }
    function lastUpdateTimestamp() external view returns (uint256) { return syncedAt; }
    function sharesPerUser(address user) external view returns (uint256) { return userShares[user]; }
    function updateRebaseInfo(uint256 s, uint256 sh) external { setRebaseData(s, sh); }
    function getEthByShares(uint256 sh) external view returns (uint256) { return convertSharesToEth(sh); }
    function getSharesByEth(uint256 e) external view returns (uint256) { return convertEthToShares(e); }

    // ═══════════════════════════════════════════════════════════════════════════
    // INTERNAL OVERRIDES
    // ═══════════════════════════════════════════════════════════════════════════

    function _debit(
        address from,
        uint256 amountLD,
        uint256 minAmountLD,
        uint32 dstEid
    ) internal virtual override returns (uint256 amountSentLD, uint256 amountReceivedLD) {
        uint256 shares = convertEthToShares(amountLD);
        userShares[from] -= shares;
        return super._debit(from, amountLD, minAmountLD, dstEid);
    }

    function _credit(
        address to,
        uint256 amountLD,
        uint32 srcEid
    ) internal virtual override returns (uint256 amountReceivedLD) {
        uint256 shares = convertEthToShares(amountLD);
        userShares[to] += shares;
        return super._credit(to, amountLD, srcEid);
    }
}

