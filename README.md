## FundMe

**My first Solidity project**

## Scripts

### Deployment

**DeployFundMe.s.sol**

usage:

```
forge script script/DeployFundMe.s.sol:DeployFundMe
```

#### Necessary parameters:

```
--account <account_name>
```
or

```
--private-key <your_private_key>
```

#### Additional parameters:

in case of running script in foundry-zksync
```
--zksync
```
to run script not in fork, but in real blockchain:

```
--broadcast
```
to run script in a specific blockchain (may require real money):

```
--rpc-url <your_rpc_url>
```
you also have to pass
```
--rpc-url <anvil_rpc_url> --broadcast
```
to run the script in localy running anvil blockchain, not in simulation.

to verify contract on etherscan (in case of running on a real blockchain):
```
--verify --etherscan-api-key <ETHERSCAN_API_KEY> -vvvv
```


**Interactions.s.sol**

#### FundFundMe

Sends 0.1 ether to the contract

```
forge script script/Interactions.s.sol:FundFundMe (--account <your_account> --rpc-url <your_rpc_url>  --broadcast) 
```

#### WithdrawFundMe

Withdraws all the money from the contract's bank. 
Requires user to be the owner of the contract.

```
forge script script/Interactions.s.sol:WithdrawFundMe (--account <your_account> --rpc-url <your_rpc_url>  --broadcast) 
```


**HelperConfig.s.sol**

meant to be operated automaticaly


## Sending direct transactions from terminal

**Send money**

tx type: 2

triggering special receive() function

```
cast send <contract_address> --value <amt_in_wei> --account <your_account>
```

**Call view function**

(doesn't count as a transaction)

```
cast call <your_contract_address> "function(uint256)" 123 (--rpc-url <your_rpc_url>) 
```

## Testing
***Warning! Tests may not work properly in some networks. They're approved to run in BNB Chain and in Anvil. However, something goes wrong while testing in Sepolia.**


### General test

```
forge test (-vvvv --fork-url <your_rpc_url>)
```

### Tests' coverage

```
forge coverage
```

## Testing fail in Sepolia

**I assume that the problem is in the withdrawal. Running withdraw() it executes everything till it reaches the actual ETH sending and then calls fallback:**

```
├─ [13059] FundMe::withdraw()
    │   ├─ [0] console::log("tried withdraw from address %s", DefaultSender: [0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38]) [staticcall]
    │   │   └─ ← [Stop] 
    │   ├─ [0] console::log("fundMe owner again: %s", DefaultSender: [0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38]) [staticcall]
    │   │   └─ ← [Stop] 
    │   ├─ [0] console::log("s_bank: %s, actual balance: %s", 1000000000000000000 [1e18], 1101000000000000000 [1.101e18]) [staticcall]
    │   │   └─ ← [Stop] 
    │   ├─ [0] DefaultSender::fallback{value: 1000000000000000000}()
    │   │   └─ ← [Stop] 
    │   └─ ← [Stop] 
```

**Again. This problem wasn't encountered in other networks, so I haven't spent much time trying to solve it :D**