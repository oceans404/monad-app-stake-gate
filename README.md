# StakingGateFactory

A Solidity factory contract that allows anyone to create customized staking contracts with different requirements and names. Each staking contract gates access to content by requiring users to stake a specific amount of ETH.

## Deployed Contracts

### Factory Contract

StakingGateFactory: https://testnet.monadexplorer.com/address/0x7c809EA8370B2efD01b3f175Be3Aab970b66Ded3?tab=Contract

- **Address**: `0x7c809EA8370B2efD01b3f175Be3Aab970b66Ded3`
- **Network**: Monad Testnet
- **Purpose**: Creates new staking contracts with customizable parameters

### Example Staking Contract

StakingGate for "TestApp": https://testnet.monadexplorer.com/address/0x22C453f438085008A9B9dBf4b418F7Fd73DF4350?tab=Contract

- **Address**: `0x22c453f438085008a9b9dbf4b418f7fd73df4350`
- **Name**: TestApp
- **Required Stake**: 0.0069 ETH (6,900,000,000,000,000 wei)

## Features

Each staking contract created by the factory:

- Requires users to stake exactly the specified amount
- Allows users to withdraw their stake at any time
- Has the `isStaker(address)` function to check if an address has staked
- Tracks the total number of stakers
- Is owned by whoever created it through the factory

## How to Create Your Own Staking Contract

### Using Forge/Cast (Command Line)

```bash
cast send 0x7c809EA8370B2efD01b3f175Be3Aab970b66Ded3 "createStakingGate(uint256,string)" YOUR_STAKE_AMOUNT_IN_WEI "YOUR_APP_NAME" --account YOUR_ACCOUNT_NAME
```

Example (Creating a contract requiring 0.01 ETH):

```bash
cast send 0x7c809EA8370B2efD01b3f175Be3Aab970b66Ded3 "createStakingGate(uint256,string)" 10000000000000000 "MyNewApp" --account monad
```

### Using Web3 JS/Ethers

```javascript
const factory = new ethers.Contract(
  '0x7c809EA8370B2efD01b3f175Be3Aab970b66Ded3',
  factoryAbi,
  signer
);

const tx = await factory.createStakingGate(
  ethers.utils.parseEther('0.01'),
  'MyNewApp'
);

const receipt = await tx.wait();
console.log(
  'New contract created at:',
  receipt.events[0].args.stakingGateAddress
);
```

## How to Verify Your Staking Contract

After creating a staking contract, you can verify it on the Monad Testnet block explorer:

```bash
# First, extract the contract address from transaction logs
# Then, verify using Forge
forge verify-contract \
--rpc-url https://testnet-rpc2.monad.xyz/52227f026fa8fac9e2014c58fbf5643369b3bfc6 \
--verifier sourcify \
--verifier-url 'https://sourcify-api-monad.blockvision.org' \
--constructor-args $(cast abi-encode "constructor(uint256,string,address)" YOUR_STAKE_AMOUNT "YOUR_APP_NAME" YOUR_ADDRESS) \
YOUR_CONTRACT_ADDRESS \
src/StakingGateFactory.sol:StakingGate
```

Example:

```bash
forge verify-contract \
--rpc-url https://testnet-rpc2.monad.xyz/52227f026fa8fac9e2014c58fbf5643369b3bfc6 \
--verifier sourcify \
--verifier-url 'https://sourcify-api-monad.blockvision.org' \
--constructor-args $(cast abi-encode "constructor(uint256,string,address)" 10000000000000000 "MyNewApp" 0x70EC34970f76A318A66Eb0042D5E1EF795bE0825) \
0xYourNewContractAddress \
src/StakingGateFactory.sol:StakingGate
```

## Finding Your Created Contracts

To get all contracts you've created:

```bash
cast call 0x7c809EA8370B2efD01b3f175Be3Aab970b66Ded3 "getStakingGatesByCreator(address)(address[])" YOUR_ADDRESS
```

## Interacting with Staking Contracts

### To stake (exactly the required amount):

```bash
cast send YOUR_STAKING_CONTRACT_ADDRESS "stake()" --value YOUR_STAKE_AMOUNT_IN_WEI --account YOUR_ACCOUNT_NAME
```

### To check if an address is a staker:

```bash
cast call YOUR_STAKING_CONTRACT_ADDRESS "isStaker(address)(bool)" ADDRESS_TO_CHECK
```

### To withdraw your stake:

```bash
cast send YOUR_STAKING_CONTRACT_ADDRESS "withdraw()" --account YOUR_ACCOUNT_NAME
```

## Contract Information

To get information about a contract created by the factory:

```bash
cast call 0x7c809EA8370B2efD01b3f175Be3Aab970b66Ded3 "getContractInfo(address)(bool,uint256,string,address)" CONTRACT_ADDRESS
```

## License

MIT
