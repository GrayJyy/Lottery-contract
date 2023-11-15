// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

/**
 * @title a contract for raffle
 * @author GrayJiang
 * @notice for learing solidity
 * @dev implements Chainlink VRF v2
 */
contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    error Raffle__NotEnoughFee();
    // error Raffle__TimeNotUp();
    error Raffle__PaymentFailed();
    error Raffle__NotOpen();
    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

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
        uint64 subscriptionId_,
        bytes32 keyHash_,
        uint256 interval_,
        uint256 entranceFee_,
        uint32 callbackGasLimit_,
        address vrfCoordinator_
    ) VRFConsumerBaseV2(vrfCoordinator_) {
        i_entranceFee = entranceFee_;
        i_interval = interval_;
        s_startTime = block.timestamp;
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

    function pinkWinner() internal {
        // if (block.timestamp < s_startTime + i_interval) {
        //     revert Raffle__TimeNotUp();
        // }
        s_raffleStatus = RaffleStatus.CALCULATING;
        i_vrfCoordinator.requestRandomWords(
            i_keyHash, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGasLimit, NUM_WORDS
        );
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */
    function checkUpkeep(bytes memory)
        /**
         * checkData
         */
        public
        view
        returns (bool upkeepNeeded, bytes memory)
    /**
     * performData
     */
    {
        bool isOpen = RaffleStatus.OPEN == s_raffleStatus;
        bool timePassed = ((block.timestamp - s_startTime) > i_interval);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance);
        return (upkeepNeeded, "0x0"); // can we comment this out?
    }

    /**
     *
     * @dev
     * chainlink will automatically call this function,and it will be worked when checkUpkeep returns true.Instead of call pinkWinner manually.
     */
    function performUpkeep(bytes calldata)
        /**
         * performData
         */
        external
    {
        (bool checkUpkeep_,) = checkUpkeep("");
        if (!checkUpkeep_) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_participants.length, uint256(s_raffleStatus));
        }
        pinkWinner();
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
    function getRaffleState() public view returns (RaffleStatus) {
        return s_raffleStatus;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getRecentWinner() public view returns (address) {
        return s_winner;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_participants[index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_startTime;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_participants.length;
    }
}
