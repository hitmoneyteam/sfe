// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PancakeClass.sol";
import "./Lottery.sol";

contract LpLottery is PancakeClass {
    address private admin;
    uint256 private lotteryId;
    mapping(uint256 => Lottery) public lotteryStructs;
    mapping(uint256 => bool) public lotteryWinnerDeclared;
    mapping(uint256 => address) private lotteryWinner;

    using SafeMath for uint256;

    constructor(
        address _routerAddres,
        address _tokenSafeMars,
        address _tokenBUSD
    ) PancakeClass(_routerAddres, _tokenSafeMars, _tokenBUSD) {
        admin = msg.sender;
    }

    function transferOwnership(address newManger) public restricted {
        admin = newManger;
    }

    function createContext(uint256 _prizeValue, uint256 _minimumAmount)
        public
        restricted
    {
        lotteryStructs[lotteryId] = new Lottery(
            _prizeValue,
            _minimumAmount,
            address(this)
        );
        lotteryId++;
        emit LotteryCreated(lotteryId);
    }

    function declareWinner(uint256 _lotteryId) public restricted {
        require(!lotteryWinnerDeclared[_lotteryId], "Winner already declared");
        lotteryWinnerDeclared[_lotteryId] = true;
        address winner = lotteryStructs[_lotteryId].declareWinner();
        lotteryWinner[_lotteryId] = winner;
        uint256 tokensGetInSafemars = convertBUSDToSafeMars(
            lotteryStructs[_lotteryId].getPrizeValue()
        );
        IERC20(tokenSafeMars).transfer(winner, tokensGetInSafemars);
    }

    function getEntriesRequired(uint256 _lotteryId)
        public
        view
        returns (uint256)
    {
        return lotteryStructs[_lotteryId].getEntriesRequired();
    }

    function viewWinner(uint256 _lotteryId) public view returns (address) {
        require(
            lotteryWinnerDeclared[_lotteryId],
            "Winner is not declared yet"
        );
        return lotteryWinner[_lotteryId];
    }

    function participateInBusd(uint256 _lotteryId, uint256 amount)
        public
        nonReentrant
    {
        require(
            amount >= lotteryStructs[_lotteryId].getMinimumAmountInBusd(),
            "Transferred amount is less than minimum amount"
        );
        IERC20(tokenBUSD).transferFrom(msg.sender, address(this), amount);
        uint256 entryFee = amount.mul(4).div(100);
        lotteryStructs[_lotteryId].participate(entryFee, msg.sender);
        uint256 stakingAmount = amount.sub(entryFee);
        stakeInBUSD(stakingAmount, msg.sender);
    }

    function participateInSafemars(uint256 _lotteryId, uint256 amount)
        public
        nonReentrant
    {
        uint256 tokensGetInBusdForTotalAmount = convertSafeMarsToBUSD(amount);
        require(
            tokensGetInBusdForTotalAmount >=
                lotteryStructs[_lotteryId].getMinimumAmountInBusd(),
            "Transferred amount is less than minimum amount"
        );

        uint256 initBalance = IERC20(tokenSafeMars).balanceOf(address(this));
        IERC20(tokenSafeMars).transferFrom(msg.sender, address(this), amount);
        amount = IERC20(tokenSafeMars).balanceOf(address(this)).sub(
            initBalance
        );

        uint256 entryFee = amount.mul(4).div(100);
        uint256 tokensGetInBusd = convertSafeMarsToBUSD(entryFee);
        lotteryStructs[_lotteryId].participate(tokensGetInBusd, msg.sender);

        uint256 stakingAmount = amount.sub(entryFee);
        stakeInSafeMars(stakingAmount, msg.sender);
    }

    function exit(uint256 _lotteryId) public nonReentrant {
        require(lotteryWinnerDeclared[_lotteryId], "Winner not declared");
        unstakeAllToSafeMars(msg.sender);
    }

    modifier restricted() {
        require(msg.sender == admin);
        _;
    }

    event LotteryCreated(uint256 lotteryId);
}
