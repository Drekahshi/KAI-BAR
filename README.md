# KAI Chain
## DeFi-Powered Financial Infrastructure for Africa's Economic Revolution on Hedera

[![Hedera](https://img.shields.io/badge/Built%20on-Hedera-4A90E2?style=for-the-badge&logo=hedera)](https://hedera.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)
[![Status](https://img.shields.io/badge/Status-In%20Development-yellow?style=for-the-badge)](https://github.com/kaichainfi)

---
youtube video https://youtu.be/DxYEn1aagh0?si=5CGzLUigy74P4w1D
## 🌍 Mission

KAI Chain democratizes access to **BTC.HBAR investments** and transitions people from traditional Web2 banking to Web3 banking for prosperity. We're building a complete DeFi ecosystem on **Hedera Hashgraph** that enables African communities to earn **20–55% APY** while maintaining full asset custody.

**Core Innovation**: Leveraging Hedera's **3-6 second finality**, **deterministic consensus**, and **near-zero gas costs** to create wealth multiplication mechanisms where Bitcoin liquidity meets advanced DeFi strategies.

---

## 🎯 What We Solve

### The Problems
- 🔥 **Chronic Inflation**: African currencies lose 10–20% value annually
- 🚫 **Financial Exclusion**: 75% of Africans remain unbanked
- 📉 **Poor Returns**: Traditional savings offer 2–5% APY vs. 10–20% inflation
- ⏱️ **Slow Settlement**: Bank transfers take 2–8 weeks; loans require months
- 💸 **High Fees**: Banks charge 2–5% on transactions; gas costs $5–50 on other chains
- 🎲 **No Passive Income**: Savings accounts generate no meaningful returns

### The KAI Solution
- ✅ **Inflation Resistance**: BTC.HBAR liquidity provides Bitcoin's scarcity + HBAR's utility
- ✅ **Instant Access**: 3-6 second settlement for all transactions on Hedera
- ✅ **Superior Yields**: 18–55% APY through automated DeFi strategies
- ✅ **Minimal Costs**: <$0.00001 per transaction on Hedera vs. $5–50 elsewhere
- ✅ **Universal Access**: USSD support for feature phones; no internet required
- ✅ **MEV Protection**: Deterministic consensus eliminates front-running and slippage

---

## 🏗️ Architecture

### Core Products

#### 1. **YToken Multi-Strategy DeFi Vault**
- **Purpose**: Bitcoin exposure with automated yield optimization
- **Strategy**: 60% BTC.HBAR LP farming + 40% HBAR validator staking
- **Expected APY**: 22–38%
- **Features**: Auto-compounding, impermanent loss protection, flash loan arbitrage

#### 2. **YGOLD-H Bond Vault**
- **Purpose**: Diversified real-world asset exposure
- **Composition**: 40% BTC.HBAR LP + 30% Infrastructure Bonds + 20% Gold + 10% USDC
- **Expected APY**: 26–55%
- **Features**: Quarterly rebalancing, DAO governance, inflation hedge

#### 3. **KAI Trust Pools**
- **Purpose**: Intergenerational wealth building with programmable conditions
- **Types**: MMF (30–90 days), Growth (1–3 years), Legacy (5+ years)
- **Expected APY**: 18–55% depending on pool type
- **Features**: AI guardianship, ZK-proof verification, USSD accessibility

#### 4. **Insurance Pools**
- **Purpose**: 100% premium-covered protection via DeFi yields
- **Coverage**: Health, farming, SME, family security, education
- **Expected APY**: 20–32% on staked premiums
- **Features**: 3-6 second claim settlement, AI validation, community governance

#### 5. **YBOB-H Stablecoin**
- **Purpose**: Yield-bearing USD-pegged savings vehicle
- **Backing**: 150% collateralization (USDC + BTC.HBAR LP)
- **Expected APY**: 10–15%
- **Features**: Algorithmic stability, auto-rebalancing

#### 6. **GAMI Social DeFi**
- **Purpose**: Monetize digital engagement and content creation
- **Mechanism**: Verified social activity → token rewards → LP farming
- **Expected APY**: 12–22%
- **Features**: Creator staking, fan funding, engagement mining

---

## 🚀 Quick Start

### For Users

```bash
# 1. Download KAI App
iOS: https://apps.apple.com/kai-chain
Android: https://play.google.com/store/apps/kai-chain
USSD: Dial *384*5000# (no smartphone needed)

# 2. Create Wallet or Connect Existing
# Supports: HashPack, Blade, MetaMask (via Hashport)

# 3. Fund Your Account
# Deposit HBAR or BTC via Hashport bridge
Minimum: 1 HBAR (~$0.05)

# 4. Start Earning
# Choose your strategy:
- Conservative: YBOB-H stablecoin (10-15% APY)
- Balanced: YToken vault (22-38% APY)
- Aggressive: YGOLD-H bonds (26-55% APY)
```

### For Developers

```bash
# Clone the repository
git clone https://github.com/kaichainfi/kai-protocol.git
cd kai-protocol

# Install dependencies
npm install

# Set up environment
cp .env.example .env
# Add your Hedera testnet credentials

# Run tests
npm test

# Deploy to Hedera testnet
npm run deploy:testnet

# Deploy to mainnet (requires multi-sig approval)
npm run deploy:mainnet
```

---

## 📊 Key Metrics

| Metric | Traditional Banking | Competitors (AAVE, Curve) | **KAI on Hedera** |
|--------|---------------------|---------------------------|-------------------|
| Savings APY | 2–5% | 3–8% | **18–55%** |
| Loan Processing | 2–8 weeks | Minutes | **3-6 seconds** |
| Gas Costs | N/A | $5–50 per tx | **<$0.00001** |
| Settlement Finality | 2–3 days | 12–15 min | **3-6 seconds** |
| MEV Risk | No | Yes | **No (deterministic)** |
| Geographic Access | Local only | Global | **Global + USSD** |

---

## 🛠️ Technology Stack

### Blockchain
- **Primary**: Hedera Hashgraph (hashgraph consensus)
- **Bridge**: Hashport (for BTC.HBAR liquidity)
- **Secondary**: Ethereum, Polygon (via cross-chain bridges)

### Smart Contracts
- **Language**: Solidity (Hedera-compatible)
- **Tools**: Hardhat, Foundry
- **Testing**: Mocha, Chai, Waffle
- **Audits**: Certora, Trail of Bits, OpenZeppelin

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: PostgreSQL (off-chain indexing)
- **Oracles**: Chainlink, Hedera native oracles
- **Storage**: IPFS (encrypted documents)

### Frontend
- **Framework**: React + Next.js
- **Mobile**: React Native
- **USSD**: Custom gateway (Twilio integration)
- **Wallet Integration**: HashPack SDK, Blade Wallet

### AI/ML
- **Engine**: Python (TensorFlow, PyTorch)
- **Agents**: LangChain and Eliza Plugins with openconvai for agentic AI
- **Risk Scoring**: Custom ML models
- **Yield Optimization**: Reinforcement learning

### Privacy
- **ZK Proofs**: Circom (zk-SNARKs)
- **Encryption**: AES-256, RSA
- **Key Management**: Hardware Security Modules (HSM)

---

## 📚 Documentation

- [Whitepaper](./Docs/Whitepaper.md) - Complete technical specification
- [Trust System](./Docs/Trust.md) - Intergenerational wealth building
- [Insurance Pools](./Docs/Insurance.md) - Decentralized protection
- [DeFi Strategies](./Docs/Pools.md) - Yield optimization guide
- [API Reference](./docs/api.md) - Developer integration
- [Security Audits](./docs/audits/) - Third-party verification

---

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Process
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Standards
- Follow Solidity style guide
- 100% test coverage for smart contracts
- Documented with NatSpec comments
- Passes all security checks

---

## 🔐 Security

### Audits
- ✅ Certora formal verification (Q1 2026)
- ✅ Trail of Bits security audit (Q1 2026)
- ✅ OpenZeppelin code review (Q2 2026)

### Bug Bounty
- **Critical**: $50K–$100K
- **High**: $10K–$50K
- **Medium**: $2K–$10K
- **Low**: $100–$2K

Report vulnerabilities: security@kaichainfi.com

---

## 📱 Community

- **Website**: https://kaichainfi.com
- **Twitter**: [@KaiChainFi](https://twitter.com/KaiChainFi)
- **Discord**: https://discord.gg/kai-chain
- **Telegram**: https://t.me/kaichainfi
- **Medium**: https://medium.com/@kaichainfi

---

## 🗓️ Roadmap

### Phase 1: Foundation (Q1 2026)
- ✅ Smart contracts deployed on Hedera testnet
- ✅ YToken vault live
- ✅ HBAR staking integration
- 🎯 Target: 10,000 users, $5M TVL

### Phase 2: Products (Q2 2026)
- YGOLD-H bond vault launch
- KAI Trust infrastructure
- YBOB-H stablecoin
- 🎯 Target: 50,000 users, $25M TVL

### Phase 3: Integration (Q3 2026)
- GAMI social DeFi
- Insurance pools live
- SME lending platform
- 🎯 Target: 200,000 users, $100M TVL

### Phase 4: Scaling (Q4 2026)
- Cross-chain bridges
- USSD accessibility
- Regional expansion (East Africa)
- 🎯 Target: 1M users, $500M TVL

### Phase 5: Global (2027)
- Pan-African expansion
- Institutional partnerships
- Central bank coordination
- 🎯 Target: 5M users, $2B TVL

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## ⚠️ Disclaimer

KAI Chain is a decentralized protocol. Using DeFi products involves risk, including potential loss of principal. Past performance does not guarantee future results. Users are responsible for their own financial decisions. This is not financial advice.

Always do your own research (DYOR) and never invest more than you can afford to lose.

---

## 🌟 Why Hedera?

| Feature | Traditional L1s | **Hedera Hashgraph** |
|---------|----------------|---------------------|
| Throughput | 14–200 TPS | **10,000 TPS** |
| Finality | 12–15 min | **3–6 seconds** |
| Gas Costs | $5–50 | **~$0.00001** |
| MEV Protection | ❌ | **✅ Deterministic** |
| Sustainability | High energy | **Carbon-neutral** |
| Governance | Varied | **Google, IBM, Boeing** |

---

**Built with ❤️ for Africa on Hedera**

*Empowering the next billion users to build wealth through decentralized finance.*




# KAI Chain Setup Guide
## Complete Installation and Configuration Instructions

---

## 📋 Prerequisites

### System Requirements
- **Node.js**: v18.x or higher
- **npm** or **yarn**: Latest version
- **Git**: v2.x or higher
- **Docker**: v20.x or higher (optional, for local testing)
- **Hedera Account**: Testnet/Mainnet account with HBAR balance

### Required Accounts
- [Hedera Portal](https://portal.hedera.com) - Get testnet credentials
- [HashPack Wallet](https://www.hashpack.app/) - Recommended wallet
- [Hashport Bridge](https://hashport.network/) - For BTC bridging

---

## 🚀 Quick Setup (5 Minutes)

### 1. Clone Repository
```bash
git clone https://github.com/kaichainfi/kai-protocol.git
cd kai-protocol
```

### 2. Install Dependencies
```bash
# Using npm
npm install

# Or using yarn
yarn install
```

### 3. Configure Environment
```bash
# Copy example environment file
cp .env.example .env

# Edit .env with your credentials
nano .env  # or use your preferred editor
```

### 4. Required Environment Variables
```env
# Hedera Network Configuration
HEDERA_NETWORK=testnet  # or mainnet
HEDERA_ACCOUNT_ID=0.0.XXXXX
HEDERA_PRIVATE_KEY=302e020100300506032b657004220420...

# Contract Addresses (will be provided after deployment)
YTOKEN_CONTRACT_ADDRESS=
YGOLD_CONTRACT_ADDRESS=
YBOB_CONTRACT_ADDRESS=
TRUST_FACTORY_CONTRACT_ADDRESS=
INSURANCE_POOL_CONTRACT_ADDRESS=

# Oracle Configuration
CHAINLINK_NODE_URL=https://...
HEDERA_ORACLE_ADDRESS=0.0.XXXXX

# API Keys
HASHPORT_API_KEY=your_hashport_key
COINMARKETCAP_API_KEY=your_cmc_key  # for price feeds

# Database (PostgreSQL)
DATABASE_URL=postgresql://user:password@localhost:5432/kai_db

# IPFS Configuration
IPFS_API_URL=https://ipfs.infura.io:5001
IPFS_PROJECT_ID=your_project_id
IPFS_PROJECT_SECRET=your_secret

# AI/ML Services
OPENAI_API_KEY=sk-...  # for agentic AI
ML_MODEL_PATH=./models/risk_scorer.pkl

# Security
JWT_SECRET=your_jwt_secret_here
ENCRYPTION_KEY=your_32_byte_hex_key

# USSD Gateway (for mobile access)
TWILIO_ACCOUNT_SID=ACxxxxx
TWILIO_AUTH_TOKEN=your_token
USSD_PHONE_NUMBER=+254...
```

### 5. Initialize Database
```bash
# Run database migrations
npm run db:migrate

# Seed initial data (optional)
npm run db:seed
```

### 6. Run Tests
```bash
# Run all tests
npm test

# Run only smart contract tests
npm run test:contracts

# Run with coverage
npm run test:coverage
```

### 7. Deploy to Testnet
```bash
# Compile contracts
npm run compile

# Deploy to Hedera testnet
npm run deploy:testnet

# Verify deployment
npm run verify:testnet
```

---

## 🔧 Detailed Configuration

### Hedera Account Setup

#### Option 1: Create New Account
```bash
# Install Hedera SDK CLI
npm install -g @hashgraph/hedera-cli

# Create testnet account
hedera account create --network testnet

# Save the output:
# Account ID: 0.0.XXXXX
# Private Key: 302e020100...
# Public Key: 302a300506...
```

#### Option 2: Import Existing Account
If you have a HashPack wallet:
1. Open HashPack extension
2. Go to Settings → Security → Export Private Key
3. Copy private key and account ID to `.env`

### Smart Contract Deployment

#### Step-by-Step Deployment
```bash
# 1. Compile contracts
npm run compile

# Output will be in ./artifacts/contracts/

# 2. Deploy YToken Vault
npm run deploy:ytoken -- --network testnet

# 3. Deploy YGOLD Bonds
npm run deploy:ygold -- --network testnet

# 4. Deploy YBOB Stablecoin
npm run deploy:ybob -- --network testnet

# 5. Deploy Trust Factory
npm run deploy:trust -- --network testnet

# 6. Deploy Insurance Pools
npm run deploy:insurance -- --network testnet

# 7. Initialize all contracts
npm run initialize:all -- --network testnet
```

#### Verify Deployment
```bash
# Check deployed contracts on Hedera
npm run verify:contracts

# Test basic functionality
npm run test:integration
```

---

## 🐳 Docker Setup (Alternative)

### Using Docker Compose
```bash
# Build all services
docker-compose build

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Docker Compose Configuration
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://postgres:password@db:5432/kai_db
    depends_on:
      - db
      - redis
      
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: kai_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
      
  ipfs:
    image: ipfs/kubo:latest
    ports:
      - "5001:5001"
      - "8080:8080"
    volumes:
      - ipfs_data:/data/ipfs

volumes:
  postgres_data:
  ipfs_data:
```

---

## 🧪 Testing Environment

### Local Hedera Network
```bash
# Start local Hedera network (for development)
npm run hedera:local

# This starts:
# - Consensus nodes
# - Mirror node
# - JSON-RPC relay

# Local network endpoints:
# Consensus: localhost:50211
# Mirror API: localhost:5600
# JSON-RPC: localhost:7546
```

### Running Tests
```bash
# Unit tests
npm run test:unit

# Integration tests
npm run test:integration

# End-to-end tests
npm run test:e2e

# Specific test file
npm test -- tests/contracts/YToken.test.js

# Watch mode
npm test -- --watch

# Coverage report
npm run test:coverage
```

### Test Accounts
Pre-funded testnet accounts for testing:
```javascript
// In your test files
const TREASURY_ACCOUNT = '0.0.34567890';
const TREASURY_KEY = '302e020100...';

const USER_ACCOUNT_1 = '0.0.34567891';
const USER_KEY_1 = '302e020100...';

const USER_ACCOUNT_2 = '0.0.34567892';
const USER_KEY_2 = '302e020100...';
```

---

## 📱 Frontend Setup

### Web Application
```bash
cd frontend/web

# Install dependencies
npm install

# Configure environment
cp .env.example .env.local

# Required variables
# NEXT_PUBLIC_HEDERA_NETWORK=testnet
# NEXT_PUBLIC_API_URL=http://localhost:3000
# NEXT_PUBLIC_HASHPACK_APP_ID=your_app_id

# Start development server
npm run dev

# Build for production
npm run build

# Start production server
npm start
```

### Mobile Application
```bash
cd frontend/mobile

# Install dependencies
npm install

# iOS setup (macOS only)
cd ios && pod install && cd ..

# Android setup
# Ensure Android Studio is installed

# Start Metro bundler
npm start

# Run on iOS simulator
npm run ios

# Run on Android emulator
npm run android

# Build for production
npm run build:ios
npm run build:android
```

---

## 🔐 Security Setup

### Generate Encryption Keys
```bash
# Generate 32-byte encryption key
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Generate JWT secret
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

### Multi-Sig Wallet Setup
```bash
# Deploy multi-sig wallet contract
npm run deploy:multisig -- --signers 0.0.11111,0.0.22222,0.0.33333 --threshold 2

# Set as treasury owner
npm run set-treasury-owner -- --multisig 0.0.XXXXX
```

### Enable 2FA (Optional)
```bash
# Install authenticator
npm install speakeasy qrcode

# Generate 2FA secret
npm run generate:2fa
```

---

## 🌐 API Configuration

### Start API Server
```bash
# Development mode (with hot reload)
npm run dev:api

# Production mode
npm run start:api

# API available at: http://localhost:3000
```

### API Endpoints
```
GET    /api/v1/health              # Health check
GET    /api/v1/prices              # Token prices
GET    /api/v1/vaults              # All vaults
GET    /api/v1/vaults/:id          # Specific vault
POST   /api/v1/vaults/:id/deposit  # Deposit to vault
POST   /api/v1/vaults/:id/withdraw # Withdraw from vault
GET    /api/v1/trusts              # User's trusts
POST   /api/v1/trusts              # Create trust
GET    /api/v1/insurance           # Insurance pools
POST   /api/v1/claims              # Submit claim
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. "Insufficient HBAR balance"
```bash
# Get testnet HBAR from faucet
curl -X POST "https://testnet.mirrornode.hedera.com/api/v1/accounts/0.0.XXXXX/hbar" \
  -H "Content-Type: application/json" \
  -d '{"amount": 10000}'
```

#### 2. "Contract deployment failed"
```bash
# Check Hedera network status
npm run check:network

# Verify account permissions
npm run verify:account

# Increase gas limit in deployment script
# Edit: scripts/deploy.js
# Add: { gas: 5000000 }
```

#### 3. "Database connection failed"
```bash
# Check PostgreSQL is running
pg_isready

# Reset database
npm run db:reset

# Check connection string in .env
# Format: postgresql://user:password@host:port/database
```

#### 4. "IPFS upload timeout"
```bash
# Use local IPFS node
npm run ipfs:local

# Or switch to Pinata
IPFS_PROVIDER=pinata npm start
```

---

## 📊 Monitoring Setup

### Enable Logging
```javascript
// config/logger.js
import winston from 'winston';

export const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});
```

### Hedera Transaction Monitoring
```bash
# Install monitoring tools
npm install @hashgraph/sdk axios

# Start transaction monitor
npm run monitor:transactions

# View in browser
# http://localhost:4000/dashboard
```

---

## 🚢 Production Deployment

### Pre-Deployment Checklist
- [ ] All tests passing
- [ ] Security audit completed
- [ ] Smart contracts verified
- [ ] Environment variables set
- [ ] Database migrated
- [ ] Monitoring configured
- [ ] Backup strategy in place

### Deploy to Mainnet
```bash
# ⚠️ CAUTION: This deploys to mainnet with real HBAR

# 1. Switch to mainnet
export HEDERA_NETWORK=mainnet

# 2. Deploy contracts (requires multi-sig)
npm run deploy:mainnet

# 3. Verify deployment
npm run verify:mainnet

# 4. Initialize pools
npm run initialize:mainnet

# 5. Enable monitoring
npm run monitor:start
```

---

## 📞 Support

Need help? Contact us:
- **Email**: support@kaichainfi.com
- **Discord**: https://discord.gg/kai-chain
- **Telegram**: https://t.me/kaichainfi
- **Documentation**: https://docs.kaichainfi.com

---

**Setup complete! You're ready to build on KAI Chain. 🎉**
