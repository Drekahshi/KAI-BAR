// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@hashgraph/smart-contracts/contracts/hts-precompile/HederaTokenService.sol";

/**
 * @title KAI Token Integration Helper
 * @notice Provides unified interface for interacting with all KAI tokens
 */
contract KAITokenHelper is HederaTokenService {
    
    address public yhtToken;
    address public ybobToken;
    address public ygoldToken;
    address public centsToken;
    address public gamiToken;
    
    constructor(
        address _yht,
        address _ybob,
        address _ygold,
        address _cents,
        address _gami
    ) {
        yhtToken = _yht;
        ybobToken = _ybob;
        ygoldToken = _ygold;
        centsToken = _cents;
        gamiToken = _gami;
    }
    
    /**
     * @notice Associate user with all KAI tokens in one transaction
     * @dev Users must associate before receiving HTS tokens
     */
    function associateAllTokens() external returns (bool) {
        address[] memory tokens = new address[](5);
        tokens[0] = yhtToken;
        tokens[1] = ybobToken;
        tokens[2] = ygoldToken;
        tokens[3] = centsToken;
        tokens[4] = gamiToken;
        
        for (uint256 i = 0; i < tokens.length; i++) {
            int256 responseCode = HederaTokenService.associateToken(
                msg.sender,
                tokens[i]
            );
            
            require(
                responseCode == HederaResponseCodes.SUCCESS,
                "Association failed"
            );
        }
        
        return true;
    }
    
    /**
     * @notice Get user's balance across all KAI tokens
     */
    function getAllBalances(address user) external view returns (
        uint256 yhtBalance,
        uint256 ybobBalance,
        uint256 ygoldBalance,
        uint256 centsBalance,
        uint256 gamiBalance
    ) {
        yhtBalance = uint256(uint64(HederaTokenService.balanceOf(yhtToken, user)));
        ybobBalance = uint256(uint64(HederaTokenService.balanceOf(ybobToken, user)));
        ygoldBalance = uint256(uint64(HederaTokenService.balanceOf(ygoldToken, user)));
        centsBalance = uint256(uint64(HederaTokenService.balanceOf(centsToken, user)));
        gamiBalance = uint256(uint64(HederaTokenService.balanceOf(gamiToken, user)));
        
        return (yhtBalance, ybobBalance, ygoldBalance, centsBalance, gamiBalance);
    }
    
    /**
     * @notice Get total USD value of user's portfolio
     * @param user Address to check
     * @param yhtPrice YHT price in USD (8 decimals)
     * @param ybobPrice YBOB-H price (should be ~$1)
     * @param ygoldPrice YGOLD-H price in USD
     * @param centsPrice CENTS-H price (should be ~HBAR price)
     * @param gamiPrice GAMI price in USD
     */
    function getPortfolioValue(
        address user,
        uint256 yhtPrice,
        uint256 ybobPrice,
        uint256 ygoldPrice,
        uint256 centsPrice,
        uint256 gamiPrice
    ) external view returns (uint256 totalValue) {
        (
            uint256 yhtBal,
            uint256 ybobBal,
            uint256 ygoldBal,
            uint256 centsBal,
            uint256 gamiBal
        ) = this.getAllBalances(user);
        
        totalValue = (yhtBal * yhtPrice) / 1e8;
        totalValue += (ybobBal * ybobPrice) / 1e8;
        totalValue += (ygoldBal * ygoldPrice) / 1e8;
        totalValue += (centsBal * centsPrice) / 1e8;
        totalValue += (gamiBal * gamiPrice) / 1e8;
        
        return totalValue;
    }
    
    /**
     * @notice Approve all KAI tokens for spending by a contract
     * @param spender Contract address to approve
     * @param amount Amount to approve for each token
     */
    function approveAll(address spender, uint256 amount) external returns (bool) {
        address[] memory tokens = new address[](5);
        tokens[0] = yhtToken;
        tokens[1] = ybobToken;
        tokens[2] = ygoldToken;
        tokens[3] = centsToken;
        tokens[4] = gamiToken;
        
        for (uint256 i = 0; i < tokens.length; i++) {
            int256 responseCode = HederaTokenService.approve(
                tokens[i],
                spender,
                int256(amount)
            );
            
            require(responseCode == HederaResponseCodes.SUCCESS, "Approval failed");
        }
        
        return true;
    }
    
    /**
     * @notice Check if user is associated with all tokens
     */
    function checkAssociations(address user) external view returns (
        bool yhtAssociated,
        bool ybobAssociated,
        bool ygoldAssociated,
        bool centsAssociated,
        bool gamiAssociated
    ) {
        // Note: In actual implementation, you'd call HTS precompile to check association
        // This is a simplified version
        
        yhtAssociated = HederaTokenService.isAssociated(user, yhtToken);
        ybobAssociated = HederaTokenService.isAssociated(user, ybobToken);
        ygoldAssociated = HederaTokenService.isAssociated(user, ygoldToken);
        centsAssociated = HederaTokenService.isAssociated(user, centsToken);
        gamiAssociated = HederaTokenService.isAssociated(user, gamiToken);
        
        return (
            yhtAssociated,
            ybobAssociated,
            ygoldAssociated,
            centsAssociated,
            gamiAssociated
        );
    }
}