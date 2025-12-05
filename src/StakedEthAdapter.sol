// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/*
 * @title StakedEthAdapter
 * @author Rebased Protocol Team
 * @notice Adapter for bridging staked ETH via LayerZero OFT
 */

import {OFTAdapter} from "@layerzerolabs/oft-evm/contracts/OFTAdapter.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IStETH} from "./external/IStETH.sol";

contract StakedEthAdapter is OFTAdapter {
    // ═══════════════════════════════════════════════════════════════════════════
    // STATE
    // ═══════════════════════════════════════════════════════════════════════════

    mapping(address => uint256) public userShares;

    // ═══════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════════════

    constructor(
        address tokenAddr,
        address lzEndpoint,
        address admin
    ) OFTAdapter(tokenAddr, lzEndpoint, admin) Ownable(admin) {}

    // ═══════════════════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════

    function convertSharesToEth(uint256 shares) public view returns (uint256) {
        IStETH token = IStETH(address(innerToken));
        return (shares * token.totalSupply()) / token.getTotalShares();
    }

    function convertEthToShares(uint256 ethAmount) public view returns (uint256) {
        IStETH token = IStETH(address(innerToken));
        return (ethAmount * token.getTotalShares()) / token.totalSupply();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // LEGACY COMPATIBILITY
    // ═══════════════════════════════════════════════════════════════════════════

    function sharesPerUser(address user) external view returns (uint256) { return userShares[user]; }
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
        uint32
    ) internal virtual override returns (uint256 amountReceivedLD) {
        uint256 shares = convertEthToShares(amountLD);
        userShares[to] += shares;
        innerToken.transfer(to, amountLD);
        return amountLD;
    }
}

