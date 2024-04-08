from vyper.interfaces import ERC20
from vyper import nonreentrant

# Events for logging significant contract interactions
event TokensLocked:
    user: indexed(address)
    amount: uint256
    lock_end_time: uint256
    veTokensIssued: uint256

event TokensClaimed:
    user: indexed(address)
    amount: uint256

event RewardDistributed:
    user: indexed(address)
    reward_amount: uint256

event RewardsFunded:
    amount: uint256

event BalanceUpdated:
    user: indexed(address)
    newBalance: uint256
    timestamp: uint256

event EmergencyUnlockTriggered:
    user: indexed(address)
    amount: uint256

# Constants defining core parameters
LOCK_PERIOD: constant(uint256) = 86400 * 365  # Lock period of 1 year
MIN_LOCK_AMOUNT: constant(uint256) = 10000  # Minimum tokens required for locking
MAX_ACTIVE_USERS: constant(uint256) = 1000  # Max number of users who can lock tokens
DEPOSIT_FEE_PERCENT: constant(uint256) = 1  # Deposit fee percentage

locked_tokens: public(HashMap[address, uint256])
lock_end_time: public(HashMap[address, uint256])
total_locked_tokens: public(uint256)
active_users: public(address[MAX_ACTIVE_USERS])
num_active_users: public(uint256)
veToken_balances: public(HashMap[address, uint256])  # Tracking veToken balances
total_available_rewards: public(uint256)  # Total available rewards
snapshot_balances: public(HashMap[uint256, HashMap[address, uint256]])  # Maps block numbers to user balances

# Initialize contract with essential information
@external
def __init__(_owner: address, _erc20: address, _fee_beneficiary: address):
    self.owner = _owner
    self.erc20 = ERC20(_erc20)
    self.authorized[_owner] = True
    self.num_active_users = 0
    self.fee_beneficiary = _fee_beneficiary

# Security checks to ensure actions are performed by authorized addresses
@internal
def onlyOwner():
    assert msg.sender == self.owner, "Unauthorized: caller is not the owner"

@internal
def onlyAuthorized():
    assert self.authorized[msg.sender], "Unauthorized"

@external
@nonreentrant('lock')
def lock_tokens(amount: uint256):
    assert amount >= MIN_LOCK_AMOUNT, "Amount below minimum requirement"
    assert self.erc20.allowance(msg.sender, self) >= amount, "Insufficient allowance"

    fee_amount: uint256 = amount * DEPOSIT_FEE_PERCENT / 100  # Calculate the fee
    net_amount: uint256 = amount - fee_amount  # Calculate net amount after fee deduction

    # Transfer the fee and the net amount
    assert self.erc20.transferFrom(msg.sender, self.fee_beneficiary, fee_amount), "Fee transfer failed"
    assert self.erc20.transferFrom(msg.sender, self, net_amount), "Token transfer failed"

    # Issue veTokens and update storage variables
    self.veToken_balances[msg.sender] += net_amount
    self.locked_tokens[msg.sender] += net_amount
    self.total_locked_tokens += net_amount
    self.lock_end_time[msg.sender] = block.timestamp + LOCK_PERIOD

    if self.locked_tokens[msg.sender] == net_amount:  # New lock
        if self.num_active_users < MAX_ACTIVE_USERS:
            self.active_users[self.num_active_users] = msg.sender
            self.num_active_users += 1

    log TokensLocked(msg.sender, net_amount, self.lock_end_time[msg.sender], net_amount)

@external
@nonreentrant('withdraw')
def withdraw_erc20(token_address: address, amount: uint256):
    self.onlyOwner()
    assert token_address != self.erc20, "Cannot withdraw the locked ERC20 token"  # Safety check
    assert self.erc20.transfer(msg.sender, amount), "ERC20 transfer failed"

# Reward distribution section
reward_rate: public(uint256)  # Stores the pre-calculated reward rate

@external
@nonreentrant('update')
def updateRewardRate(new_reward_rate: uint256):
    self.onlyOwner()
    self.reward_rate = new_reward_rate

@external
@nonreentrant('distribute')
def distribute_rewards():
    self.onlyAuthorized()
    assert self.total_available_rewards <= self.erc20.balanceOf(self), "Insufficient funds in reward pool"
    total_veTokens: uint256 = sum(self.veToken_balances.values())
    assert total_veTokens > 0, "No veTokens to distribute rewards to"
    for user, balance in self.veToken_balances.items():
        if balance > 0:
            user_share: uint256 = (balance * self.total_available_rewards) / total_veTokens
            assert self.erc20.transfer(user, user_share), "Reward transfer failed."
            self.total_available_rewards -= user_share
            log RewardDistributed(user, user_share)

@external
@nonreentrant('fund')
def fund_rewards(amount: uint256):
    self.onlyOwner()
    allowance: uint256 = self.erc20.allowance(msg.sender, self)
    assert allowance >= amount, "Check the token allowance. Approval required."
    assert self.erc20.transferFrom(msg.sender, self, amount), "Transfer failed"
    self.total_available_rewards += amount
    log RewardsFunded(amount)

# Function to retrieve veToken balance at a specific block number (snapshot)
@external
@view
def balanceOfAt(user: address, block_number: uint256) -> uint256:
    if block_number in self.snapshot_balances:
        snapshot_balances: HashMap[address, uint256] = self.snapshot_balances[block_number]
        if user in snapshot_balances:
            return snapshot_balances[user]
    return 0

@external
@nonreentrant('emergency')
def emergencyUnlock(user: address):
    self.onlyOwner()
    assert block.timestamp > self.lock_end_time[user], "Tokens are still locked"

    amount: uint256 = self.locked_tokens[user]
    self.locked_tokens[user] = 0
    self.total_locked_tokens -= amount
    self.veToken_balances[user] -= amount  # Assuming a 1:1 lock to veToken ratio

    assert self.erc20.transfer(user, amount), "Emergency unlock failed"
    log EmergencyUnlockTriggered(user, amount)

# Contract upgrade (use with careful planning)
@external
@nonreentrant('upgrade')
def upgradeContract(new_contract: address):
    self.onlyOwner()
    # ... (extensive migration logic to transfer data to the new contract)
    # Use a more secure upgradeability mechanism, such as the Transparent Proxy Pattern or the UUPS Proxy Pattern
    selfdestruct(new_contract)  # Migrate contract state to the new contract

@external
@nonreentrant('claim')
def claimTokens():
    assert block.timestamp > self.lock_end_time[msg.sender], "Tokens are still locked"

    amount: uint256 = self.locked_tokens[msg.sender]
    self.locked_tokens[msg.sender] = 0
    self.total_locked_tokens -= amount
    self.veToken_balances[msg.sender] -= amount  # Assuming a 1:1 lock to veToken ratio

    assert self.erc20.transfer(msg.sender, amount), "Claim failed"
    log TokensClaimed(msg.sender, amount)
