// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title StakingGate
 * @dev A contract that gates access to content by requiring users to stake an exact amount of ETH.
 */
contract StakingGate {
    uint256 public immutable REQUIRED_STAKE_AMOUNT;
    string public name;
    address public immutable owner;
    mapping(address => uint256) public stakedAmount;
    uint256 public totalStakers;
    
    event Staked(address indexed staker, uint256 amount);
    event Withdrawn(address indexed staker, uint256 amount);
    
    constructor(uint256 _requiredStakeAmount, string memory _name, address _owner) {
        REQUIRED_STAKE_AMOUNT = _requiredStakeAmount;
        name = _name;
        owner = _owner;
    }
    
    function stake() external payable {
        require(msg.value == REQUIRED_STAKE_AMOUNT, "Must stake the exact required amount");
        require(stakedAmount[msg.sender] == 0, "Already staked");
        
        stakedAmount[msg.sender] = msg.value;
        totalStakers += 1;
        
        emit Staked(msg.sender, msg.value);
    }
    
    function withdraw() external {
        uint256 amount = stakedAmount[msg.sender];
        require(amount > 0, "No stake to withdraw");
        
        stakedAmount[msg.sender] = 0;
        totalStakers -= 1;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");
        
        emit Withdrawn(msg.sender, amount);
    }
    
    function isStaker(address staker) external view returns (bool) {
        return stakedAmount[staker] > 0;
    }
    
    function getStakedAmount(address staker) external view returns (uint256) {
        return stakedAmount[staker];
    }
    
    function getTotalStakers() external view returns (uint256) {
        return totalStakers;
    }
    
    receive() external payable {
        revert("Direct ETH transfers not allowed");
    }
    
    fallback() external payable {
        revert("Function does not exist");
    }
}

/**
 * @title StakingGateFactory
 * @dev A factory contract that creates new StakingGate contracts with customizable parameters
 */
contract StakingGateFactory {
    event StakingGateCreated(
        address indexed stakingGateAddress,
        address indexed creator,
        uint256 requiredStakeAmount,
        string name
    );
    
    // Maps creators to their created staking gates
    mapping(address => address[]) public creatorToStakingGates;
    
    // All staking gates created by this factory
    address[] public allStakingGates;
    
    // Simple tracking of created contracts for verification
    mapping(address => bool) public isContractCreatedByFactory;
    
    /**
     * @notice Creates a new staking gate contract with customized parameters
     * @param requiredStakeAmount The exact amount of ETH that must be staked in the new contract
     * @param name The name for the new staking contract
     * @return The address of the newly created staking gate contract
     */
    function createStakingGate(uint256 requiredStakeAmount, string calldata name) external returns (address) {
        // Create a new staking gate contract
        StakingGate newStakingGate = new StakingGate(requiredStakeAmount, name, msg.sender);
        
        // Store the new staking gate address
        address stakingGateAddress = address(newStakingGate);
        creatorToStakingGates[msg.sender].push(stakingGateAddress);
        allStakingGates.push(stakingGateAddress);
        
        // Track that this contract was created by our factory
        isContractCreatedByFactory[stakingGateAddress] = true;
        
        // Emit creation event
        emit StakingGateCreated(stakingGateAddress, msg.sender, requiredStakeAmount, name);
        
        return stakingGateAddress;
    }
    
    /**
     * @notice Gets all staking gates created by a specific address
     * @param creator The address of the creator
     * @return An array of staking gate addresses created by this creator
     */
    function getStakingGatesByCreator(address creator) external view returns (address[] memory) {
        return creatorToStakingGates[creator];
    }
    
    /**
     * @notice Gets the total number of staking gates created
     * @return The total number of staking gates
     */
    function getTotalStakingGates() external view returns (uint256) {
        return allStakingGates.length;
    }
    
    /**
     * @notice Gets a batch of staking gates from the complete list
     * @param startIndex The starting index for the batch
     * @param batchSize The size of the batch to retrieve
     * @return A batch of staking gate addresses
     */
    function getStakingGatesBatch(uint256 startIndex, uint256 batchSize) external view returns (address[] memory) {
        require(startIndex < allStakingGates.length, "Start index out of bounds");
        
        // Determine actual batch size (handle end of array)
        uint256 endIndex = startIndex + batchSize;
        if (endIndex > allStakingGates.length) {
            endIndex = allStakingGates.length;
        }
        uint256 actualBatchSize = endIndex - startIndex;
        
        // Create and populate result array
        address[] memory result = new address[](actualBatchSize);
        for (uint256 i = 0; i < actualBatchSize; i++) {
            result[i] = allStakingGates[startIndex + i];
        }
        
        return result;
    }
    
    /**
     * @notice Gets verification info from a contract address
     * @param gateAddress The staking gate contract address
     * @return valid Whether this contract was created by this factory
     * @return stakeAmount The required stake amount
     * @return contractName The name of the contract
     * @return contractOwner The owner of the contract
     */
    function getContractInfo(address gateAddress) external view returns (
        bool valid,
        uint256 stakeAmount,
        string memory contractName,
        address contractOwner
    ) {
        // Check if this is a contract we created
        if (!isContractCreatedByFactory[gateAddress]) {
            return (false, 0, "", address(0));
        }
        
        // If it is, get the info directly from the contract using low-level calls
        // This avoids type casting issues between payable/non-payable addresses
        
        // Get REQUIRED_STAKE_AMOUNT
        (bool successAmount, bytes memory dataAmount) = gateAddress.staticcall(
            abi.encodeWithSignature("REQUIRED_STAKE_AMOUNT()")
        );
        
        // Get name
        (bool successName, bytes memory dataName) = gateAddress.staticcall(
            abi.encodeWithSignature("name()")
        );
        
        // Get owner
        (bool successOwner, bytes memory dataOwner) = gateAddress.staticcall(
            abi.encodeWithSignature("owner()")
        );
        
        if (successAmount && successName && successOwner) {
            stakeAmount = abi.decode(dataAmount, (uint256));
            contractName = abi.decode(dataName, (string));
            contractOwner = abi.decode(dataOwner, (address));
            return (true, stakeAmount, contractName, contractOwner);
        }
        
        // If any call failed, return invalid
        return (false, 0, "", address(0));
    }
}