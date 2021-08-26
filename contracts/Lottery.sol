// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Lottery {
    using SafeMath for uint256;

    uint256 private prizeValue;
    uint256 private minimumAmountInBusd;
    address private manager;
    uint256 private entriesRequired;
    uint256 private currentTicketId;
    bool private isActive;
    mapping(uint256 => address) allParticipants;

    constructor(uint256 _prizeValue, uint256 _minimumAmountInBusd,address _manager) {
        prizeValue = _prizeValue;
        minimumAmountInBusd=_minimumAmountInBusd;
        entriesRequired = _prizeValue.div(10**18);
        manager = _manager;
        isActive = true;
    }

    function participate(uint256 _amount, address _particpant) external {
        require(entriesRequired != 0, "context is full");
        require(isActive, "context is not active anymore");

        uint256 _tickets = _amount.div(10**18);
        require(
            entriesRequired >= _tickets,
            "entree fee should be smaller than entries required"
        );
        for (uint256 i = 0; i < _tickets; i++) {
            allParticipants[currentTicketId] = _particpant;
            currentTicketId++;
        }
        entriesRequired = entriesRequired.sub(_tickets);
        emit PlayerParticipated(_particpant);
    }

    function declareWinner() external restricted returns(address){
        require(isActive,"Context is not active anymore");
        require(entriesRequired == 0, "context is not full yet");
        isActive = false;
        uint256 winnerTicketNo = random().mod(prizeValue.div(10**18));
        return allParticipants[winnerTicketNo];
    }

    function getEntriesRequired() external view returns(uint256){
        return entriesRequired;
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        prizeValue
                    )
                )
            );
    }

    function getPrizeValue() external view returns(uint256) {
        return prizeValue;
    }

    function getMinimumAmountInBusd() external view returns(uint256) {
        return minimumAmountInBusd;
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    event PlayerParticipated(
        address playerAddress
    );
}
