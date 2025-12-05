// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/*
 * @title Rebased
 * @author Rebased Protocol Team
 * @notice Cross-chain rebasing token reader via LayerZero Read
 */

import {OAppRead} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppRead.sol";
import {MessagingFee, Origin} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EVMCallRequestV1, EVMCallComputeV1, ReadCodecV1} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/ReadCodecV1.sol";
import {OptionsBuilder} from "@lz-oapp-v2/libs/OptionsBuilder.sol";
import {IStETH} from "./external/IStETH.sol";
import {IRebased} from "./IRebased.sol";

contract Rebased is OAppRead, IRebased {
    using OptionsBuilder for bytes;

    // ═══════════════════════════════════════════════════════════════════════════
    // CONSTANTS
    // ═══════════════════════════════════════════════════════════════════════════

    uint8 private constant COMPUTE_MAP_ONLY = 0;
    uint8 private constant COMPUTE_REDUCE_ONLY = 1;
    uint8 private constant COMPUTE_MAP_REDUCE = 2;
    uint8 private constant COMPUTE_NONE = 3;
    uint8 private constant MSG_TYPE_READ = 1;
    uint32 private constant LZ_READ_CHANNEL = 4294967295;
    uint32 private constant EID_THRESHOLD = 4294965694;

    // ═══════════════════════════════════════════════════════════════════════════
    // STATE
    // ═══════════════════════════════════════════════════════════════════════════

    address public stakedToken;
    uint32 public sourceChainEid = 40161;
    uint256 public cachedSupply;
    uint256 public cachedShares;
    uint256 public syncTimestamp;

    // ═══════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════════════

    constructor(
        address endpoint_,
        address admin_,
        address stakedToken_
    ) OAppRead(endpoint_, admin_) Ownable(admin_) {
        stakedToken = stakedToken_;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // EXTERNAL FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════

    function syncRebaseData(bytes calldata) external payable {
        bytes memory command = _buildCommand();
        bytes memory opts = _buildOptions(250_000, 0);

        _lzSend(
            LZ_READ_CHANNEL,
            command,
            opts,
            MessagingFee(msg.value, 0),
            payable(msg.sender)
        );
    }

    function lzReduce(
        bytes calldata,
        bytes[] calldata responses
    ) external pure returns (bytes memory) {
        require(responses.length == 2, "InvalidResponseCount");
        return bytes.concat(responses[0], responses[1]);
    }

    function estimateFee(
        uint32 channel,
        bytes memory opts,
        bool payWithLzToken
    ) public view returns (MessagingFee memory) {
        bytes memory command = _buildCommand();
        return _quote(channel, command, opts, payWithLzToken);
    }

    function estimateFeeAndUpdate(
        uint32 channel,
        bytes memory opts,
        bool payWithLzToken
    ) public returns (MessagingFee memory) {
        bytes memory command = _buildCommand();
        syncTimestamp = block.timestamp;
        return _quote(channel, command, opts, payWithLzToken);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════

    function lastTotalSupply() external view returns (uint256) {
        return cachedSupply;
    }

    function lastTotalShares() external view returns (uint256) {
        return cachedShares;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // INTERNAL FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════

    function _buildCommand() public view returns (bytes memory) {
        EVMCallRequestV1[] memory requests = new EVMCallRequestV1[](2);

        requests[0] = EVMCallRequestV1({
            appRequestLabel: 1,
            targetEid: sourceChainEid,
            isBlockNum: false,
            blockNumOrTimestamp: uint64(block.timestamp),
            confirmations: 10,
            to: stakedToken,
            callData: abi.encodeWithSelector(IStETH.totalSupply.selector)
        });

        requests[1] = EVMCallRequestV1({
            appRequestLabel: 2,
            targetEid: sourceChainEid,
            isBlockNum: false,
            blockNumOrTimestamp: uint64(block.timestamp),
            confirmations: 10,
            to: stakedToken,
            callData: abi.encodeWithSelector(IStETH.getTotalShares.selector)
        });

        EVMCallComputeV1 memory compute = EVMCallComputeV1({
            computeSetting: COMPUTE_REDUCE_ONLY,
            targetEid: sourceChainEid,
            isBlockNum: false,
            blockNumOrTimestamp: uint64(block.timestamp),
            confirmations: 10,
            to: address(this)
        });

        return ReadCodecV1.encode(0, requests, compute);
    }

    function _buildOptions(
        uint128 gasLimit,
        uint128 nativeValue
    ) private pure returns (bytes memory) {
        return OptionsBuilder.newOptions().addExecutorLzReceiveOption(gasLimit, nativeValue);
    }

    function _lzReceive(
        Origin calldata origin,
        bytes32 guid,
        bytes calldata payload,
        address executor,
        bytes calldata extra
    ) internal virtual override {
        if (origin.srcEid > EID_THRESHOLD) {
            _handleReadResponse(origin, guid, payload, executor, extra);
        } else {
            _handleMessage(origin, guid, payload, executor, extra);
        }
    }

    function _handleMessage(
        Origin calldata,
        bytes32,
        bytes calldata payload,
        address,
        bytes calldata
    ) internal virtual {
        bool _unused = abi.decode(payload, (bool));
    }

    function _handleReadResponse(
        Origin calldata,
        bytes32,
        bytes calldata payload,
        address,
        bytes calldata
    ) internal virtual {
        (uint256 supply, uint256 shares) = abi.decode(payload, (uint256, uint256));
        cachedSupply = supply;
        cachedShares = shares;
        syncTimestamp = block.timestamp;
    }
}

