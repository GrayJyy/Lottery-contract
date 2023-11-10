// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

/**
 * @title a contract for raffle
 * @author GrayJiang
 * @notice for learing solidity
 * @dev implements Chainlink VRF v2
 */
contract Raffle {
    error Raffle__NotEnoughFee();
    error Raffle__TimeNotUp();

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint256 private immutable i_startTime;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] s_participants;

    event EnterRaffle(address indexed participant);

    constructor(
        uint256 entranceFee_,
        uint256 interval_,
        uint256 startTime_,
        address vrfCoordinator_,
        bytes32 keyHash_,
        uint64 subscriptionId_,
        uint32 callbackGasLimit_
    ) {
        i_entranceFee = entranceFee_;
        i_interval = interval_;
        i_startTime = startTime_;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
        i_keyHash = keyHash_;
        i_subscriptionId = subscriptionId_;
        i_callbackGasLimit = callbackGasLimit_;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughFee();
        }
        s_participants.push(payable(msg.sender));
        emit EnterRaffle(msg.sender);
    }

    function pinkWinner() external {
        if (block.timestamp < i_startTime + i_interval) {
            revert Raffle__TimeNotUp();
        }
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGasLimit, NUM_WORDS
        );
    }

    /**
     * Getting Functions
     */
    function entranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
