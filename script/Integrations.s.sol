// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract CreateSubscription is Script {
    HelperConfig public helperConfig;

    function run() public returns (uint64 subscriptionId) {
        subscriptionId = createSubscriptionUsingConfig();
    }

    function createSubscriptionUsingConfig() public returns (uint64 subscriptionId) {
        helperConfig = new HelperConfig();
        (,,,,, address vrfCoordinator,) = helperConfig.activeNetworkConfig();
        subscriptionId = createSubscription(vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns (uint64 subscriptionId) {
        console.log("Creating subscription on chainId: %s", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorMock = VRFCoordinatorV2Mock(vrfCoordinator);
        subscriptionId = vrfCoordinatorMock.createSubscription();
        vm.stopBroadcast();
        console.log("Created subscription with id: %s", subscriptionId);
    }
}

contract FundSubscription is Script {
    HelperConfig public helperConfig;
    LinkToken public linkToken;
    uint96 public constant FOUND_AMOUNT = 1 ether;

    function run() public {
        fundSubscriptionUsingConfig();
    }

    function fundSubscriptionUsingConfig() public {
        helperConfig = new HelperConfig();
        (uint64 subscriptionId,,,,, address vrfCoordinator, address link) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subscriptionId, link);
    }

    function fundSubscription(address vrfCoordinator, uint64 subscriptionId, address link) public {
        console.log("Funding subscription on chainId: %s", block.chainid);
        console.log("Found amount: %s", FOUND_AMOUNT);
        console.log("Found subscription id: %s", subscriptionId);
        console.log("Found vrfCoordinator: %s", vrfCoordinator);
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock vrfCoordinatorMock = VRFCoordinatorV2Mock(vrfCoordinator);
            vrfCoordinatorMock.fundSubscription(subscriptionId, FOUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            linkToken = LinkToken(link);
            linkToken.transferAndCall(vrfCoordinator, FOUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }
}
