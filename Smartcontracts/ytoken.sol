// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@hashgraph/smart-contracts/contracts/hts-precompile/HederaTokenService.sol";
import "@hashgraph/smart-contracts/contracts/hts-precompile/IHederaTokenService.sol";
import "@hashgraph/smart-contracts/contracts/hts-precompile/HederaResponseCodes.sol";

/**
 * @title YHT Token - Multi-Strategy DeFi Vault Token
 * @notice Represents shares in BTC.HBAR liquidity vault with automated yield optimization
 * @dev Built on Hedera Token Service for native integration and minimal gas costs
 */
contract YHTToken is HederaTokenService {
    
    // Token configuration
    address public tokenAddress;
    address public treasury;
    address public vaultController;
    
    // Supply management
    uint256 public constant MAX_SUPPLY = 2_100_000_000 * 10**8; // 2.1 Billion with 8 decimals
    uint256 public totalMinted;
    
    // Yield tracking
    mapping(address => uint256) public lastYieldClaim;
    mapping(address => uint256) public accumulatedYield;
    
    // Vault performance metrics
    uint256 public totalValueLocked;
    uint256 public currentAPY; // Basis points (2400 = 24%)
    
    // Events
    event TokenCreated(address indexed tokenAddress, string name, string symbol);
    event YieldDistributed(address indexed recipient, uint256 amount, uint256 timestamp);
    event VaultRebalanced(uint256 newTVL, uint256 newAPY, uint256 timestamp);
    event SharesMinted(address indexed recipient, uint256 shares, uint256 underlyingValue);
    event SharesBurned(address indexed holder, uint256 shares, uint256 underlyingValue);
    
    // Modifiers
    modifier onlyVaultController() {
        require(msg.sender == vaultController, "Only vault controller");
        _;
    }
    
    modifier onlyTreasury() {
        require(msg.sender == treasury, "Only treasury");
        _;
    }
    
    constructor(address _treasury, address _vaultController) {
        treasury = _treasury;
        vaultController = _vaultController;
    }
    
    /**
     * @notice Initialize HTS token with Hedera-native features
     * @dev Creates token through Hedera Token Service
     */
    function createToken() external onlyTreasury returns (address) {
        IHederaTokenService.HederaToken memory token;
        
        token.name = "KAI YToken - Multi-Strategy Vault";
        token.symbol = "YHT";
        token.treasury = treasury;
        token.memo = "BTC.HBAR LP Vault Shares - Earn 22-38% APY";
        token.tokenSupplyType = true; // FINITE supply
        token.maxSupply = MAX_SUPPLY;
        token.freezeDefault = false;
        
        // Token keys configuration
        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](4);
        
        // Admin key - treasury control
        keys[0] = IHederaTokenService.TokenKey(
            KeyHelper.KeyType.ADMIN,
            KeyHelper.KeyValueType.CONTRACT_ID,
            KeyHelper.keyFrom(treasury)
        );
        
        // Supply key - minting control
        keys[1] = IHederaTokenService.TokenKey(
            KeyHelper.KeyType.SUPPLY,
            KeyHelper.KeyValueType.CONTRACT_ID,
            KeyHelper.keyFrom(address(this))
        );
        
        // Wipe key - emergency controls
        keys[2] = IHederaTokenService.TokenKey(
            KeyHelper.KeyType.WIPE,
            KeyHelper.KeyValueType.CONTRACT_ID,
            KeyHelper.keyFrom(treasury)
        );
        
        // Pause key - circuit breaker
        keys[3] = IHederaTokenService.TokenKey(
            KeyHelper.KeyType.PAUSE,
            KeyHelper.KeyValueType.CONTRACT_ID,
            KeyHelper.keyFrom(vaultController)
        );
        
        token.tokenKeys = keys;
        
        (int256 responseCode, address createdToken) = HederaTokenService.createFungibleToken(
            token,
            MAX_SUPPLY,
            8 // decimals
        );
        
        require(responseCode == HederaResponseCodes.SUCCESS, "Token creation failed");
        
        tokenAddress = createdToken;
        
        emit TokenCreated(tokenAddress, token.name, token.symbol);
        
        return tokenAddress;
    }
    
    /**
     * @notice Mint YHT shares when user deposits into vault
     * @param recipient Address receiving shares
     * @param shares Amount of shares to mint (represents vault ownership)
     * @param underlyingValue USD value of underlying assets
     */
    function mintShares(
        address recipient,
        uint256 shares,
        uint256 underlyingValue
    ) external onlyVaultController returns (bool) {
        require(totalMinted + shares <= MAX_SUPPLY, "Exceeds max supply");
        require(shares > 0, "Invalid share amount");
        
        int256 responseCode = HederaTokenService.mintToken(
            tokenAddress,
            int64(uint64(shares)),
            new bytes[](0)
        );
        
        require(responseCode == HederaResponseCodes.SUCCESS, "Minting failed");
        
        responseCode = HederaTokenService.transferToken(
            tokenAddress,
            address(this),
            recipient,
            int64(uint64(shares))
        );
        
        require(responseCode == HederaResponseCodes.SUCCESS, "Transfer failed");
        
        totalMinted += shares;
        lastYieldClaim[recipient] = block.timestamp;
        
        emit SharesMinted(recipient, shares, underlyingValue);
        
        return true;
    }
    
    /**
     * @notice Burn YHT shares when user withdraws from vault
     * @param holder Address burning shares
     * @param shares Amount of shares to burn
     * @param underlyingValue USD value being withdrawn
     */
    function burnShares(
        address holder,
        uint256 shares,
        uint256 underlyingValue
    ) external onlyVaultController returns (bool) {
        require(shares > 0, "Invalid share amount");
        
        // Transfer shares back to contract first
        int256 responseCode = HederaTokenService.transferToken(
            tokenAddress,
            holder,
            address(this),
            int64(uint64(shares))
        );
        
        require(responseCode == HederaResponseCodes.SUCCESS, "Transfer failed");
        
        // Burn the shares
        responseCode = HederaTokenService.burnToken(
            tokenAddress,
            int64(uint64(shares)),
            new int64[](0)
        );
        
        require(responseCode == HederaResponseCodes.SUCCESS, "Burning failed");
        
        totalMinted -= shares;
        
        emit SharesBurned(holder, shares, underlyingValue);
        
        return true;
    }
    
    /**
     * @notice Distribute yield to token holders
     * @dev Called by vault controller after harvesting yields
     * @param recipients Array of addresses receiving yield
     * @param amounts Array of yield amounts (in YHT)
     */
    function distributeYield(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyVaultController returns (bool) {
        require(recipients.length == amounts.length, "Array length mismatch");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];
            
            accumulatedYield[recipient] += amount;
            
            emit YieldDistributed(recipient, amount, block.timestamp);
        }
        
        return true;
    }
    
    /**
     * @notice Update vault performance metrics
     * @dev Called after rebalancing operations
     */
    function updateVaultMetrics(
        uint256 newTVL,
        uint256 newAPY
    ) external onlyVaultController {
        totalValueLocked = newTVL;
        currentAPY = newAPY;
        
        emit VaultRebalanced(newTVL, newAPY, block.timestamp);
    }
    
    /**
     * @notice Calculate user's share of vault
     * @param holder Address to check
     * @return User's share percentage (basis points)
     */
    function getSharePercentage(address holder) external view returns (uint256) {
        int64 balance = HederaTokenService.balanceOf(tokenAddress, holder);
        
        if (balance <= 0 || totalMinted == 0) return 0;
        
        return (uint256(uint64(balance)) * 10000) / totalMinted; // Basis points
    }
    
    /**
     * @notice Get user's underlying vault value
     * @param holder Address to check
     * @return USD value of user's vault position
     */
    function getUnderlyingValue(address holder) external view returns (uint256) {
        int64 balance = HederaTokenService.balanceOf(tokenAddress, holder);
        
        if (balance <= 0 || totalMinted == 0) return 0;
        
        return (uint256(uint64(balance)) * totalValueLocked) / totalMinted;
    }
    
    /**
     * @notice Emergency pause trading
     */
    function pauseToken() external onlyVaultController {
        int256 responseCode = HederaTokenService.pauseToken(tokenAddress);
        require(responseCode == HederaResponseCodes.SUCCESS, "Pause failed");
    }
    
    /**
     * @notice Resume trading after emergency
     */
    function unpauseToken() external onlyVaultController {
        int256 responseCode = HederaTokenService.unpauseToken(tokenAddress);
        require(responseCode == HederaResponseCodes.SUCCESS, "Unpause failed");
    }
    
    /**
     * @notice Update vault controller address
     */
    function updateVaultController(address newController) external onlyTreasury {
        require(newController != address(0), "Invalid address");
        vaultController = newController;
    }
    
    /**
     * @notice Update treasury address
     */
    function updateTreasury(address newTreasury) external onlyTreasury {
        require(newTreasury != address(0), "Invalid address");
        treasury = newTreasury;
    }
}

/**
 * @title KeyHelper Library
 * @notice Helper functions for Hedera key management
 */
library KeyHelper {
    enum KeyType {
        ADMIN,
        KYC,
        FREEZE,
        WIPE,
        SUPPLY,
        FEE,
        PAUSE
    }
    
    enum KeyValueType {
        INHERIT_ACCOUNT_KEY,
        CONTRACT_ID,
        ED25519,
        SECP256K1,
        DELEGATABLE_CONTRACT_ID
    }
    
    function keyFrom(address addr) internal pure returns (bytes memory) {
        return abi.encodePacked(addr);
    }
}