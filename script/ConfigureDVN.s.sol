// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/*
 * @title ConfigureDVN
 * @notice Script to configure DVN settings for LayerZero
 */

import "forge-std/src/Script.sol";
import "forge-std/src/console.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "lz-evm-messagelib/contracts/uln/UlnBase.sol";

contract ConfigureDVN is Script {
    // ═══════════════════════════════════════════════════════════════════════════
    // CONFIG
    // ═══════════════════════════════════════════════════════════════════════════

    uint32 private constant ULN_TYPE = 2;

    address private rebasedContract = 0x8eE74Bfc34e7e2e257887d54a59DAD1b2BD80Cc3;
    ILayerZeroEndpointV2 private endpoint = ILayerZeroEndpointV2(0x6EDCE65403992e310A62460808c4b910D972f10f);
    address private dvnAddress = 0xbf6FF58f60606EdB2F190769B951D825BCb214E2;
    uint32 private targetEid = 4294967295;
    address private signerAddr = 0x1c46D242755040a0032505fD33C6e8b83293a332;

    // ═══════════════════════════════════════════════════════════════════════════
    // EXECUTION
    // ═══════════════════════════════════════════════════════════════════════════

    function run() external {
        address[] memory requiredDvns = new address[](1);
        address[] memory optionalDvns;
        requiredDvns[0] = dvnAddress;

        UlnConfig memory config = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 0,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: requiredDvns,
            optionalDVNs: optionalDvns
        });

        SetConfigParam[] memory params = new SetConfigParam[](1);
        params[0] = SetConfigParam({
            eid: targetEid,
            configType: ULN_TYPE,
            config: abi.encode(config)
        });

        uint256 pk = vm.envUint("KEY");
        vm.startBroadcast(pk);

        endpoint.setConfig(
            rebasedContract,
            0xC1868e054425D378095A003EcbA3823a5D0135C9,
            params
        );

        vm.stopBroadcast();
    }
}

