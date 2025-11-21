// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@hashgraph/smart-contracts/contracts/hts-precompile/HederaTokenService.sol";

/**
 * @title KAI CENTS-H Gas & Utility Token
 * @notice HBAR-pegged utility token for gas payments, micro-transactions, and predictions
 * @dev Maintains soft 1:1 peg with HBAR through reserve-backed mechanisms
 */
contract KAICentsToken is HederaTokenService {
    
    address public tokenAddress;
    address public treasury;
    address public utilityController;
    address public predictionEngine;
    
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**8; // 1 Billion
    uint256 public totalMinted;
    
    // Peg mechanism
    uint256 public constant TARGET_PEG = 1_00000000; // 1 HBAR (8 decimals)
    uint256 public currentPeg;
    uint256 public reserveHBAR; // HBAR backing reserves
    
    // Usage tracking
    mapping(address => uint256) public gasUsage;
    mapping(address => uint256) public predictionActivity;
    mapping(address => uint256) public lastDiscountClaim;
    
    // Fee discounts
    uint256 public constant MAX_DISCOUNT = 2500; // 25% max discount
    
    // Burn mechanism
    uint256 public totalBurned;
    uint256 public weeklyBurnRate; // Basis points of gas fees burned
    
    event TokenCreated(address indexed tokenAddress);
    event GasPayment(address indexed user, uint256 amount, uint256 hbarEquivalent);
    event PredictionPlaced(address indexed user, uint256 amount, bytes32 predictionId);
    event DiscountApplied(address indexed user, uint256 discountPercent);
    event TokensBurned(uint256 amount, uint256 totalBurned);
    event PegAdjusted(uint256 oldPeg, uint256 newPeg);
    event ReservesUpdated(uint256 newReserve);
    
    modifier onlyUtilityController() {
        require(msg.sender == utilityController, "Only utility controller");
        _;
    }
    
    modifier onlyPredictionEngine() {
        require(msg.sender == predictionEngine, "Only prediction engine");
        _;
    }
    
    modifier onlyTreasury() {
        require(msg.sender == treasury, "Only treasury");
        _;
    }
    
    constructor(
        address _treasury,
        address _utilityController,
        address _predictionEngine
    ) {
        treasury = _treasury;
        utilityController = _utilityController;
        predictionEngine = _predictionEngine;
        currentPeg = TARGET_PEG;
        weeklyBurnRate = 100; // 1% weekly burn
    }
    
    function createToken() external onlyTreasury returns (address) {
        IHederaTokenService.HederaToken memory token;
        
        token.name = "KAI CENTS-H Utility Token";
        token.symbol = "CENTS-H";
        token.treasury = treasury;
        token.memo = "HBAR-pegged utility: Gas + Predictions + Discounts";
        token.tokenSupplyType = true; // FINITE
        token.maxSupply = MAX_SUPPLY;
        token.freezeDefault = false;
        
        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](4);
        
        keys[0] = IHederaTokenService.TokenKey(1, 2, abi.encodePacked(treasury));
        keys[1] = IHederaTokenService.TokenKey(4, 2, abi.encodePacked(address(this)));
        keys[2] = IHederaTokenService.TokenKey(3, 2, abi.encodePacked(treasury));
        keys[3] = IHederaTokenService.TokenKey(6, 2, abi.encodePacked(utilityController));
        
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
     * @notice Mint KAI CENTS-H tokens
     * @param recipient Address receiving tokens
     * @param amount Amount to mint
     */
    function mint(
        address recipient,
        uint256 amount
    ) external onlyUtilityController returns (bool) {
        require(totalMinted + amount <= MAX_SUPPLY, "Exceeds max supply");
        
        int256 responseCode = HederaTokenService.mintToken(
            tokenAddress,
            int64(uint64(amount)),
            new bytes[](0)
        );
        
        require(responseCode == HederaResponseCodes.SUCCESS, "Minting failed");
        
        responseCode = HederaTokenService.transferToken(
            tokenAddress,
            address(this),
            recipient,
            int64(uint64(amount))
        );
        
        require(responseCode == HederaResponseCodes.SUCCESS, "Transfer failed");
        
        totalMinted += amount;
        
        return true;
    }
    
    /**
     * @notice Pay gas fees using KAI CENTS-H
     * @param user Address paying gas
     * @param amount Amount of CENTS-H to use for gas
     * @param operationType Type of operation (for tracking)
     */
    function payGas(
        address user,
        uint256 amount,
        uint8 operationType
    ) external onlyUtilityController returns (bool) {
        require(amount > 0, "Invalid amount");
        
        // Calculate discount based on user's staking/activity
        uint256 discount = calculateDiscount(user);
        uint256 discountedAmount = (amount * (10000 - discount)) / 10000;
        
        // Transfer tokens for gas payment
        int256 responseCode = HederaTokenService.transferToken(
            tokenAddress,
            user,
            address(this),
            int64(uint64(discountedAmount))
        );
        
        require(responseCode == HederaResponseCodes.SUCCESS, "Gas payment failed");
        
        gasUsage[user] += discountedAmount;
        
        uint256 hbarEquivalent = (discountedAmount * currentPeg) / 1e8;
        
        emit GasPayment(user, discountedAmount, hbarEquivalent);
        
        if (discount > 0) {
            emit DiscountApplied(user, discount);
        }
        
        return true;
    }
    
    /**
     * @notice Use CENTS-H for prediction markets
     * @param user Address making prediction
     * @param amount Amount to stake on prediction
     * @param predictionId Unique prediction identifier
     */
    function placePrediction(
        address user,
        uint256 amount,
        bytes32 predictionId
    ) external onlyPredictionEngine returns (bool) {
        require(amount > 0, "Invalid amount");
        
        // Transfer tokens to prediction pool
        int256 responseCode = HederaTokenService.transferToken(
            tokenAddress,
            user,
            predictionEngine,
            int64(uint64(amount))
        );
        
        require(responseCode == HederaResponseCodes.SUCCESS, "Prediction placement failed");
        
        predictionActivity[user] += amount;
        
        emit PredictionPlaced(user, amount, predictionId);
        
        return true;
    }
    
    /**
     * @notice Calculate user's fee discount based on activity
     * @param user Address to calculate discount for
     * @return Discount in basis points (0-2500 = 0-25%)
     */
    function calculateDiscount(address user) public view returns (uint256) {
        // Get user's KAI CENTS-H balance
        int64 balance = HederaTokenService.balanceOf(tokenAddress, user);
        
        if (balance <= 0) return 0;
        
        uint256 bal = uint256(uint64(balance));
        
        // Discount tiers
        if (bal >= 100000 * 1e8) return 2500; // 25% for 100K+ CENTS
        if (bal >= 50000 * 1e8) return 2000;  // 20% for 50K+
        if (bal >= 10000 * 1e8) return 1500;  // 15% for 10K+
        if (bal >= 5000 * 1e8) return 1000;   // 10% for 5K+
        if (bal >= 1000 * 1e8) return 500;    // 5% for 1K+
        
        return 0;
    }
    
    /**
     * @notice Weekly burn mechanism (deflationary)
     */
    function weeklyBurn() external onlyUtilityController returns (uint256) {
        // Calculate burn amount based on weekly gas fees
        uint256 burnAmount = (totalMinted * weeklyBurnRate) / 10000;
        
        if (burnAmount == 0) return 0;
        
        int256 responseCode = HederaTokenService.burnToken(
            tokenAddress,
            int64(uint64(burnAmount)),
            new int64[](0)
        );
        
        require(responseCode == HederaResponseCodes.SUCCESS, "Burn failed");
        
        totalBurned += burnAmount;
        totalMinted -= burnAmount;
        
        emit TokensBurned(burnAmount, totalBurned);
        
        return burnAmount;
    }
    
    /**
     * @notice Update peg price based on HBAR reserves
     */
    function updatePeg() external onlyUtilityController returns (uint256) {
        // Calculate new peg based on reserve ratio
        uint256 circulatingSupply = totalMinted - totalBurned;
        
        if (circulatingSupply == 0) return currentPeg;
        
        uint256 newPeg = (reserveHBAR * 1e8) / circulatingSupply;
        
        // Limit peg deviation to ±5% per update
        uint256 maxDeviation = (TARGET_PEG * 500) / 10000; // 5%
        
        if (newPeg > TARGET_PEG + maxDeviation) {
            newPeg = TARGET_PEG + maxDeviation;
        } else if (newPeg < TARGET_PEG - maxDeviation) {
            newPeg = TARGET_PEG - maxDeviation;
        }
        
        uint256 oldPeg = currentPeg;
        currentPeg = newPeg;
        
        emit PegAdjusted(oldPeg, newPeg);
        
        return newPeg;
    }
    
    /**
     * @notice Add HBAR to reserves (strengthen peg)
     */
    function addReserves(uint256 hbarAmount) external onlyUtilityController {
        reserveHBAR += hbarAmount;
        emit ReservesUpdated(reserveHBAR);
    }
    
    /**
     * @notice Get user's total utility activity
     */
    function getUserActivity(address user) external view returns (
        uint256 balance,
        uint256 totalGasUsed,
        uint256 totalPredictions,
        uint256 discountTier
    ) {
        int64 bal = HederaTokenService.balanceOf(tokenAddress, user);
        balance = uint256(uint64(bal));
        totalGasUsed = gasUsage[user];
        totalPredictions = predictionActivity[user];
        discountTier = calculateDiscount(user);
        
        return (balance, totalGasUsed, totalPredictions, discountTier);
    }
    
    /**
     * @notice Update burn rate (governance)
     */
    function updateBurnRate(uint256 newRate) external onlyTreasury {
        require(newRate <= 500, "Max 5% burn rate");
        weeklyBurnRate = newRate;
    }
    
    /**
     * @notice Stake CENTS-H for enhanced governance/yield
     * @param amount Amount to stake
     */
    function stake(uint256 amount) external returns (bool) {
        require(amount > 0, "Invalid amount");
        
        int256 responseCode = HederaTokenService.transferToken(
            tokenAddress,
            msg.sender,
            address(this),
            int64(uint64(amount))
        );
        
        require(responseCode == HederaResponseCodes.SUCCESS, "Staking failed");
        
        // Staking rewards handled by separate staking contract
        
        return true;
    }
}