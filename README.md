# Provable Random Raffle Contracts

## About

This code is to create a provable random smart contract lottery.

## Description

1. Users can enter by paying for a ticket,and the ticket fee are going to the winner during the draw.
2. After X period of time,the lottery will automatically draw a winner,and this will be done programmatically.
3. Using Chainlink VRF & Chainlink Automation.# Lottery-contract

## For development
> CEI (Checks -> Effects -> Interactions)

1. Require(...)...
2. Change our own contract state (include events emitting)
3. Interact with other contracts
It's very important for every developer~

> About deploy the Raffle

To deploy the Raffle, there are several important steps that involve coding to ensure proper interaction with Chainlink:

Since the Raffle requires interaction with Chainlink, we need to handle this interaction through code.

On the Anvil environment, we lack the Link token contract necessary to fund the subscription. Therefore, we need to deploy the Link token contract on Anvil. However, on the Sepolia test network, the Link token is already deployed. The necessary code for this is included in HelperConfig.

With the Link token available on both the test network and Anvil, our next step is to create a subscription. We then need to add the Raffle contract as a consumer to this subscription. The foundry-devops tool can be used to retrieve the most recent contract. All these interactions should be automated through programming.

Finally, we need to integrate the interaction contract into the deployment process. This will enable us to deploy the Raffle on both Sepolia and Anvil. All the necessary code for this is already prepared in the Interactions module.


## About Tests

1. deploy scripts
2. tests work on a local chain
3. tests work on a forked testnet
4. tests work on a forked mainnet
### Why test failed?
>`VRFCoordinatorV2Mock::addConsumer` got an error which called `MustBeSubOwner(address)`

Verify that all contract deployments are enclosed within vm.startBroadcast and vm.stopBroadcast. This is crucial because the caller of addConsumer must be the same as the caller of createSubscription. This setup simulates the scenario where you connect your wallet to the Chainlink website to create a subscription, and subsequently, you must add the consumer using the same connection. This process mirrors real-world operations where consistency in authorization is key.

> `testPerformUpkeep_ShouldReverts_WhenUpkeepNotNeeded` already have balance that make this test failed

Just empty your broadcast files and deploy your Raffle again.And make sure you already set deploy key.

> Find a custom Error which is not defined in your contact...

make sure your VRF config is right. eg:the `REQUEST_CONFIRMATIONS`'s
 minimum is 3,and the gas limit's maximum is 2,500,000...

### test scripts
`forge test` means run all the test
`forge test --mt functionName -vvvvv` means run the certain function test and get more detail
`forge coverage` means check the test coverage
`forge coverage --report debug > coverage.txt` means get the test report

## About config
>How to install the packages?

`forge install repos --no-commit`

>how to relocate the imports which are start with `@` ?
```solidity
// the imports be like
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
```
```shell
remappings = ['@chainlink/contracts=lib/chainlink-brownie-contracts/contracts']
```


# Lottery-contract
1. Participants enter the lottery.
2. Later, when certain conditions are satisfied, the Chainlink will invoke the `performUpkeep` function, which in turn calls the `checkUpkeep` to verify the conditions.
3. Once the conditions are confirmed, the `pickWinner` function, which contains our custom logic, is executed. This function requests a random number by calling Chainlink VRF's `requestRandomWords` and waits for the transaction to be confirmed. After confirmation, Chainlink VRF generates a random number and uses the callback function `fulfillRandomWords` to deliver the random number, which we then use for further processing.
> tips: the `performUpkeep` and `checkUpkeep` is the AutomationCompatibleInterface's implement;the `requestRandomWords` and `fulfillRandomWords` is the VRFConsumerBaseV2's implement.

