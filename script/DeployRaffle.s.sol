// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle raffle, HelperConfig helperConfig) {
        helperConfig = new HelperConfig();
        (
            uint64 subscriptionId,
            bytes32 keyHash,
            uint256 interval,
            uint256 entranceFee,
            uint32 callbackGasLimit,
            address vrfCoordinator
        ) = helperConfig.activeNetworkConfig();
        vm.startBroadcast();
        raffle = new Raffle(
               subscriptionId,
               keyHash,
               interval,
               entranceFee,
               callbackGasLimit,
               vrfCoordinator
        );
        vm.stopBroadcast();
    }
}
