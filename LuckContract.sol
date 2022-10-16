// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "./utils/ReentrancyGuard.sol";
import "./utils/Ownable.sol";
import "./utils/SafeMath.sol";
import "./utils/SafeERC20.sol";
import "./interfaces/IAdmin.sol";
import "./interfaces/IERC20.sol";

contract LuckyContract is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IAdmin public admin;
    IERC20 public LuckyToken;
    uint256 public tokenWei;

    struct LuckyInfo {
        uint256 participationCounts;
        uint256 totalAmount;
        address winner;
        uint256 luckyNumber;
        mapping(uint256 => address) luckyList;
        mapping(address => uint256) totalBet;
    }

    mapping(uint256 => LuckyInfo) Infos;
    uint256 public round = 1;

    event winner(uint256 indexed round, address winner, uint256 winAmount, uint256 feeRate, uint256 number);

    constructor(
        address _admin,
        address _token,
        uint256 _tokenDecimals
    ) {
        require(_admin != address(0), "_admin != address(0)");
        admin = IAdmin(_admin);
        LuckyToken = IERC20(_token);
        tokenWei = 10 ** _tokenDecimals;
    }

    function bet(uint256 _amount) external nonReentrant {
        require(_amount % tokenWei == 0, "bet: Invalid amount");
        LuckyInfo storage curInfo = Infos[round];
        curInfo.totalAmount = curInfo.totalAmount.add(_amount);
        curInfo.totalBet[msg.sender] = curInfo.totalBet[msg.sender].add(
            _amount
        );
        LuckyToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 steps = _amount.div(tokenWei);
        for (uint256 i = 0; i < steps; i++) {
            curInfo.luckyList[curInfo.participationCounts] = msg.sender;
            curInfo.participationCounts++;
        }
    }

    function clacWinner(uint256 _len, uint256 _feeRate) external onlyOwner {
        require(_len > 17, "clacWinner: Invalid _len");
        require(_feeRate < 20, "clacWinner: Invalid _feeRate");
        LuckyInfo storage curInfo = Infos[round];
        require(
            curInfo.participationCounts > 1,
            "clacWinner: Insufficient participants"
        );
        uint256 number = block.number + block.timestamp;
        uint256 luckyNumber = number.mod(curInfo.participationCounts);
        address winnerAddress = curInfo.luckyList[curInfo.luckyNumber];
        uint256 winAmount = curInfo.totalAmount.mul(100 - _feeRate).div(100);
        LuckyToken.safeTransfer(winnerAddress, winAmount);
        LuckyToken.safeTransfer(
            msg.sender,
            curInfo.totalAmount.mul(_feeRate).div(100)
        );
        curInfo.winner = winnerAddress;
        curInfo.luckyNumber = luckyNumber;
        emit winner(round, winnerAddress, winAmount, _feeRate, number);
        round++;
        tokenWei = 10 ** _len;
    }

    function queryAddressByIndex(uint256 _round, uint256 _participationIndex)
    public
    view
    returns (address)
    {
        LuckyInfo storage curInfo = Infos[_round];
        return curInfo.luckyList[_participationIndex];
    }

    function roundWinner(uint256 _round) public view returns (address) {
        LuckyInfo storage curInfo = Infos[_round];
        return curInfo.winner;
    }

    function roundLuckNumber(uint256 _round) public view returns (uint256) {
        LuckyInfo storage curInfo = Infos[_round];
        return curInfo.luckyNumber;
    }

    function participationCount(uint256 _round) public view returns (uint256){
        LuckyInfo storage curInfo = Infos[_round];
        return curInfo.participationCounts;
    }

    function totalPool(uint256 _round) public view returns (uint256) {
        LuckyInfo storage curInfo = Infos[_round];
        return curInfo.totalAmount;
    }

    function personTotal(uint256 _round, address _address)
    public
    view
    returns (uint256)
    {
        LuckyInfo storage curInfo = Infos[_round];
        return curInfo.totalBet[_address];
    }
}
