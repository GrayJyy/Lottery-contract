# Provable Random Raffle Contracts

## About

This code is to create a provable random smart contract lottery.

## Description

1. Users can enter by paying for a ticket,and the ticket fee are going to the winner during the draw.
2. After X period of time,the lottery will automatically draw a winner,and this will be done programmatically.
3. Using Chainlink VRF & Chainlink Automation.# Lottery-contract

## For development
> CEI (Checks -> Effects -> Interactions)

1. require(...)...
2. Change our own contract state (include events emitting)
3. Interact with other contracts
It's very important for every developer~

> About Tests

1. deploy scripts
2. tests work on a local chain
3. tests work on a forked testnet
4.tests work on a forked mainnet
# Lottery-contract
1. Participants enter the lottery.
2. Later, when certain conditions are satisfied, the Chainlink will invoke the `performUpkeep` function, which in turn calls the `checkUpkeep` to verify the conditions.
3. Once the conditions are confirmed, the `pickWinner` function, which contains our custom logic, is executed. This function requests a random number by calling Chainlink VRF's `requestRandomWords` and waits for the transaction to be confirmed. After confirmation, Chainlink VRF generates a random number and uses the callback function `fulfillRandomWords` to deliver the random number, which we then use for further processing.
> tips: the `performUpkeep` and `checkUpkeep` is the AutomationCompatibleInterface's implement;the `requestRandomWords` and `fulfillRandomWords` is the VRFConsumerBaseV2's implement.