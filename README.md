# **Token Locker Contract**

This Vyper contract allows users to lock ERC20 tokens for a fixed period, earning veTokens as a representation of their locked amount. It includes features such as minimum lock amounts, reward distribution, and emergency unlocking, designed with security measures like reentrancy protection.

## **Features**

Token Locking: Users can lock a minimum amount of tokens to participate in the contract's ecosystem, receiving veTokens proportional to the locked amount.
Reward Distribution: A mechanism to distribute rewards to token holders based on pre-defined rates and their share of the total locked tokens.
Emergency Unlock: An option for the contract owner to unlock tokens in case of emergency, ensuring user funds are accessible when needed.
Upgradeability: Functionality to migrate the contract to a new version, allowing for future improvements and enhancements.

## **Usage**

### **Locking Tokens**

To lock tokens, users must approve the contract to transfer the desired amount of ERC20 tokens on their behalf. Once approved, tokens can be locked by calling:
```lock_tokens(amount: uint256)```
amount: The amount of ERC20 tokens to lock.

### *Claiming Tokens*

Locked tokens can be claimed after the lock period ends by calling:
```claimTokens()```
This function releases the locked tokens back to the user's wallet.

### *Distributing Rewards*

The contract owner or authorized addresses can distribute rewards to locked token holders based on the set reward rate:

```distribute_rewards()```

### **Emergency Unlock**

In case of emergency, the contract owner can unlock a user's tokens before the lock period expires:
```emergencyUnlock(user: address)```
user: The address of the user whose tokens are to be unlocked.

### **Configuration**

Initial Setup
Upon deployment, the contract must be initialized with the owner's address, the ERC20 token address, and the fee beneficiary address:
```__init__(_owner: address, _erc20: address, _fee_beneficiary: address)```

### **Access Control**

The contract owner can authorize other addresses to perform restricted actions:
```setAuthorized(_addr: address, _status: bool)```
_addr: Address to modify authorization for.
_status: True to authorize, false to revoke authorization.

Remember to replace snapshot_balances with the actual name of your storage variable that stores historical veToken balances. You might also need to adjust the code further based on your specific contract structure and storage variable placement.
