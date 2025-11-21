// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title KAI Token Deployment Manager
 * @notice Manages deployment and initialization of all KAI ecosystem tokens
 */
contract KAITokenDeployer {
    
    address public treasury;
    address public admin;
    
    // Deployed token addresses
    address public yhtToken;
    address public ybobToken;
    address public ygoldToken;
    address public centsToken;
    address public gamiToken;
    
    // Controller addresses
    address public vaultController;
    address public stabilityController;
    address public bondController;
    address public utilityController;
    address public socialFiController;
    address public predictionEngine;
    address public creatorStudio;
    address public oracleAddress;
    
    event TokenDeployed(string tokenName, address tokenAddress);
    event ControllersConfigured();
    event DeploymentComplete();
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }
    
    constructor(address _treasury) {
        admin = msg.sender;
        treasury = _treasury;
    }
    
    /**
     * @notice Configure all controller addresses
     */
    function configureControllers(
        address _vaultController,
        address _stabilityController,
        address _bondController,
        address _utilityController,
        address _socialFiController,
        address _predictionEngine,
        address _creatorStudio,
        address _oracleAddress
    ) external onlyAdmin {
        vaultController = _vaultController;
        stabilityController = _stabilityController;
        bondController = _bondController;
        utilityController = _utilityController;
        socialFiController = _socialFiController;
        predictionEngine = _predictionEngine;
        creatorStudio = _creatorStudio;
        oracleAddress = _oracleAddress;
        
        emit ControllersConfigured();
    }
    
    /**
     * @notice Deploy all KAI tokens in sequence
     */
    function deployAllTokens() external onlyAdmin {
        require(vaultController != address(0), "Controllers not configured");
        
        // Deploy YHT
        YHTToken yht = new YHTToken(treasury, vaultController);
        yhtToken = yht.createToken();
        emit TokenDeployed("YHT", yhtToken);
        
        // Deploy YBOB-H
        YBOBToken ybob = new YBOBToken(treasury, stabilityController, oracleAddress);
        ybobToken = ybob.createToken();
        emit TokenDeployed("YBOB-H", ybobToken);
        
        // Deploy YGOLD-H (5 year default lock)
        YGOLDToken ygold = new YGOLDToken(treasury, bondController, 5 * 365 days);
        ygoldToken = ygold.createToken();
        emit TokenDeployed("YGOLD-H", ygoldToken);
        
        // Deploy KAI CENTS-H
        KAICentsToken cents = new KAICentsToken(treasury, utilityController, predictionEngine);
        centsToken = cents.createToken();
        emit TokenDeployed("CENTS-H", centsToken);
        
        // Deploy GAMI
        GAMIToken gami = new GAMIToken(treasury, socialFiController, creatorStudio);
        gamiToken = gami.createToken();
        emit TokenDeployed("GAMI", gamiToken);
        
        emit DeploymentComplete();
    }
    
    /**
     * @notice Get all deployed token addresses
     */
    function getAllTokens() external view returns (
        address yht,
        address ybob,
        address ygold,
        address cents,
        address gami
    ) {
        return (yhtToken, ybobToken, ygoldToken, centsToken, gamiToken);
    }
}