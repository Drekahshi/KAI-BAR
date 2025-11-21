// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@hashgraph/smart-contracts/contracts/hts-precompile/HederaTokenService.sol";

/**
 * @title GAMI Social DeFi Token
 * @notice Rewards for social engagement, content creation, and community participation
 * @dev Integrates with SocialFi protocol for engagement verification on Hedera
 */
contract GAMIToken is HederaTokenService {
    
    address public tokenAddress;
    address public treasury;
    address public socialFiController;
    address public creatorStudio;
    
    uint256 public constant MAX_SUPPLY = 10_000_000_000 * 10**8; // 10 Billion
    uint256 public totalMinted;
    
    // Emission schedule (halving every 4 years)
    uint256 public currentYearEmission;
    uint256 public emissionStartTime;
    uint256 public lastHalvingTime;
    uint256 public constant HALVING_PERIOD = 4 * 365 days;
    
    // Engagement types and rewards
    enum EngagementType {
        LIKE,           // 0.1 GAMI
        COMMENT,        // 0.5 GAMI
        SHARE,          // 2 GAMI
        WATCH_15MIN,    // 2-3 GAMI
        READ_5MIN,      // 1 GAMI
        FITNESS,        // 5 GAMI
        CREATE_CONTENT, // 10-100 GAMI
        REFERRAL        // 5% of referee earnings
    }
    
    mapping(EngagementType => uint256) public baseRewards;
    
    // User engagement tracking
    mapping(address => uint256) public totalEngagements;
    mapping(address => uint256) public engagementStreak;
    mapping(address => uint256) public lastEngagementTime;
    mapping(address => uint256) public creatorEarnings;
    
    // Creator economy
    mapping(address => bool) public isCreator;
    mapping(address => uint256) public creatorStakes;
    mapping(address => address[]) public creatorSupporters;
    
    // Liquidity mining
    mapping(address => uint256) public lpStaked;
    uint256 public totalLPStaked;
    
    event TokenCreated(address indexed tokenAddress);
    event EngagementRewarded(
        address indexed user,
        EngagementType engagementType,
        uint256 amount,
        uint256 qualityScore
    );
    event CreatorRegistered(address indexed creator);
    event CreatorSupported(address indexed supporter, address indexed creator, uint256 amount);
    event LiquidityStaked(address indexed user, uint256 amount);
    event EmissionHalved(uint256 newEmission, uint256 timestamp);
    
    modifier onlySocialFiController() {
        require(msg.sender == socialFiController, "Only SocialFi controller");
        _;
    }
    
    modifier onlyCreatorStudio() {
        require(msg.sender == creatorStudio, "Only creator studio");
        _;
    }
    
    modifier onlyTreasury() {
        require(msg.sender == treasury, "Only treasury");
        _;
    }
    
    constructor(
        address _treasury,
        address _socialFiController,
        address _creatorStudio
    ) {
        treasury = _treasury;
        socialFiController = _socialFiController;
        creatorStudio = _creatorStudio;
        
        emissionStartTime = block.timestamp;
        lastHalvingTime = block.timestamp;
        currentYearEmission = 2_000_000_000 * 1e8; // 2B first year
        
        // Set base rewards
        baseRewards[EngagementType.LIKE] = 10000000; // 0.1 GAMI
        baseRewards[EngagementType.COMMENT] = 50000000; // 0.5 GAMI
        baseRewards[EngagementType.SHARE] = 200000000; // 2 GAMI
        baseRewards[EngagementType.WATCH_15MIN] = 200000000; // 2 GAMI base
        baseRewards[EngagementType.READ_5MIN] = 100000000; // 1 GAMI
        baseRewards[EngagementType.FITNESS] = 500000000; // 5 GAMI
        baseRewards[EngagementType.CREATE_CONTENT] = 1000000000; // 10 GAMI base
    }
    
    function createToken() external onlyTreasury returns (address) {
        IHederaTokenService.HederaToken memory token;
        
        token.name = "GAMI Social DeFi Token";
        token.symbol = "GAMI";
        token.treasury = treasury;
        token.memo = "Monetize Attention: Earn from Social Engagement";
        token.tokenSupplyType = true; // FINITE
        token.maxSupply = MAX_SUPPLY;
        token.freezeDefault = false;
        
        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](3);
        
        keys[0] = IHederaTokenService.TokenKey(1, 2, abi.encodePacked(treasury));
        keys[1] = IHederaTokenService.TokenKey(4, 2, abi.encodePacked(address(this)));
        keys[2] = IHederaTokenService.TokenKey(3, 2, abi.encodePacked(treasury));
        
        token.tokenKeys = keys;
        
        (int256 responseCode, address createdToken) = HederaTokenService.createFungibleToken(
            token,
            MAX_SUPPLY,
            8
        );
        
        require(responseCode == HederaResponseCodes.SUCCESS, "Token creation failed");
        
        tokenAddress = createdToken;
        
        emit TokenCreated(tokenAddress);
        
        return tokenAddress;
    }
    
    /**
     * @notice Reward user for verified engagement
     * @param user Address being rewarded
     * @param engagementType Type of engagement
     * @param qualityScore Quality score from AI (0-100)
     * @param creator Optional creator address (if engagement benefits creator)
     */
    function rewardEngagement(
        address user,
        EngagementType engagementType,
        uint256 qualityScore,
        address creator
    ) external onlySocialFiController returns (uint256) {
        require(qualityScore <= 100, "Invalid quality score");
        
        // Calculate base reward
        uint256 baseReward = baseRewards[engagementType];
        
        // Apply quality multiplier (quality score as percentage)
        uint256 qualityBonus = (baseReward * qualityScore) / 100;
        uint256 totalReward = baseReward + qualityBonus;
        
        // Apply streak multiplier
        uint256 streakBonus = _calculateStreakBonus(user);
        totalReward = (totalReward * (10000 + streakBonus)) / 10000;
        
        // Check emission limits
        require(totalMinted + totalReward <= MAX_SUPPLY, "Exceeds max supply");
        _checkAndHalveEmission();
        
        // Mint tokens
        int256 responseCode = HederaTokenService.mintToken(
            tokenAddress,
            int64(uint64(totalReward)),
            new bytes[](0)
        );
        
        require(responseCode == HederaResponseCodes.SUCCESS, "Minting failed");
        
        // Distribution: 60% user, 30% creator (if applicable), 10% protocol
        uint256 userShare = (totalReward * 6000) / 10000; // 60%
        uint256 creatorShare = creator != address(0) ? (totalReward * 3000) / 10000 : 0; // 30%
        uint256 protocolShare = totalReward - userShare - creatorShare; // 10% + unclaimed creator share
        
        // Transfer to user
        responseCode = HederaTokenService.transferToken(
            tokenAddress,
            address(this),
            user,
            int64(uint64(userShare))
        );
        require(responseCode == HederaResponseCodes.SUCCESS, "User transfer failed");
        
        // Transfer to creator if applicable
        if (creator != address(0) && creatorShare > 0) {
            responseCode = HederaTokenService.transferToken(
                tokenAddress,
                address(this),
                creator,
                int64(uint64(creatorShare))
            );
            require(responseCode == HederaResponseCodes.SUCCESS, "Creator transfer failed");
            
            creatorEarnings[creator] += creatorShare;
        }
        
        // Protocol treasury
        responseCode = HederaTokenService.transferToken(
            tokenAddress,
            address(this),
            treasury,
            int64(uint64(protocolShare))
        );
        require(responseCode == HederaResponseCodes.SUCCESS, "Protocol transfer failed");
        
        totalMinted += totalReward;
        totalEngagements[user]++;
        
        // Update streak
        if (block.timestamp - lastEngagementTime[user] <= 1 days) {
            engagementStreak[user]++;
        } else if (block.timestamp - lastEngagementTime[user] > 7 days) {
            engagementStreak[user] = 1; // Reset streak
        }
        
        lastEngagementTime[user] = block.timestamp;
        
        emit EngagementRewarded(user, engagementType, totalReward, qualityScore);
        
        return totalReward;
    }
    
    /**
     * @notice Register as content creator
     */
    function registerCreator() external returns (bool) {
        require(!isCreator[msg.sender], "Already registered");
        
        isCreator[msg.sender] = true;
        
        emit CreatorRegistered(msg.sender);
        
        return true;
    }
    
    /**
     * @notice Stake GAMI to support a creator
     * @param creator Creator address to support
     * @param amount Amount of GAMI to stake
     */
    function supportCreator(
        address creator,
        uint256 amount
    ) external returns (bool) {
        require(isCreator[creator], "Not a registered creator");
        require(amount > 0, "Invalid amount");
        
        // Transfer GAMI to staking contract
        int256 responseCode = HederaTokenService.transferToken(
            tokenAddress,
            msg.sender,
            address(this),
            int64(uint64(amount))
        );
        
        require(responseCode == HederaResponseCodes.SUCCESS, "Staking failed");
        
        creatorStakes[creator] += amount;
        creatorSupporters[creator].push(msg.sender);
        
        emit CreatorSupported(msg.sender, creator, amount);
        
        return true;
    }
    
    /**
     * @notice Stake GAMI in liquidity pools for enhanced rewards
     * @param amount Amount to stake
     */
    function stakeLP(uint256 amount) external returns (bool) {
        require(amount > 0, "Invalid amount");
        
        int256 responseCode = HederaTokenService.transferToken(
            tokenAddress,
            msg.sender,
            address(this),
            int64(uint64(amount))
        );
        
        require(responseCode == HederaResponseCodes.SUCCESS, "Staking failed");
        
        lpStaked[msg.sender] += amount;
        totalLPStaked += amount;
        
        emit LiquidityStaked(msg.sender, amount);
        
        return true;
    }
    
    /**
     * @notice Calculate streak bonus multiplier
     * @return Bonus in basis points (e.g., 500 = 5% bonus)
     */
    function _calculateStreakBonus(address user) internal view returns (uint256) {
        uint256 streak = engagementStreak[user];
        
        if (streak >= 365) return 3000; // 30% for 1 year streak
        if (streak >= 90) return 2500;  // 25% for 90 days
        if (streak >= 30) return 2000;  // 20% for 30 days
        if (streak >= 14) return 1500;  // 15% for 14 days
        if (streak >= 7) return 1300;   // 13% for 7 days
        if (streak >= 3) return 1100;   // 11% for 3 days
        
        return 1000; // 10% base
    }
    
    /**
     * @notice Check and execute emission halving if period elapsed
     */
    function _checkAndHalveEmission() internal {
        if (block.timestamp >= lastHalvingTime + HALVING_PERIOD) {
            currentYearEmission = currentYearEmission / 2;
            lastHalvingTime = block.timestamp;
            
            emit EmissionHalved(currentYearEmission, block.timestamp);
        }
    }
    
    /**
     * @notice Get user engagement statistics
     */
    function getUserStats(address user) external view returns (
        uint256 balance,
        uint256 engagements,
        uint256 streak,
        uint256 streak
        uint256 streak,
        uint256 streakBonus,
        bool isContentCreator,
        uint256 totalEarnings
    ) {
        int64 bal = HederaTokenService.balanceOf(tokenAddress, user);
        balance = uint256(uint64(bal));
        engagements = totalEngagements[user];
        streak = engagementStreak[user];
        streakBonus = _calculateStreakBonus(user);
        isContentCreator = isCreator[user];
        totalEarnings = balance + creatorEarnings[user];
        
        return (balance, engagements, streak, streakBonus, isContentCreator, totalEarnings);
    }
    
    /**
     * @notice Get creator statistics
     */
    function getCreatorStats(address creator) external view returns (
        uint256 totalStaked,
        uint256 supporterCount,
        uint256 totalEarned,
        bool isActive
    ) {
        totalStaked = creatorStakes[creator];
        supporterCount = creatorSupporters[creator].length;
        totalEarned = creatorEarnings[creator];
        isActive = isCreator[creator];
        
        return (totalStaked, supporterCount, totalEarned, isActive);
    }
    
    /**
     * @notice Update base reward amounts (governance)
     */
    function updateBaseReward(
        EngagementType engagementType,
        uint256 newReward
    ) external onlyTreasury {
        baseRewards[engagementType] = newReward;
    }
    
    /**
     * @notice Batch reward multiple users (gas optimization)
     */
    function batchRewardEngagement(
        address[] calldata users,
        EngagementType[] calldata engagementTypes,
        uint256[] calldata qualityScores,
        address[] calldata creators
    ) external onlySocialFiController returns (uint256 totalRewarded) {
        require(
            users.length == engagementTypes.length &&
            users.length == qualityScores.length &&
            users.length == creators.length,
            "Array length mismatch"
        );
        
        for (uint256 i = 0; i < users.length; i++) {
            uint256 reward = this.rewardEngagement(
                users[i],
                engagementTypes[i],
                qualityScores[i],
                creators[i]
            );
            totalRewarded += reward;
        }
        
        return totalRewarded;
    }
}