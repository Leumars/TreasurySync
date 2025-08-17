# TreasurySync

**Synthetic Assets for US Treasury Securities on Stacks Blockchain**

TreasurySync creates synthetic exposure to traditional US Treasury assets through tokenized representation on the Stacks blockchain. Users can mint synthetic treasury tokens by depositing STX as collateral, enabling decentralized access to treasury-backed synthetic assets.

## Features

- **Collateralized Synthetic Tokens**: Mint synthetic treasury tokens backed by STX collateral
- **Multi-Asset Support**: Create and manage multiple treasury asset types with different characteristics
- **Dynamic Pricing**: Oracle-based price feeds for accurate asset valuation
- **Overcollateralization**: Minimum 150% collateral ratio ensures system stability
- **Flexible Asset Management**: Define maturity dates, yield rates, and asset metadata
- **User Portfolio Management**: Track collateral positions and synthetic token balances
- **Administrative Controls**: Contract governance and emergency controls

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity v2
- **Token Standard**: Fungible Token (SIP-010)
- **Minimum Collateral Ratio**: 150% (15,000 basis points)
- **Maximum Supply**: 1 billion synthetic treasury tokens
- **Price Oracle**: Configurable external price feed
- **Epoch**: 2.5

## Architecture

### Core Components

1. **Synthetic Treasury Token**: Fungible token representing synthetic exposure to US Treasury securities
2. **Collateral Management**: STX-based collateral system with overcollateralization requirements
3. **Asset Registry**: Multi-asset support for different treasury securities
4. **Price Oracle**: External price feed mechanism for accurate asset valuation
5. **Administrative Controls**: Contract governance and emergency functions

### Key Constants

```clarity
MIN_COLLATERAL_RATIO: 15000 (150%)
BASIS_POINTS: 10000
MAX_SUPPLY: 1000000000000000 (1 billion tokens)
```

## Installation

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet) - Clarity development environment
- [Node.js](https://nodejs.org/) v16 or higher
- [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd TreasurySync
```

2. Navigate to the contract directory:
```bash
cd TreasurySync_contract
```

3. Install dependencies:
```bash
npm install
```

4. Run tests:
```bash
npm test
```

## Usage Examples

### Basic Operations

#### 1. Create Treasury Asset (Admin Only)
```clarity
(contract-call? .TreasurySync create-treasury-asset 
  "US Treasury 10Y Bond" 
  "UST10Y" 
  u1735689600  ;; Maturity timestamp
  u250)        ;; 2.5% yield rate (250 basis points)
```

#### 2. Deposit Collateral
```clarity
(contract-call? .TreasurySync deposit-collateral u1500000000) ;; 1,500 STX
```

#### 3. Mint Synthetic Tokens
```clarity
(contract-call? .TreasurySync mint-synthetic-tokens u1000000) ;; 1 synthetic token
```

#### 4. Burn Tokens and Withdraw Collateral
```clarity
(contract-call? .TreasurySync burn-synthetic-tokens u500000) ;; 0.5 tokens
```

#### 5. Withdraw Excess Collateral
```clarity
(contract-call? .TreasurySync withdraw-collateral u100000000) ;; 100 STX
```

### Query Functions

#### Check User Collateral
```clarity
(contract-call? .TreasurySync get-user-collateral 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)
```

#### Get Collateral Ratio
```clarity
(contract-call? .TreasurySync get-user-collateral-ratio 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)
```

#### Check Maximum Mintable Tokens
```clarity
(contract-call? .TreasurySync get-max-mintable-tokens 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)
```

## Contract Functions Documentation

### Public Functions

#### Asset Management
- **`create-treasury-asset`**: Create new treasury asset type (Admin only)
  - Parameters: `name`, `symbol`, `maturity-date`, `yield-rate`
  - Returns: Asset ID

#### Collateral Operations
- **`deposit-collateral`**: Deposit STX as collateral
  - Parameters: `amount` (in microSTX)
  - Returns: Success boolean

- **`withdraw-collateral`**: Withdraw excess collateral
  - Parameters: `amount` (in microSTX)
  - Returns: Amount withdrawn

#### Token Operations
- **`mint-synthetic-tokens`**: Mint synthetic treasury tokens
  - Parameters: `amount` (in micro-tokens)
  - Returns: Tokens minted
  - Requires: Sufficient collateral ratio (≥150%)

- **`burn-synthetic-tokens`**: Burn tokens and release collateral
  - Parameters: `amount` (in micro-tokens)
  - Returns: Tokens burned

#### Oracle Functions
- **`update-treasury-price`**: Update asset price (Oracle only)
  - Parameters: `new-price` (in microSTX)
  - Returns: Updated price

#### Administrative Functions
- **`set-contract-admin`**: Transfer admin rights
- **`set-price-oracle`**: Set price oracle address
- **`toggle-minting`**: Enable/disable token minting

### Read-Only Functions

- **`get-user-collateral`**: Get user's collateral amount
- **`get-user-synthetic-balance`**: Get user's synthetic token balance
- **`get-treasury-asset`**: Get treasury asset information
- **`get-treasury-price`**: Get current treasury price
- **`get-total-collateral`**: Get total system collateral
- **`get-user-collateral-ratio`**: Calculate user's collateral ratio
- **`get-max-mintable-tokens`**: Calculate maximum mintable tokens for user
- **`get-contract-info`**: Get contract metadata and settings

### Error Codes

- **ERR_UNAUTHORIZED (401)**: Insufficient permissions
- **ERR_INSUFFICIENT_BALANCE (402)**: Insufficient collateral or token balance
- **ERR_INVALID_AMOUNT (403)**: Invalid amount specified
- **ERR_ASSET_NOT_FOUND (404)**: Treasury asset not found
- **ERR_ORACLE_PRICE_STALE (405)**: Price data is outdated
- **ERR_MINT_LIMIT_EXCEEDED (406)**: Maximum supply limit exceeded

## Deployment Guide

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy contract:
```clarity
::deploy_contracts
```

3. Test contract functions:
```clarity
(contract-call? .TreasurySync get-contract-info)
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`

2. Deploy using Clarinet:
```bash
clarinet deployments generate --testnet
clarinet deployments apply --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`

2. Deploy to mainnet:
```bash
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## Security Considerations

### Risk Factors

1. **Collateral Risk**: STX price volatility affects collateral value
2. **Oracle Risk**: Dependency on external price feeds
3. **Liquidation Risk**: Users must maintain minimum collateral ratio
4. **Smart Contract Risk**: Potential bugs or vulnerabilities in contract code

### Security Features

- **Overcollateralization**: 150% minimum collateral ratio provides safety buffer
- **Access Controls**: Administrative functions restricted to authorized addresses
- **Supply Limits**: Maximum token supply prevents infinite inflation
- **Emergency Controls**: Admin can disable minting during emergencies

### Best Practices

1. **Monitor Collateral Ratio**: Keep collateral well above minimum requirements
2. **Price Feed Validation**: Verify oracle price updates are recent and accurate
3. **Gradual Scaling**: Start with small amounts and gradually increase exposure
4. **Regular Audits**: Conduct periodic security reviews and audits

## Testing

Run the test suite:
```bash
cd TreasurySync_contract
npm test
```

Generate coverage report:
```bash
npm run test:report
```

Watch mode for development:
```bash
npm run test:watch
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the ISC License.

## Support

For questions, issues, or support:
- Create an issue in the repository
- Review the [Clarity documentation](https://docs.stacks.co/clarity)
- Check the [Stacks documentation](https://docs.stacks.co/)

---

**Disclaimer**: This is experimental software. Use at your own risk. Synthetic assets are complex financial instruments that may not be suitable for all users. Please conduct thorough research and consider consulting with financial professionals before using this system.