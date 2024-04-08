# Vyper Token Locking and Reward Distribution Contract

This is a Vyper smart contract that provides a token locking mechanism with reward distribution functionality. Users can lock their ERC20 tokens for a fixed period (currently set to 1 year) and receive veTokens in return. The contract then distributes rewards to users based on their veToken balances.

## Features

- Token locking with a 1-year lock period
- Minimum token lock amount of 10,000 tokens
- Maximum number of active users capped at 1,000
- 1% deposit fee for locking tokens
- Reward distribution based on veToken balances
- Emergency unlock function for the contract owner
- Contract upgrade functionality (use with caution)
- Snapshot functionality to retrieve veToken balances at a specific block number

## Usage

1. Deploy the contract with the necessary initialization parameters (owner address, ERC20 token address, and fee beneficiary address).
2. Users can lock their tokens by calling the `lock_tokens` function, providing the amount they want to lock.
3. The contract owner can update the reward rate using the `updateRewardRate` function.
4. The authorized distributors can call the `distribute_rewards` function to distribute the available rewards to the users based on their veToken balances.
5. Users can claim their locked tokens after the lock period ends by calling the `claimTokens` function.
6. The contract owner can perform an emergency unlock for a user's locked tokens if necessary, using the `emergencyUnlock` function.
7. The contract owner can upgrade the contract to a new version using the `upgradeContract` function (use with caution).

## Deployment and Configuration

1. Compile the Vyper contract using the Vyper compiler.
2. Deploy the contract to the desired blockchain network.
3. Configure the necessary parameters, such as the ERC20 token address, fee beneficiary address, and initial reward rate.

## Events

The contract emits the following events:

- `TokensLocked`: Logged when a user locks their tokens.
- `TokensClaimed`: Logged when a user claims their locked tokens.
- `RewardDistributed`: Logged when rewards are distributed to a user.
- `RewardsFunded`: Logged when rewards are added to the contract.
- `BalanceUpdated`: Logged when a user's balance is updated.
- `EmergencyUnlockTriggered`: Logged when the emergency unlock function is used.

## Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please create a new issue or submit a pull request.

## License

This project is licensed under the [MIT License](LICENSE).
