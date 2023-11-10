// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title a contract for raffle
 * @author GrayJiang
 * @notice for learing solidity
 * @dev implements Chainlink VRF v2
 */
contract Raffle is VRFConsumerBaseV2 {
    error Raffle__NotEnoughFee();
    error Raffle__TimeNotUp();
    error Raffle__PaymentFailed();
    error Raffle__NotOpen();

    enum RaffleStatus {
        OPEN, // 0
        CALCULATING // 1
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;

    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint256 private s_startTime;
    address payable private s_winner;
    address payable[] s_participants;
    RaffleStatus private s_raffleStatus = RaffleStatus.OPEN;

    event EnterRaffle(address indexed participant);
    event PickWinner(address indexed winner);

    constructor(
        uint256 entranceFee_,
        uint256 interval_,
        uint256 startTime_,
        address vrfCoordinator_,
        bytes32 keyHash_,
        uint64 subscriptionId_,
        uint32 callbackGasLimit_
    ) VRFConsumerBaseV2(vrfCoordinator_) {
        i_entranceFee = entranceFee_;
        i_interval = interval_;
        s_startTime = startTime_;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
        i_keyHash = keyHash_;
        i_subscriptionId = subscriptionId_;
        i_callbackGasLimit = callbackGasLimit_;
    }

    function enterRaffle() external payable {
        if (s_raffleStatus != RaffleStatus.OPEN) {
            revert Raffle__NotOpen();
        }
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughFee();
        }
        s_participants.push(payable(msg.sender));
        emit EnterRaffle(msg.sender);
    }

    function pinkWinner() external {
        if (block.timestamp < s_startTime + i_interval) {
            revert Raffle__TimeNotUp();
        }
        s_raffleStatus = RaffleStatus.CALCULATING;
        i_vrfCoordinator.requestRandomWords(
            i_keyHash, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGasLimit, NUM_WORDS
        );
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        uint256 winnerIndex = randomWords[0] % s_participants.length;
        address payable winner = s_participants[winnerIndex];
        s_winner = winner;
        emit PickWinner(winner);
        (bool success,) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__PaymentFailed();
        }
        s_participants = new address payable[](0); // empty participants array
        s_startTime = block.timestamp; // reset startTime
        s_raffleStatus = RaffleStatus.OPEN;
    }

    /**
     * Getting Functions
     */
    function entranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
