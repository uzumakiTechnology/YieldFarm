// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./SobaToken.sol";

contract YieldFarm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Farm's user info
    struct UserInfo {
        uint256 amount; // LP tokens user provided
        uint256 rewardDebt; //
        /**
            whenever a user deposits or withdraw LP tokens in a pool
            the pool

            the pool's accCakePerShare and lastRewardBlock gets updated
            User receives the pending reward sent their address
            User amount/rewardDebt gets updated

            The term accCakePerShare mean keep track the amount of CAKE earned
            per LP token(share) in specific pool
            pending reward = (user.amount * pool.accCakePerShare) - user.rewardDebt

            When a user claims their pending rewards, the following actions occur:
            a. The pending reward is sent to the user's address.
            b. The user's amount is updated to reflect the current number of LP tokens they have provided.
            c. The user's rewardDebt is updated to the current value of (user.amount * pool.accSobaPerShare), 
            ensuring that any future pending rewards will be calculated accurately.
        */
    }

    struct PoolInfo {
        IERC20 lpToken; // address of LP token contract
        uint256 allocPoint; // allocation point assign to the pool.
        uint256 lastRewardBlock; // last time reward distritubed
        uint256 accSobaPerShare;
        uint256 totalStaked;
    }

    // Sobaja Token
    SobaToken public sobaja;

    address public devAddress; // for every 100 Soba, 10 is sent to dev address
    uint256 public sobaPerBlock; // sobaja token created per block
    uint256 public BONUS_MULTIPLIER = 1; // bonus mulitiplier for early sobaja makers

    // info of each pool
    PoolInfo[] public poolInfo;
    // info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo; // keep track based on poolID
    // total Allocation points, sum of all allocation points in all pools
    uint256 public totalAllocPoint = 0; // if a pool jave 10 allocation points, total allocations all pool is 100 then this pool will receive 10% of newly minted Soba token
    // the block number when SOBA mining start
    uint256 public startBlock;

    /* EVENTS */

    event Deposit(
        address indexed user,
        uint256 indexed poolId,
        uint256 indexed amount
    );

    event Withdraw(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );

    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );

    constructor(
        SobaToken _sobaja,
        address _devaddr,
        uint256 _sobaPerBlock,
        uint256 _startBlock
    ) {
        sobaja = _sobaja;
        devAddress = _devaddr;
        sobaPerBlock = _sobaPerBlock;
        startBlock = _startBlock;

        // staking pool
        // create first pool
        poolInfo.push(
            PoolInfo({
                lpToken: _sobaja,
                allocPoint: 1000,
                lastRewardBlock: startBlock,
                accSobaPerShare: 0,
                totalStaked: 0
            })
        );

        totalAllocPoint = 1000;
    }

    // for early user join the farm
    // owner update the rate for reward
    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function block() external view returns (uint) {
        return block.number;
    }

    // Add new LP to the pool, only owner
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        // when adding a new pool, ensure that all existing pools have up to date data
        if (_withUpdate) {
            massUpdatePools();
        }
        // if block at that present > startBlock so lastRewardBlock = block.number if not = startBlock
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;

        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accSobaPerShare: 0,
                totalStaked: 0
            })
        );
        updateStakingPool();
    }

    // update the give pool's Soba allocation point, only called by owner
    function set(
        uint256 _poolId,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_poolId].allocPoint;
        poolInfo[_poolId].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(
                _allocPoint
            );
            updateStakingPool();
        }
    }

    // update the allocation points and the allocation points for the first pool in poolInfo[] array
    function updateStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;
        // from second pool
        for (uint256 poolId = 1; poolId < length; ++poolId) {
            points = points.add(poolInfo[poolId].allocPoint);
        }
        if (points != 0) {
            points = points.div(3); // normalization
            totalAllocPoint = totalAllocPoint.sub(poolInfo[0].allocPoint).add(
                points
            );
            poolInfo[0].allocPoint = points;
        }
    }

    // return reward mulitiplier over the given _from to _to block
    function getMultiplier(
        uint256 _from,
        uint256 _to
    ) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // pending SOBA on front-end
    function pendingSoba(
        uint256 _poolId,
        address _user
    ) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][_user];

        uint256 accSobaPerShare = pool.accSobaPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 sobaReward = multiplier
                .mul(sobaPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);

            accSobaPerShare = accSobaPerShare.add(
                sobaReward.mul(1e18).div(lpSupply)
            );
        }
        return user.amount.mul(accSobaPerShare).div(1e18).sub(user.rewardDebt);
    }

    // update reward variables for all pools
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 poolId = 0; poolId < length; ++poolId) {
            updatePool(poolId);
        }
    }

    // update reward variables of the given pool
    function updatePool(uint256 _poolId) public {
        PoolInfo storage pool = poolInfo[_poolId];

        // if reward already up to date
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        // how many reward
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);

        uint256 sobaReward = multiplier
            .mul(sobaPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);

        sobaja.mint(devAddress, sobaReward.div(10)); // send 10% to dev address
        sobaja.mint(address(this), sobaReward);
        pool.accSobaPerShare = pool.accSobaPerShare.add(
            sobaReward.mul(1e18).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP
    function deposit(uint256 _poolId, uint256 _amount) public {
        require(_poolId != 0, "Pool must exist");

        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];
        updatePool(_poolId);

        // amount of Lp tokens that the users has previously staked in the pool
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accSobaPerShare)
                .div(1e18)
                .sub(user.rewardDebt);
            if (pending > 0) {
                safeSobaTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
            pool.totalStaked += _amount;
        }
        user.rewardDebt = user.amount.mul(pool.accSobaPerShare).div(1e18);
        emit Deposit(msg.sender, _poolId, _amount);
    }

    function withdraw(uint256 _poolId, uint256 _amount) public {
        require(_poolId != 0, "Pool must exist");
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];
        require(user.amount >= _amount, "Exceed");

        updatePool(_poolId);
        uint256 pending = user.amount.mul(pool.accSobaPerShare).div(1e18).sub(
            user.rewardDebt
        );
        if (pending > 0) {
            safeSobaTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalStaked -= _amount;
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accSobaPerShare).div(1e18);
        emit Withdraw(msg.sender, _poolId, _amount);
    }

    // stake
    function staking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];

        updatePool(0); // at pool index 0
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accSobaPerShare)
                .div(1e18)
                .sub(user.rewardDebt);
            if (pending > 0) {
                safeSobaTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            pool.totalStaked += _amount;
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accSobaPerShare).div(1e18);
        emit Deposit(msg.sender, 0, _amount);
    }

    // withdraw soba token
    function leaveStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0]; // get first pool
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "Exceed");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accSobaPerShare).div(1e18).sub(
            user.rewardDebt
        );
        if (pending > 0) {
            safeSobaTransfer(msg.sender, pending);
        }

        if (_amount > 0) {
            pool.totalStaked -= _amount;
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accSobaPerShare).div(1e18);
        emit Withdraw(msg.sender, 0, _amount);
    }

    // withdraw without caring about reward. Emergency only
    function emergencyWithdraw(uint256 _poolId) public {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        pool.totalStaked -= user.amount;
        emit EmergencyWithdraw(msg.sender, _poolId, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // safe Soba transfer function
    function safeSobaTransfer(address _to, uint256 _amount) internal {
        uint256 sobaBalance = sobaja.balanceOf(address(this));
        if (_amount > sobaBalance) {
            sobaja.transfer(_to, sobaBalance);
        } else {
            sobaja.transfer(_to, _amount);
        }
    }

    // update dev address
    function dev(address _devaddr) public {
        require(msg.sender == devAddress, "Address not satisfy");
        devAddress = _devaddr;
    }
}
