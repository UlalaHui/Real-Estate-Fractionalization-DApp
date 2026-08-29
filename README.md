# Real-Estate-Fractionalization-DApp
TARUMT Degree Blockchain Application Development Assignment

# PropertyFraction – Real Estate Fractionalization DApp

A decentralized application that allows property owners to fractionalize real estate into tradeable ERC-20 tokens. Investors can buy fractions, trade them on a secondary market, and claim rental/income dividends.

## Features

- **Property Tokenization** – Create an ERC-20 token representing fractions of a real estate property
- **Factory Pattern** – Deploy multiple independent property tokens via `PropertyFactory`
- **Primary Sale** – Buy fractions directly from the property owner
- **Secondary Market** – List and purchase fractions from other investors
- **Income Distribution** – Property owner deposits rental income; token holders claim proportional share
- **KYC Management** – Basic KYC approval system (owner-controlled + self-verify for testing)
- **Portfolio & History** – View holdings, transfer fractions, and track transactions
- **MetaMask Integration** – Connect wallet and interact with the blockchain

## Tech Stack

| Layer       | Technology                          |
|-------------|-------------------------------------|
| Smart Contracts | Solidity ^0.8.19, OpenZeppelin (ERC20, Ownable, ReentrancyGuard) |
| Frontend    | HTML, CSS, Vanilla JavaScript, Web3.js |
| Network     | Ganache (local) / Ethereum-compatible |
| Wallet      | MetaMask                            |

## Project Structure
DApp/
├── PropertyFactory.sol      # Factory that deploys PropertyToken contracts
├── PropertyToken.sol        # ERC-20 token with marketplace + income logic
├── abi/
│   ├── PropertyFactory.json
│   └── PropertyToken.json
└── index.html               # Frontend DApp

1. **Owner** creates a new property via the Factory (sets name, symbol, valuation, total supply, price per fraction, IPFS hash).
2. Full token supply is minted to the owner.
3. **Investors** buy fractions from the owner (primary market) or from other holders who listed tokens (secondary market).
4. Owner can deposit income; holders claim their proportional share.
5. Tokens can be transferred freely between addresses.

## Setup & Deployment

1. Install dependencies (OpenZeppelin contracts).
2. Start Ganache (Chain ID `1337`).
3. Deploy `PropertyFactory` (it will deploy `PropertyToken` instances).
4. Copy the Factory address into `index.html` → `FACTORY_ADDRESS`.
5. Open `index.html` in a browser with MetaMask connected to Ganache.
6. Switch MetaMask to the correct network if prompted.

## Limitations

This is an **academic/assignment project** and has several intentional or practical limitations:

- **Local network only** – Designed for Ganache. Not production-ready for mainnet or testnets without modifications.
- **No real IPFS** – Images/documents are stored in browser IndexedDB; the “IPFS hash” is a local identifier.
- **Simplified KYC** – KYC is owner-controlled and includes a `selfVerifyKYC()` function for testing. No real identity verification.
- **Income distribution model** – Share calculation is based on current balances and contract ETH balance. It does not use snapshots, so transfers after income is deposited can lead to unfair claims.
- **No access control for secondary market** – Anyone can list and buy (KYC is not enforced on purchases).
- **Gas & UX** – No gas estimation UI, limited error handling, and no loading states for all actions.
- **Hardcoded Factory address** – Must be updated manually after every redeployment.
- **No formal audits** – Contracts have not been audited and should not be used with real funds.
- **Frontend–contract coupling** – ABIs are partially embedded; function names must stay in sync.

## Modules (Team Contributions)

- **Daniel** – Property fractionalization & token issuance
- **Wong Shen Hui** – Market listing & distribution
- **Alia** – Transactions, trading & records

## License

MIT
