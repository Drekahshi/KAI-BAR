// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Events shared across contracts
interface KaiInsuranceEvents {
    event PoolCreated(bytes32 poolId, address creator, string poolType, uint256 timestamp);
    event StakeDeposited(bytes32 poolId, address staker, address token, uint256 amount, uint256 timestamp);
    event ClaimSubmitted(bytes32 claimId, bytes32 poolId, address claimant, uint256 amount, uint256 timestamp);
    event ClaimValidated(bytes32 claimId, bool approved, uint256 timestamp);
    event PayoutExecuted(bytes32 claimId, address recipient, uint256 amount, uint256 timestamp);
    event YieldHarvested(bytes32 poolId, uint256 harvestedAmount, uint256 timestamp);
    event GovernanceVote(bytes32 proposalId, address voter, bool support, uint256 timestamp);
}

// Base storage for insurance pools
contract KaiInsuranceStorage {
    struct Pool {
        string poolType; // e.g., "Comprehensive Good Samaritan Pool"
        address creator;
        address[] allowedAssets; // e.g., BTC.HBAR, YHT
        uint256 lockupPeriod; // in seconds, e.g., 1 year
        uint256 payoutCap; // max per claim
        uint256 totalStaked;
        uint256 totalYield;
        uint256 createdAt;
        mapping(address => uint256) stakerBalances; // Staker's total stake
        mapping(address => uint256) assetBalances; // Pool's asset balances
    }

    struct Claim {
        bytes32 poolId;
        address claimant;
        uint256 amount;
        bytes32 eventType; // e.g., keccak256("Health")
        bytes zkProof; // Placeholder for ZK proof
        bool validated;
        bool paid;
        uint256 submittedAt;
    }

    struct Proposal {
        string description;
        uint256 voteStart;
        uint256 voteEnd;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    mapping(bytes32 => Pool) public pools;
    mapping(bytes32 => Claim) public claims;
    mapping(bytes32 => Proposal) public proposals;
    address public vaultAddress; // Vault for assets
    address public governanceToken; // e.g., YHT for voting

    constructor(address _vaultAddress, address _governanceToken) {
        vaultAddress = _vaultAddress;
        governanceToken = _governanceToken;
    }
}

// PoolFactory: Creates insurance pools
contract PoolFactory is KaiInsuranceStorage, KaiInsuranceEvents, Ownable {
    constructor(address _vaultAddress, address _governanceToken) KaiInsuranceStorage(_vaultAddress, _governanceToken) {}

    // Create a new insurance pool
    function createPool(
        string calldata poolType,
        address[] calldata allowedAssets,
        uint256 lockupPeriod,
        uint256 payoutCap
    ) external onlyOwner returns (bytes32 poolId) {
        poolId = keccak256(abi.encodePacked(msg.sender, block.timestamp, poolType));

        Pool storage p = pools[poolId];
        p.poolType = poolType;
        p.creator = msg.sender;
        p.allowedAssets = allowedAssets;
        p.lockupPeriod = lockupPeriod;
        p.payoutCap = payoutCap;
        p.createdAt = block.timestamp;

        emit PoolCreated(poolId, msg.sender, poolType, block.timestamp);
    }

    // Stake into a pool
    function stake(bytes32 poolId, address token, uint256 amount) external {
        Pool storage p = pools[poolId];
        require(isAllowedAsset(poolId, token), "Invalid asset");
        require(block.timestamp < p.createdAt + p.lockupPeriod, "Pool locked"); // Simplified lock check

        IERC20(token).transferFrom(msg.sender, vaultAddress, amount);

        p.assetBalances[token] += amount;
        p.stakerBalances[msg.sender] += amount;
        p.totalStaked += amount;

        emit StakeDeposited(poolId, msg.sender, token, amount, block.timestamp);
    }

    // Helper to check allowed asset
    function isAllowedAsset(bytes32 poolId, address token) internal view returns (bool) {
        Pool storage p = pools[poolId];
        for (uint256 i = 0; i < p.allowedAssets.length; i++) {
            if (p.allowedAssets[i] == token) {
                return true;
            }
        }
        return false;
    }
}

// ClaimsExecutor: Handles claim submission and execution
contract ClaimsExecutor is KaiInsuranceStorage, KaiInsuranceEvents {
    constructor(address _vaultAddress, address _governanceToken) KaiInsuranceStorage(_vaultAddress, _governanceToken) {}

    // Submit a claim
    function submitClaim(
        bytes32 poolId,
        uint256 amount,
        bytes32 eventType,
        bytes calldata zkProof
    ) external returns (bytes32 claimId) {
        require(pools[poolId].stakerBalances[msg.sender] > 0, "Not a staker");
        require(amount <= pools[poolId].payoutCap, "Exceeds cap");

        claimId = keccak256(abi.encodePacked(msg.sender, block.timestamp, poolId));

        Claim storage c = claims[claimId];
        c.poolId = poolId;
        c.claimant = msg.sender;
        c.amount = amount;
        c.eventType = eventType;
        c.zkProof = zkProof;
        c.submittedAt = block.timestamp;

        emit ClaimSubmitted(claimId, poolId, msg.sender, amount, block.timestamp);
    }

    // Placeholder for ZK proof validation (integrate real verifier)
    function validateZKProof(bytes calldata zkProof) internal pure returns (bool) {
        // In production: Use zk-SNARK verifier
        return zkProof.length > 0; // Mock
    }

    // Validate and payout claim (AI-triggered)
    function validateAndPayout(bytes32 claimId) external onlyOwner { // Assume owner is AI oracle
        Claim storage c = claims[claimId];
        require(!c.validated, "Already validated");
        require(validateZKProof(c.zkProof), "Invalid proof");

        c.validated = true;
        emit ClaimValidated(claimId, true, block.timestamp);

        if (c.validated) {
            // Payout (simplified: from vault)
            Pool storage p = pools[c.poolId];
            address token = p.allowedAssets[0]; // Assume primary asset
            require(p.assetBalances[token] >= c.amount, "Insufficient funds");

            IERC20(token).transferFrom(vaultAddress, c.claimant, c.amount);
            p.assetBalances[token] -= c.amount;
            p.totalStaked -= c.amount; // Adjust total

            c.paid = true;
            emit PayoutExecuted(claimId, c.claimant, c.amount, block.timestamp);
        }
    }
}

// YieldOptimizer: Manages yield harvesting
contract YieldOptimizer is KaiInsuranceStorage, KaiInsuranceEvents {
    constructor(address _vaultAddress, address _governanceToken) KaiInsuranceStorage(_vaultAddress, _governanceToken) {}

    // Placeholder harvest yield
    function harvestYield(bytes32 poolId, address asset) internal returns (uint256) {
        // In production: Call DeFi protocols
        Pool storage p = pools[poolId];
        return p.assetBalances[asset] / 50; // Mock 2% yield
    }

    // Optimize yield for pool
    function optimizeYield(bytes32 poolId) external onlyOwner { // AI-triggered
        Pool storage p = pools[poolId];
        uint256 totalHarvested = 0;
        for (uint256 i = 0; i < p.allowedAssets.length; i++) {
            uint256 yield = harvestYield(poolId, p.allowedAssets[i]);
            totalHarvested += yield;
            p.assetBalances[p.allowedAssets[i]] += yield;
        }

        p.totalYield += totalHarvested;
        p.totalStaked += totalHarvested;

        emit YieldHarvested(poolId, totalHarvested, block.timestamp);
    }
}

// Governance: For DAO voting
contract Governance is KaiInsuranceStorage, KaiInsuranceEvents {
    uint256 public quorumPercentage = 50; // 50% quorum

    constructor(address _vaultAddress, address _governanceToken) KaiInsuranceStorage(_vaultAddress, _governanceToken) {}

    // Create proposal
    function createProposal(string calldata description, uint256 duration) external onlyOwner returns (bytes32 proposalId) {
        proposalId = keccak256(abi.encodePacked(msg.sender, block.timestamp, description));

        Proposal storage prop = proposals[proposalId];
        prop.description = description;
        prop.voteStart = block.timestamp;
        prop.voteEnd = block.timestamp + duration;

        // Emit event if needed
    }

    // Vote on proposal
    function vote(bytes32 proposalId, bool support) external {
        Proposal storage prop = proposals[proposalId];
        require(block.timestamp >= prop.voteStart && block.timestamp <= prop.voteEnd, "Voting not active");
        require(!prop.hasVoted[msg.sender], "Already voted");

        uint256 weight = IERC20(governanceToken).balanceOf(msg.sender);
        if (support) {
            prop.forVotes += weight;
        } else {
            prop.againstVotes += weight;
        }

        prop.hasVoted[msg.sender] = true;

        emit GovernanceVote(proposalId, msg.sender, support, block.timestamp);
    }

    // Execute proposal if passed
    function executeProposal(bytes32 proposalId) external onlyOwner {
        Proposal storage prop = proposals[proposalId];
        require(block.timestamp > prop.voteEnd, "Voting not ended");
        require(!prop.executed, "Already executed");

        uint256 totalVotes = prop.forVotes + prop.againstVotes;
        uint256 totalSupply = IERC20(governanceToken).totalSupply();
        require(totalVotes >= (totalSupply * quorumPercentage) / 100, "Quorum not met");
        require(prop.forVotes > prop.againstVotes, "Not approved");

        prop.executed = true;
        // In production: Execute action (e.g., update pool params)
    }
}