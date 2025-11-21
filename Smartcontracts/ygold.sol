// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@hashgraph/smart-contracts/contracts/hts-precompile/HederaTokenService.sol";

/**
 * @title YGOLD-H Multi-Asset Yield Bond
 * @notice Tokenized bond backed by infrastructure bonds, gold, and BTC.HBAR LP
 * @dev Offers 26-55% APY through diversified real-world and DeFi assets
 */
contract YGOLDToken is HederaTokenService {
    
    address public tokenAddress;
    address public treasury;
    address public bondController;
    
    uint256 public constant MAX_SUPPLY = 8_400_000_000 * 10**8; // 8.4 Billion
    uint256 public totalMinted;
    
    // Asset backing composition (basis points)
    struct AssetAllocation {
        uint256 infrastructureBonds;  // 40% target
        uint256 btcHbarLP;            // 30% target
        uint256 goldBacked;           // 20% target
        uint256 usdcReserves;         // 10% target
    }
    
    AssetAllocation public allocation;
    
    // Bond terms
    uint256 public bondMaturity; // timestamp
    uint256 public lockPeriod; // seconds (5-10 years typical)
    uint256 public earlyWithdrawalFee; // basis points (200-500 = 2-5%)
    
    // Performance tracking
    uint256 public currentAPY; // Basis points
    uint256 public totalValueLocked;
    mapping(address => uint256) public bondPurchaseTime;
    mapping(address => uint256) public bondMaturityTime;
    
    event TokenCreated(address indexed tokenAddress);
    event BondPurchased(address indexed buyer, uint256 amount, uint256 maturityTime);
    event BondRedeemed(address indexed holder, uint256 amount, uint256 value, bool earlyWithdrawal);
    event YieldDistributed(address indexed holder, uint256 yield);
    event AssetRebalanced(AssetAllocation newAllocation);
    event QuarterlyReport(uint256 tvl, uint256 apy, uint256 timestamp);
    
    modifier onlyBondController() {
        require(msg.sender == bondController, "Only bond controller");
        _;
    }
    
    modifier onlyTreasury() {
        require(msg.sender == treasury, "Only treasury");
        _;
    }
    
    constructor(
        address _treasury,
        address _bondController,
        uint256 _lockPeriod
    ) {
        treasury = _treasury;
        bondController = _bondController;
        lockPeriod = _lockPeriod;
        
        // Set initial allocation targets
        allocation = AssetAllocation({
            infrastructureBonds: 4000, // 40%
            btcHbarLP: 3000,           // 30%
            goldBacked: 2000,          // 20%
            usdcReserves: 1000         // 10%
        });
        
        earlyWithdrawalFee = 500; // 5% default
        currentAPY = 3000; // 30% initial target
    }
    
    function createToken() external onlyTreasury returns (address) {
        IHederaTokenService.HederaToken memory token;
        
        token.name = "YGOLD-H Multi-Asset Bond";
        token.symbol = "YGOLD-H";
        token.treasury = treasury;
        token.memo = "Tokenized Bonds: Infrastructure + Gold + BTC.HBAR - 26-55% APY";
        token.tokenSupplyType = true; // FINITE
        token.maxSupply = MAX_SUPPLY;
        token.freezeDefault = false;
        
        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](4);
        
        keys[0] = IHederaTokenService.TokenKey(1, 2, abi.encodePacked(treasury));
        keys[1] = IHederaTokenService.TokenKey(4, 2, abi.encodePacked(address(this)));
        keys[2] = IHederaTokenService.TokenKey(3, 2, abi.encodePacked(treasury));
        keys[3] = IHederaTokenService.TokenKey(6, 2, abi.encodePacked(bondController));
        
        token.tokenKeys = keys;
        
        (int256 responseCode, address createdToken) = HederaTokenService.createFungibleToken(
            token,
            MAX_SUPPLY,
            8
        );
        
        require(responseCode == HederaResponseCodes.SUCCESS, "Token creation failed");
        
        tokenAddress = createdToken;
        bondMaturity = block.timestamp + lockPeriod;
        
        emit TokenCreated(tokenAddress);
        
        return tokenAddress;
    }
    
    /**
     * @notice Purchase bonds (mint YGOLD-H)
     * @param buyer Address purchasing bonds
     * @param amount Amount of YGOLD-H bonds to purchase
     * @param purchaseValue USD value of purchase
     */
    function purchaseBond(
        address buyer,
        uint256 amount,
        uint256 purchaseValue
    ) external onlyBondController returns (bool) {
        require(amount > 0, "Invalid amount");
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
            buyer,
            int64(uint64(amount))
        );
        
        require(responseCode == HederaResponseCodes.SUCCESS, "Transfer failed");
        
        totalMinted += amount;
        bondPurchaseTime[buyer] = block.timestamp;
        bondMaturityTime[buyer] = block.timestamp + lockPeriod;
        
        totalValueLocked += purchaseValue;
        
        emit BondPurchased(buyer, amount, bondMaturityTime[buyer]);
        
        return true;
    }
    
    /**
     * @notice Redeem bonds at maturity or with early withdrawal penalty
     * @param holder Address redeeming bonds
     * @param amount Amount of YGOLD-H to redeem
     */
    function redeemBond(
        address holder,
        uint256 amount
    ) external onlyBondController returns (uint256 redemptionValue) {
        require(amount > 0, "Invalid amount");
        
        bool isEarlyWithdrawal = block.timestamp < bondMaturityTime[holder];
        
        // Calculate redemption value
        uint256 baseValue = (amount * totalValueLocked) / totalMinted;
        
        if (isEarlyWithdrawal) {
            // Apply early withdrawal penalty
            uint256 penalty = (baseValue * earlyWithdrawalFee) / 10000;
            redemptionValue = baseValue - penalty
            redemptionValue = baseValue - penalty;
            
            // Penalty goes to remaining bondholders (increases TVL per token)
            totalValueLocked -= redemptionValue; // Only deduct net amount
        } else {
            redemptionValue = baseValue;
            totalValueLocked -= redemptionValue;
        }
        
        // Transfer bonds to contract
        int256 responseCode = HederaTokenService.transferToken(
            tokenAddress,
            holder,
            address(this),
            int64(uint64(amount))
        );
        
        require(responseCode == HederaResponseCodes.SUCCESS, "Transfer failed");
        
        // Burn bonds
        responseCode = HederaTokenService.burnToken(
            tokenAddress,
            int64(uint64(amount)),
            new int64[](0)
        );
        
        require(responseCode == HederaResponseCodes.SUCCESS, "Burning failed");
        
        totalMinted -= amount;
        
        emit BondRedeemed(holder, amount, redemptionValue, isEarlyWithdrawal);
        
        return redemptionValue;
    }
    
    /**
     * @notice Rebalance asset allocation (quarterly DAO governance)
     * @param newAllocation New target allocation percentages
     */
    function rebalanceAssets(
        AssetAllocation calldata newAllocation
    ) external onlyBondController {
        // Verify allocations sum to 100%
        uint256 total = newAllocation.infrastructureBonds + 
                        newAllocation.btcHbarLP + 
                        newAllocation.goldBacked + 
                        newAllocation.usdcReserves;
        
        require(total == 10000, "Allocation must equal 100%");
        
        allocation = newAllocation;
        
        emit AssetRebalanced(newAllocation);
    }
    
    /**
     * @notice Update APY based on actual performance
     */
    function updateAPY(uint256 newAPY) external onlyBondController {
        require(newAPY >= 2600 && newAPY <= 5500, "APY out of range"); // 26-55%
        currentAPY = newAPY;
    }
    
    /**
     * @notice Distribute quarterly yield to bondholders
     * @param holders Array of bondholder addresses
     * @param yieldAmounts Array of yield amounts (in YGOLD-H)
     */
    function distributeQuarterlyYield(
        address[] calldata holders,
        uint256[] calldata yieldAmounts
    ) external onlyBondController {
        require(holders.length == yieldAmounts.length, "Array mismatch");
        
        for (uint256 i = 0; i < holders.length; i++) {
            if (yieldAmounts[i] > 0) {
                emit YieldDistributed(holders[i], yieldAmounts[i]);
            }
        }
    }
    
    /**
     * @notice Publish quarterly performance report
     */
    function publishQuarterlyReport(
        uint256 tvl,
        uint256 apy
    ) external onlyBondController {
        totalValueLocked = tvl;
        currentAPY = apy;
        
        emit QuarterlyReport(tvl, apy, block.timestamp);
    }
    
    /**
     * @notice Get bond holder details
     */
    function getBondDetails(address holder) external view returns (
        uint256 balance,
        uint256 purchaseTime,
        uint256 maturityTime,
        uint256 currentValue,
        bool canRedeemWithoutPenalty
    ) {
        int64 bal = HederaTokenService.balanceOf(tokenAddress, holder);
        balance = uint256(uint64(bal));
        
        purchaseTime = bondPurchaseTime[holder];
        maturityTime = bondMaturityTime[holder];
        
        currentValue = totalMinted > 0 ? (balance * totalValueLocked) / totalMinted : 0;
        canRedeemWithoutPenalty = block.timestamp >= maturityTime;
        
        return (balance, purchaseTime, maturityTime, currentValue, canRedeemWithoutPenalty);
    }
    
    /**
     * @notice Calculate expected value at maturity
     */
    function getProjectedValue(address holder) external view returns (uint256) {
        int64 bal = HederaTokenService.balanceOf(tokenAddress, holder);
        uint256 balance = uint256(uint64(bal));
        
        if (balance == 0) return 0;
        
        uint256 timeToMaturity = bondMaturityTime[holder] > block.timestamp 
            ? bondMaturityTime[holder] - block.timestamp 
            : 0;
        
        uint256 yearsToMaturity = timeToMaturity / 365 days;
        
        // Simple compound interest calculation
        uint256 currentValue = (balance * totalValueLocked) / totalMinted;
        uint256 growthFactor = 10000 + (currentAPY * yearsToMaturity);
        
        return (currentValue * growthFactor) / 10000;
    }
    
    /**
     * @notice Update early withdrawal fee
     */
    function updateEarlyWithdrawalFee(uint256 newFee) external onlyTreasury {
        require(newFee >= 200 && newFee <= 500, "Fee must be 2-5%");
        earlyWithdrawalFee = newFee;
    }
}