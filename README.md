## Test for Overnight.fi

## Requirements

-   **OS**: Linux or WSL2
-   **Rust compiler**: Cargo.
-   **Foundry**: [instalation docs](https://book.getfoundry.sh/getting-started/installation)
-   **Alchemy key**: [Alchemy](https://www.alchemy.com/)


## Usage

### Build

```shell
$ forge build
```

### Test in mainnet fork

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
