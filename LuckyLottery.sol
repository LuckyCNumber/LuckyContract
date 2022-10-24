// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./IBEP20.sol";

contract LuckyLottery is Ownable {
    using SafeMath for uint256;

    struct Pool {
        uint256 pool_id;
        address token;
        uint256 target;
        uint256 current;
        uint256 price;
        uint256 fee;
        uint256 round;
        mapping(uint256 => RoundInfo) history_data;
    }

    struct RoundInfo {
        uint256 total_amount;
        address winner;
        uint256 lucky_number;
        address[] join_list;
    }

    Pool[] public pools;

    event lottery_notify(uint256 _pool_index, uint256 number, uint256 lucky_number, uint256 winner);

    function addPool(
        address _token,
        uint256 _target,
        uint256 _price,
        uint256 _fee
    ) external onlyOwner {
        require(_price > 0, "addPool: Invalid price");
        require(_fee > 0, "addPool Invalid fee");
        require(isContract(_token), "addPool: Invalid _token");
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
        IBEP20 token = IBEP20(pool.token);
        safeTransferFrom(token, msg.sender, address(this), pool.price);
        pool.current += pool.price;
        RoundInfo info = pool.history_data[pool.round];
        info.join_list.push(msg.sender);
    }

    function lottery(uint256 _pool_index, uint256 _random_number) external onlyOwner {
        Pool pool = pools[_pool_index];
        require(pool.current >= pool.target, "lottery: Insufficient bonus pool accumulation");
        uint256 number = block.number + block.timestamp + _random_number;
        uint256 luckyNumber = number.mod(pool.join_history.length);

        RoundInfo info = pool.history_data[pool.round];

        address winner = info.join_list[luckyNumber];

        IBEP20 token = IBEP20(pool.token);
        safeTransfer(token, winner, pool.current.mul(100 - pool.fee).div(100));
        safeTransfer(token, msg.sender, pool.current.mul(pool.fee).div(100));

        info.total_amount = pool.current;
        info.winner = winner;
        info.lucky_number = luckyNumber;

        pool.round++;
        pool.current = 0;
        emit lottery_notify(_pool_index, number, lucky_number, winner);
    }

    function poolLength() public view returns (uint256) {
        return pools.length;
    }

    function poolList() public view returns (Pool[] memory) {
        return pools;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }


}
