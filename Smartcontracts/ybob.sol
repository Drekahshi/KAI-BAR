// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@hashgraph/smart-contracts/contracts/hts-precompile/HederaTokenService.sol";
import "@hashgraph/smart-contracts/contracts/hts-precompile/IHederaTokenService.sol";

/**
 * @title YBOB-H Algorithmic Stablecoin
 * @notice USD-pegged stablecoin backed by BTC.HBAR LP + USDC with yield generation
 * @dev Maintains 1:1 USD peg through algorithmic rebalancing on Hedera
 */
contract YBOBToken is HederaTokenService {
    
    address public tokenAddress;
    address public treasury;
    address public stabilityController;
    address public oracleAddress;
    
    // Supply is dynamic (algorithmic)
    uint256 public totalMinted;
    uint256 public totalBurned;
    
    // Peg maintenance
    uint256 public constant TARGET_PRICE = 1_00000000; // $1.00 (8 decimals)
    uint256 public currentPrice;
    uint256 public collateralizationRatio; // Basis points (15000 = 150%)
    
    // Backing assets
    struct BackingAssets {
        uint256 usdc;           // USDC reserves
        uint256 btcHbarLP;      // BTC.HBAR LP tokens
        uint256 hbarStaked;     // Staked HBAR
        uint256 totalValue;     // Total USD value
    }
    
    BackingAssets public backing;
    
    // Yield tracking
    uint256 public accumulatedYield;
    uint256 public yieldAPY; // Basis points
    mapping(address => uint256) public lastYieldSnapshot;
    
    // Events
    event TokenCreated(address indexed tokenAddress);
    event Minted(address indexed recipient, uint256 amount, uint256 collateralValue);
    event Burned(address indexed holder, uint256 amount, uint256 collateralReturned);
    event PegAdjusted(uint256 oldPrice, uint256 newPrice, uint256 timestamp);
    event YieldAccrued(uint256 amount, uint256 newAPY);
    event CollateralRebalanced(uint256 usdc, uint256 btcHbar, uint256 hbar);
    event EmergencyPause(string reason, uint256 timestamp);
    
    modifier onlyStabilityController() {
        require(msg.sender == stabilityController, "Only stability controller");
        _;
    }
    
    modifier onlyTreasury() {
        require(msg.sender == treasury, "Only treasury");
        _;
    }
    
    constructor(
        address _treasury,
        address _stabilityController,
        address _oracleAddress
    ) {
        treasury = _treasury;
        stabilityController = _stabilityController;
        oracleAddress = _oracleAddress;
        collateralizationRatio = 15000; // 150% initial
        currentPrice = TARGET_PRICE;
    }
    
    function createToken() external onlyTreasury returns (address) {
        IHederaTokenService.HederaToken memory token;
        
        token.name = "YBOB-H Stablecoin";
        token.symbol = "YBOB-H";
        token.treasury = treasury;
        token.memo = "USD Stablecoin with 10-15% Yield on Hedera";
        token.tokenSupplyType = false; // INFINITE (algorithmic supply)
        token.freezeDefault = false;
        
        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](5);
        
        keys[0] = IHederaTokenService.TokenKey(
            1, // ADMIN
            2, // CONTRACT_ID
            abi.encodePacked(treasury)
        );
        
        keys[1] = IHederaTokenService.TokenKey(
            4, // SUPPLY
            2, // CONTRACT_ID
            abi.encodePacked(address(this))
        );
        
        keys[2] = IHederaTokenService.TokenKey(
            3, // WIPE
            2, // CONTRACT_ID
            abi.encodePacked(treasury)
        );
        
        keys[3] = IHederaTokenService.TokenKey(
            6, // PAUSE
            2, // CONTRACT_ID
            abi.encodePacked(stabilityController)
        );
        
        keys[4] = IHederaTokenService.TokenKey(
            2, // KYC (for compliance)
            2, // CONTRACT_ID
            abi.encodePacked(treasury)
        );
        
        token.tokenKeys = keys;
        
        (int256 responseCode, address createdToken) = HederaTokenService.createFungibleToken(
            token,
            0, // Initial supply (will mint as needed)
            8  // decimals
        );
        
        require(responseCode == HederaResponseCodes.SUCCESS, "Token creation failed");
        
        tokenAddress = createdToken;
        
        emit TokenCreated(tokenAddress);
        
        return tokenAddress;
    }
    
    /**
     * @notice Mint YBOB-H against collateral deposit
     * @param recipient Address receiving stablecoins
     * @param amount Amount of YBOB-H to mint
     * @param collateralValue USD value of deposited collateral
     */
    function mint(
        address recipient,
        uint256 amount,
        uint256 collateralValue
    ) external onlyStabilityController returns (bool) {
        require(amount > 0, "Invalid amount");
        
        // Verify sufficient collateralization
        uint256 requiredCollateral = (amount * collateralizationRatio) / 10000;
        require(collateralValue >= requiredCollateral, "Insufficient collateral");
        
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
        lastYieldSnapshot[recipient] = block.timestamp;
        
        emit Minted(recipient, amount, collateralValue);
        
        return true;
    }
    
    /**
     * @notice Burn YBOB-H to redeem collateral
     * @param holder Address burning stablecoins
     * @param amount Amount of YBOB-H to burn
     */
    function burn(
        address holder,
        uint256 amount
    ) external onlyStabilityController returns (uint256 collateralReturned) {
        require(amount > 0, "Invalid amount");
        
        // Transfer to contract first
        int256 responseCode = HederaTokenService.transferToken(
            tokenAddress,
            holder,
            address(this),
            int64(uint64(amount))
        );
        
        require(responseCode == HederaResponseCodes.SUCCESS, "Transfer failed");
        
        // Burn tokens
        responseCode = HederaTokenService.burnToken(
            tokenAddress,
            int64(uint64(amount)),
            new int64[](0)
        );
        
        require(responseCode == HederaResponseCodes.SUCCESS, "Burning failed");
        
        totalBurned += amount;
        
        // Calculate collateral to return (proportional to backing)
        uint256 circulatingSupply = totalMinted - totalBurned;
        collateralReturned = (amount * backing.totalValue) / circulatingSupply;
        
        emit Burned(holder, amount, collateralReturned);
        
        return collateralReturned;
    }
    
    /**
     * @notice Update price from oracle and adjust peg if needed
     */
    function updatePrice() external onlyStabilityController returns (uint256) {
        // Get price from Hedera oracle
        uint256 newPrice = _getPriceFromOracle();
        
        uint256 oldPrice = currentPrice;
        currentPrice = newPrice;
        
        // If price deviates >0.5%, trigger arbitrage mechanism
        uint256 deviation = _calculateDeviation(newPrice, TARGET_PRICE);
        
        if (deviation > 50) { // 0.5%
            _adjustPeg(newPrice);
        }
        
        emit PegAdjusted(oldPrice, newPrice, block.timestamp);
        
        return newPrice;
    }
    
    /**
     * @notice Update backing assets composition
     */
    function updateBacking(
        uint256 usdcAmount,
        uint256 btcHbarLPAmount,
        uint256 hbarStakedAmount,
        uint256 totalUSDValue
    ) external onlyStabilityController {
        backing.usdc = usdcAmount;
        backing.btcHbarLP = btcHbarLPAmount;
        backing.hbarStaked = hbarStakedAmount;
        backing.totalValue = totalUSDValue;
        
        // Verify collateralization ratio maintained
        uint256 circulatingSupply = totalMinted - totalBurned;
        uint256 currentRatio = (totalUSDValue * 10000) / circulatingSupply;
        
        require(currentRatio >= collateralizationRatio, "Under-collateralized");
        
        emit CollateralRebalanced(usdcAmount, btcHbarLPAmount, hbarStakedAmount);
    }
    
    /**
     * @notice Accrue yield from backing assets
     * @param yieldAmount USD value of yield generated
     */
    function accrueYield(uint256 yieldAmount) external onlyStabilityController {
        accumulatedYield += yieldAmount;
        
        // Calculate new APY based on yield performance
        uint256 circulatingSupply = totalMinted - totalBurned;
        yieldAPY = (yieldAmount * 10000 * 365) / circulatingSupply;
        
        emit YieldAccrued(yieldAmount, yieldAPY);
    }
    
    /**
     * @notice Get user's accrued yield
     */
    function getUserYield(address user) external view returns (uint256) {
        int64 balance = HederaTokenService.balanceOf(tokenAddress, user);
        
        if (balance <= 0) return 0;
        
        uint256 timeSinceSnapshot = block.timestamp - lastYieldSnapshot[user];
        uint256 dailyYield = (uint256(uint64(balance)) * yieldAPY) / (10000 * 365);
        
        return dailyYield * (timeSinceSnapshot / 1 days);
    }
    
    /**
     * @notice Emergency pause if peg breaks severely
     */
    function emergencyPause(string calldata reason) external onlyStabilityController {
        int256 responseCode = HederaTokenService.pauseToken(tokenAddress);
        require(responseCode == HederaResponseCodes.SUCCESS, "Pause failed");
        
        emit EmergencyPause(reason, block.timestamp);
    }
    
    function unpause() external onlyTreasury {
        int256 responseCode = HederaTokenService.unpauseToken(tokenAddress);
        require(responseCode == HederaResponseCodes.SUCCESS, "Unpause failed");
    }
    
    /**
     * @notice Internal peg adjustment mechanism
     */
    function _adjustPeg(uint256 newPrice) internal {
        if (newPrice > TARGET_PRICE) {
            // Price too high: mint more YBOB-H to increase supply
            // (Implemented by stability controller calling mint)
        } else {
            // Price too low: burn YBOB-H to decrease supply
            // (Implemented by stability controller calling burn)
        }
    }
    
    function _getPriceFromOracle() internal view returns (uint256) {
        // Integration with Hedera oracle (Chainlink, Pyth, etc.)
        // Returns price with 8 decimals
        // Placeholder - implement actual oracle integration
        return currentPrice;
    }
    
    function _calculateDeviation(uint256 price1, uint256 price2) internal pure returns (uint256) {
        uint256 diff = price1 > price2 ? price1 - price2 : price2 - price1;
        return (diff * 10000) / price2; // Basis points
    }
    
    function updateCollateralizationRatio(uint256 newRatio) external onlyTreasury {
        require(newRatio >= 11000 && newRatio <= 20000, "Invalid ratio"); // 110-200%
        collateralizationRatio = newRatio;
    }
}