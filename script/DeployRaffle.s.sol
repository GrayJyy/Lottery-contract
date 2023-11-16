// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Integrations.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle raffle, HelperConfig helperConfig) {
        helperConfig = new HelperConfig();
        (
            uint64 subscriptionId,
            bytes32 keyHash,
            uint256 interval,
            uint256 entranceFee,
            uint32 callbackGasLimit,
            address vrfCoordinator,
            address link,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();
        if (subscriptionId == 0) {
            // if you are in a local network, here to mock the integration of the real chain with chainlink just like interact with the chainlink ui
            // step1. create a subscription
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(vrfCoordinator, deployerKey);
            // step2. fund the subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(vrfCoordinator, subscriptionId, link, deployerKey);
        }
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
        // be careful,add consumer must be after the raffle is deployed!!
        // step3. add the consumer
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), vrfCoordinator, subscriptionId, deployerKey);
    }
}
