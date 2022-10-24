// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./IBEP20.sol";

contract LuckyLottery is Ownable {
    using SafeMath for uint256;

    struct Pool {
        uint256 pool_id;
        uint status;
        address token;
        uint256 target;
        uint256 current;
        uint256 price;
        uint256 fee;
        address[] join_history;
    }

    Pool[] public pools;

    event lottery_notify(uint256 _pool_index, uint256 number, uint256 lucky_number, uint256 winner);

    function addPool(
        address _token,
        uint256 _target,
        uint256 _price,
        uint256 _fee
    ) public {
        require(_price > 0, "addPool: Invalid price");
        require(_fee > 0, "addPool Invalid fee");
        Pool memory pool;
        pool.pool_id = pools.length;
        pool.target = _target;
        pool.token = _token;
        pool.price = _price;
        pool.fee = _fee;
        pools.push(pool);
    }

    function join(uint256 _pool_index) external {
        Pool pool = pools[_pool_index];
        require(pool.status == 0, "join: The award pool has ended");
        IBEP20 token = IBEP20(pool.token);
        token.transferFrom(msg.sender, address(this), pool.price);
        pool.current += pool.price;
        pool.join_history.push(msg.sender);
    }

    function lottery(uint256 _pool_index, uint256 _random_number) external onlyOwner {
        Pool pool = pools[_pool_index];
        require(pool.current >= pool.target, "lottery: Insufficient bonus pool accumulation");
        uint256 number = block.number + block.timestamp + _random_number;
        uint256 luckyNumber = number.mod(pool.join_history.length);
        address winner = pool.join_history[luckyNumber];
        token.transfer(winner, pool.current.mul(100 - pool.fee).div(100));
        IBEP20 token = IBEP20(pool.token);
        token.transfer(msg.sender, pool.current.mul(pool.fee).div(100));
        pool.status = 1;
        emit lottery_notify(_pool_index, number, lucky_number, winner);
    }

    function reset(uint256 _pool_index, address _token, uint256 _target, uint256 _price, uint256 _fee) external onlyOwner {
        Pool pool = pools[_pool_index];
        require(pool.status == 1, "reset: Service charge has not been collected");
        pool.status = 0;
        pool.current = 0;
        pool.token = _token;
        pool.target = _target;
        pool.price = _price;
        pool.fee = _fee;
        delete pool.join_history;
    }

    function poolLength() public view returns (uint256) {
        return pools.length;
    }

    function poolList() public view returns (Pool[] memory) {
        return pools;
    }


}
