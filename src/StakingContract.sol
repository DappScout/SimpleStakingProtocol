// SPDX-License-identifier: MIT
pragma solidity 0.8.28;

import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Simple Staking Protocol
 * @author DappScout
 * @notice Contract for managing staking logic, rewards management and emergency pausing
 * @dev Contract should be ownable, pausable,
 */
contract StakingContract is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////
                    VARIABLES
    //////////////////////////////////////////////////////*/

    ///@notice The token that users can stake in this contract
    IERC20 public immutable i_stakingToken;

    uint256 public immutable i_minimalStakeAmount;

    ///@notice A stake variable to track whole amount staked
    uint256 public s_totalStakedAmount;

    ///@notice Parameter that defines a reward rate per second
    uint256 internal s_rewardRate;

    uint256 internal s_lastBlockNumber;

    /*//////////////////////////////////////////////////////
                    MAPPINGS
    //////////////////////////////////////////////////////*/

    ///@notice
    mapping(address => uint256) private stakes;

    mapping(address => uint256) private paidRewards;

    ///@notice
    mapping(address => uint256) private rewardDebt;

    mapping(address => uint256) private rewards;

    /*//////////////////////////////////////////////////////
                    EVENTS
    //////////////////////////////////////////////////////*/

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 reward);
    event Paused();
    event Unpaused();

    /*//////////////////////////////////////////////////////
                    ERRORS
    //////////////////////////////////////////////////////*/

    error StakingContract_WrongAmountGiven();
    error StakingContract_InsufficientBalance();

    /*//////////////////////////////////////////////////////
                    CONSTRUCTOR
    //////////////////////////////////////////////////////*/

    constructor(address initialOwner, address _stakingTokenAddress, uint256 _i_minimalStakeAmount)
        Ownable(initialOwner)
    {
        i_minimalStakeAmount = _i_minimalStakeAmount;
        i_stakingToken = IERC20(_stakingTokenAddress);
    }

    /*//////////////////////////////////////////////////////
                    MODIFIERS
    //////////////////////////////////////////////////////*/

    modifier updateReward(address _user) {
        
    

    /*//////////////////////////////////////////////////////
                    MAIN FUNCTIONS
    //////////////////////////////////////////////////////*/

    /**
     * @notice Allows users to stake a specified amount of tokens.
     *         Staking is allowed only when protocol is not paused by the owner
     * @dev  Can be done by regular user, but not the owner
     *
     */

    /*
        Checks:
            minimal amount
            not zero
            rate limit(slash loans)
            
        add amount to user ballance - done
        update the token rewards
        early unstake penalty mechanism
    */

    function stake(uint256 _amount) public whenNotPaused nonReentrant {
        //check if some dust amounts can disturb the protocol
        if (_amount < i_minimalStakeAmount) revert StakingContract_WrongAmountGiven();
        if (_amount == 0) revert StakingContract_WrongAmountGiven();

        if (i_stakingToken.balanceOf(msg.sender) < _amount) revert StakingContract_InsufficientBalance();

        i_stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        stakes[msg.sender] = stakes[msg.sender] + _amount;

        //temporary added here
        s_totalStakedAmount = s_totalStakedAmount + _amount;
        //That function is under construction
        //calculateRewards(msg.sender);

        emit Staked(msg.sender, _amount);
    }

    /**
     * @notice Allows users to withdraw a portion of their staked tokens.
     *         Staking is allowed only when protocol is not paused by the owner
     */
    function unstake(uint256 _amount) public whenNotPaused nonReentrant {
        if(_amount > i_stakingToken.balanceOf(msg.sender)) revert StakingContract_WrongAmountGiven(); // check if balance is greater than unstake amount
        if(_amount == 0) revert StakingContract_WrongAmountGiven(); //is not zero
        
        stakes[msg.sender] = stakes[msg.sender] - _amount;
        i_stakingToken.safeTransfer(msg.sender, _amount);

        calculateRewards(msg.sender);
        emit Unstaked(msg.sender, _amount);
    }

    /**
     * @notice Enables users to claim their accumulated rewards
     *         Staking is allowed only when protocol is not paused by the owner
     */
    function claimRewards() public whenNotPaused nonReentrant {


    }



    /**
     * @notice Permits the owner to halt and resume staking operations.
     *         Staking is allowed only when protocol is not paused by the owner
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /* Concept:
    - should this be executed at the end of every transaction?
    */
    function calculateRewards(address _user) internal {
        uint256 rewardPerToken = (s_rewardRate / s_totalStakedAmount) * (block.number - s_lastBlockNumber);

        rewards[_user] = stakes[_user] * (rewardPerToken * paidRewards[_user]);
        ///@notice update already paid token rewards to user
        paidRewards[_user] = rewardPerToken;

        ///@notice update last block number
        s_lastBlockNumber = block.number;

        ///@notice update total staked amount
        s_totalStakedAmount = s_totalStakedAmount - stakes[_user];

        ///Unde construction - Something is not working here - Check
    }

    ///@notice Function for admin to change reward rate
    function setRewardRate(uint256 _s_rewardRate) external onlyOwner{
        s_rewardRate = _s_rewardRate;
    }

    /*//////////////////////////////////////////////////////
                    GETTER FUNCTIONS
    //////////////////////////////////////////////////////*/

    function getStakedBalance(address _staker) public view returns (uint256) {
        return stakes[_staker];
    }



    function getRewardDebt(address _staker) public view returns (uint256) {
        return rewardDebt[_staker];
    }
}
