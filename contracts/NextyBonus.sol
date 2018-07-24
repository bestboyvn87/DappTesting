pragma solidity ^0.4.17;

//Epoch timestamp: 1577836800
//Timestamp in milliseconds: 1577836800000
//Human time (GMT): Wednesday, 1 January 2020 00:00:00
//Human time (your time zone): thứ tư, 1 tháng 1 năm 2020 07:00:00 GMT+07:00

import './SafeMath.sol';

contract NextyBonus {
    using SafeMath for uint256;
    
    uint256 public constant BONUS_LOCK_DURATION= 6*30*24*60*60;
    uint256 public constant CONTRACT_ENDTIME= 1577836800;
    
    enum ActionType {
        AddMember,
        RemoveMember,
        GiveFixed,
        GiveBonus,
        GetBack,
        Deposit,
        Withdraw
    }
    
    enum StatusType {
        Pending,
        Completed
    }
    
    struct LogAtribute {
        ActionType action;
        uint256 value;
        uint256 time;
        uint256 endTime;
        bool status; //0 Pending 1 Completed
    }
    
    struct MemberAtribute {
        bool exist;
        uint256 id;
    }
    
    address public owner;
    
    uint256 totalAmount= 0;
    uint256 totalMember= 0;
    
    address[] addressList;
    
    mapping(address => MemberAtribute) member;
    mapping(uint256 => bool) id;
    
    mapping(address => LogAtribute[]) log;
    
    //Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyMember() {
        require(member[msg.sender].exist);
        _;
    }
    
    //Events
    event ownerWithdrawSuccess(uint256 _amount);
    event addMemberSuccess(address _address);
    event removeMemberSuccess(address _address);
    event getBackSuccess(uint256 _amount);
    event giveBonusSuccess(address _to);
    event giveFixedSuccess(address _to);
    event unlockedWithdraw(address _address, uint256 _amount);
    
    //Owner's Functions

    constructor () public{ 
        owner= msg.sender;
        addMember(msg.sender);
    }
    
    function () public payable {
        totalAmount= totalAmount.add(msg.value);
    }
    
    function deposit() public payable {
        totalAmount= totalAmount.add(msg.value);
    }
    
    function getTotalAmount() public onlyOwner view returns (uint256){
        return this.balance;
    }
    
    function ownerWithdraw(uint256 _amount) onlyOwner public {
        require(_amount <= totalAmount);
        owner.transfer(_amount);
        totalAmount.sub(_amount);
        emit ownerWithdrawSuccess(_amount);
    }
    
    function getMemberList() onlyOwner public view returns(address[]){
        return addressList;
    }
    
    function addMember(address _address) onlyOwner public {
        require(!member[_address].exist);
        totalMember++;
        addressList.push(_address);
        member[_address].exist= true;
        member[_address].id= totalMember;
        LogAtribute memory newLog;
        newLog.action = ActionType.AddMember;
        newLog.value= totalMember;
        newLog.time= now;
        newLog.status= true;
        log[_address].push(newLog);
        emit addMemberSuccess(_address);
    }
    
    function giveBonus(address _to, uint256 _amount) onlyOwner public payable {
        require(totalAmount >=  _amount);
        totalAmount.sub(_amount);
        LogAtribute memory newLog;
        newLog.action= ActionType.GiveBonus;
        newLog.value= _amount;
        newLog.time= now;
        newLog.endTime= now.add(BONUS_LOCK_DURATION);
        newLog.status= false;
        log[_to].push(newLog);
        emit giveBonusSuccess(_to);
    }
    
    function giveFixed(address _to, uint256 _amount) onlyOwner public {
        require(totalAmount >=  _amount);
        totalAmount.sub(_amount);
        LogAtribute memory newLog;
        newLog.action= ActionType.GiveFixed;
        newLog.value= _amount;
        newLog.time= now;
        newLog.endTime= CONTRACT_ENDTIME;
        newLog.status= false;
        log[_to].push(newLog);
        emit giveFixedSuccess(_to);
    }
    
    function getBack(address _from) onlyOwner public {
        require(now < CONTRACT_ENDTIME);
        uint256 getBackTotal= 0;
        for (uint256 i= 0; i < log[_from].length; i++) 
        if ((!log[_from][i].status) && (log[_from][i].endTime > now)){
            getBackTotal.add(log[_from][i].value);
            log[_from][i].status= true;
        }
        totalAmount.add(getBackTotal);
        
        LogAtribute memory newLog;
        newLog.action= ActionType.GetBack;
        newLog.value= getBackTotal;
        newLog.time= now;
        newLog.endTime= CONTRACT_ENDTIME;
        newLog.status= true;
        log[_from].push(newLog);
        
        emit getBackSuccess(getBackTotal);
    }
    
    //Members Functions
    
    function withdrawUnlockedAmount() onlyMember public {
        address _address= msg.sender;
        uint256 unlockedAmount= 0;
        for (uint256 i= 0; i < log[_address].length; i++) 
        if ((!log[_address][i].status) && (log[_address][i].endTime < now)){
            if ((log[_address][i].action == ActionType.GiveFixed) || (log[_address][i].action == ActionType.GiveBonus)){
                unlockedAmount.add(log[_address][i].value);
                log[_address][i].status= true;
            }
        }
        require(unlockedAmount > 0);
        
        LogAtribute memory newLog;
        newLog.action= ActionType.Withdraw;
        newLog.value= unlockedAmount;
        newLog.time= now;
        newLog.endTime= CONTRACT_ENDTIME;
        newLog.status= true;
        log[_address].push(newLog);
        msg.sender.transfer(unlockedAmount);
        emit unlockedWithdraw(_address, unlockedAmount);
    }
    
    function getLogs(address _address) public view returns(uint256[], uint256[], uint256[], uint256[], bool[]) {
        require(member[_address].exist);
        bool access= (owner == msg.sender) || (_address == msg.sender);
        require(access);
        uint256[] memory action;
        uint256[] memory value;
        uint256[] memory time;
        uint256[] memory endTime;
        bool[] memory status;
        for (uint256 i= 0; i < log[_address].length; i++) {
            action[i]= uint256(log[_address][i].action);
            value[i]= log[_address][i].value;
            time[i]= log[_address][i].time;
            endTime[i]= log[_address][i].endTime;
            status[i]= log[_address][i].status;
        }
        return (action, value, time, endTime, status);
    }
    
}