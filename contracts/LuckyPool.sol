pragma solidity ^0.4.17;

import './SafeMath.sol';

contract LuckyPool {
    using SafeMath for uint256;
    
    uint256 public constant DICE_DURATION= 20;
    uint256 public constant REFUND_PERCENT= 98;
    uint256 public constant REWARD_PERCENT= 98;
    uint256 public constant INACTIVE_DURATION= 60*60*24; //24 hours inactive room, locked but nobody calls getWinner() 

    uint256 public pendingAmount= 0;

    enum PlayerState {
        Free,
        Joined,
        Verified,
        Failed
    }

    struct RoomAtribute {
        address[] playerAddress;
        uint256 endTime;
        bool locked;
    }

    struct RoomIds{
        uint256 mul;
        uint256 amount;
        uint256 number;
    }

    struct Players {
        RoomIds inRoom;
        uint256 order;
        PlayerState state;
        bytes32[] hstring;
        uint256[] randomNumbers;
    }

    address public owner;

    uint256 public ownerPercent;
    uint256 public verifyDuration;

    uint256[] public betAmount;
    uint256[] public betMul;
    
    mapping(uint256 => bool) public amountExist;
    mapping(uint256 => bool) public mulExist;
    
    mapping(uint256 => mapping(uint256 => uint256)) public roomNumber;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => RoomAtribute))) public room;

    mapping(address => Players) public player;
    
   // uint256[2][] public roomNumber; //amount mul

//Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
//Events
    event ownerWithdrawSuccess(uint256 _withdrawAmount);
    event roomLocked(uint256 _amount, uint256 _mul, uint256 _number);
    event freeRoom(uint256 _amount, uint256 _mul, uint256 _number);
    event joinSuccess(address _from);
    event refundSuccess(address _to,uint256 amount);
    event leaveSuccess(address _from);
    event loserNotify(address _loserAddress, uint256 _round);
    event winnerNotify(address _winnerAddress);
//////////////Functions

//testing Functions

    function _showRandomNumber(address a) public view returns (uint256[]) {
        return player[a].randomNumbers;
    }
    
    function _showState(address a) public view returns (PlayerState) {
        return player[a].state;
    }

    function _initForAdmin() onlyOwner public { //tested
        addBetAmount(1);
        addBetAmount(2);
        addBetAmount(5);
        
        addBetMul(2);
        addBetMul(4);
        addBetMul(8);
        
    }
    
    function showRoom(uint256 amount, uint256 mul, uint256 number) public view returns(bool) {
        return room[amount][mul][number].locked;
    }
    
    function showReward(uint256 _amount, uint256 _mul) public view returns(uint256) {
        uint256 reward= _amount.mul(_mul).etherToWei().div(100).mul(REWARD_PERCENT);
        return reward;
    }
    
    function showHash(uint256 s) view public  returns(bytes32){
        return keccak256(s.toBytes());
    }
    
    function _getBetAmountLength() public view returns(uint256) {
        return betAmount.length;
    }
    
    function _getBetMulLength() public view returns(uint256) {
        return betMul.length;
    }

    function _getDefaultEnum() public view returns (PlayerState) {
        return player[msg.sender].state;
    }
    
//Owner's Functions

    constructor () public{ //tested
        owner = msg.sender;
    }

    function addBetAmount(uint256 _newAmount) onlyOwner public { //tested
        require(!amountExist[_newAmount]);
        betAmount.push(_newAmount);
        amountExist[_newAmount]= true;
    }

    function addBetMul(uint256 _newMul) onlyOwner public { //tested
        require(!mulExist[_newMul]);
        betMul.push(_newMul);
        mulExist[_newMul]= true;
    }

    function getBalance() public view onlyOwner returns(uint256) { //tested
        return address(this).balance;
    }

    function ownerWithdraw() public onlyOwner { //tested
        cleanInactiveRooms();
        uint256 withdrawAmount= address(this).balance.sub(pendingAmount);
        owner.transfer(withdrawAmount);
        emit ownerWithdrawSuccess(withdrawAmount);
    }

//to clean Rooms, that nobody claim reward
    function cleanInactiveRooms() public onlyOwner {
        for (uint256 i= 0; i < betAmount.length; i++)
        for (uint256 j= 0; j < betMul.length; j++) {
            uint256 _amount= betAmount[i];
            uint256 _mul= betMul[j];        
            for (uint256 _number= 0; _number < roomNumber[_amount][_mul]; _number++){
                uint256 endTime= room[_amount][_mul][_number].endTime;
                bool isLocked= room[_amount][_mul][_number].locked;
                if ((isLocked) && (now.sub(endTime) > INACTIVE_DURATION)) {
                    cleanRoom(_amount, _mul, _number);
                }
            }
        }
    }

    function() payable public { } //fallback function

//Players's Functions

    function getFirstFreeRoom(uint256 _amount, uint256 _mul) public view returns(uint256) {
        for (uint256 i= 1; i <= roomNumber[_amount][_mul]; i++)
        //room still open
        if (!room[_amount][_mul][i].locked) return i;
        return roomNumber[_amount][_mul]; // create new room if all rooms full
    }
    
    function hashVerify(bytes _randomNumber, bytes32 _hashString) private pure returns(bool){
        return (keccak256(_randomNumber) == _hashString);
    }
    
    //players send secretNumbers with this func to verify
    // Check only 1 time => Verified or Failed
    function checkRandomNumbers(uint256[] _randomNumbers) public returns(bool) {
        require(player[msg.sender].state == PlayerState.Joined); 
        RoomIds storage roomId=player[msg.sender].inRoom;
        uint256 endTime= room[roomId.amount][roomId.mul][roomId.number].endTime;
        require(now.sub(endTime) < DICE_DURATION);
        // Check if room locked;
        require(room[roomId.amount][roomId.mul][roomId.number].locked);
        require(_randomNumbers.length == player[msg.sender].hstring.length);
        
        for (uint256 i= 0; i < _randomNumbers.length - 1; i++) 
        if (!hashVerify(_randomNumbers[i].toBytes(), player[msg.sender].hstring[i])) {
            player[msg.sender].state= PlayerState.Failed;
            return false;
        }
        
        player[msg.sender].randomNumbers= _randomNumbers;
        player[msg.sender].state= PlayerState.Verified;
        return true;
    }
    
    function pairWinner(address a1, address a2, uint256 round) private returns (address) {
        address winnerAddress;
        if (player[a1].state != PlayerState.Verified) winnerAddress= a2;
        if (player[a2].state != PlayerState.Verified) winnerAddress= a1;
        //both Verified
        if ((player[a1].state == PlayerState.Verified) && (player[a1].state != PlayerState.Verified)) {
            winnerAddress= a2;
            if ((player[a1].randomNumbers[round] + player[a2].randomNumbers[round]) % 2 == 0) 
            winnerAddress= a1;
        }
        address loserAddress= a1;
        if (winnerAddress == loserAddress) loserAddress=a2;
        freePlayer(loserAddress); //kick loser out of room
        emit loserNotify(loserAddress, round);
        return winnerAddress;
    }
    
    function fighting(address[] roundPlayers) private returns(address){
        uint256 i;
        uint256 round;
        uint256 l=roundPlayers.length;
        while (l>1) {
            i=0;
            round= roundPlayers.length.log() - 1;
            
            while (i < roundPlayers.length) {
                address winnerAddress = pairWinner(roundPlayers[i], roundPlayers[i+1], round);
                roundPlayers[i / 2]= winnerAddress;
                i+= 2;
            }
            
            for (i= l/2; i < l; i++) {
                delete roundPlayers[i];
            }
            l=l/2;
        }
        
        return roundPlayers[0];
    }
    
    function didAllVerify(uint256 _amount, uint256 _mul, uint256 _number) private view returns(bool) {
        address[] memory addressList= room[_amount][_mul][_number].playerAddress;
        for (uint256 i= 0; i < addressList.length; i++) {
            if (player[addressList[i]].state == PlayerState.Joined) return false;
        }
        return true;
    }
    
    function getWinner() public payable{    //tested
        //require(player[msg.sender].exist);
        assert(player[msg.sender].state == PlayerState.Verified); //in a locked room and verified
        RoomIds storage roomId= player[msg.sender].inRoom;
        uint256 endTime= room[roomId.amount][roomId.mul][roomId.number].endTime;
        // if time for verify past or all players sent randomNumbers 
        //require((now.sub(endTime) > DICE_DURATION) || (didAllVerify(roomId.amount,roomId.mul,roomId.number))); 
        require(now.sub(endTime) > DICE_DURATION);
        address winnerAddress= fighting(room[roomId.amount][roomId.mul][roomId.number].playerAddress);
        bool nobodyVerified= (player[winnerAddress].state != PlayerState.Verified);
        uint256 reward= roomId.amount.mul(roomId.mul).etherToWei().div(100).mul(REWARD_PERCENT);
        if (!nobodyVerified) {
            winnerAddress.transfer(reward);
            emit winnerNotify(winnerAddress);
        } else emit loserNotify(winnerAddress, 0);
        cleanRoom(roomId.amount, roomId.mul, roomId.number);
        emit freeRoom(roomId.amount, roomId.mul, roomId.number);
    }
    
    function freePlayer(address playerAddress) private {
        player[playerAddress].state= PlayerState.Free;
        delete player[playerAddress].hstring;
        delete player[playerAddress].randomNumbers;
        pendingAmount.sub(player[playerAddress].inRoom.amount.etherToWei());
    }
    
    function cleanRoom(uint256 _amount, uint256 _mul, uint256 _number) private {
        room[_amount][_mul][_number].endTime= now;
        room[_amount][_mul][_number].locked= false;
        address[] storage pList= room[_amount][_mul][_number].playerAddress;
        for (uint256 i= 0; i < pList.length; i++) freePlayer(pList[i]);
        delete room[_amount][_mul][_number].playerAddress;
    }
    
    function lockRoom(uint256 _amount, uint256 _mul, uint256 _number) private { //tested
        room[_amount][_mul][_number].locked= true;
        room[_amount][_mul][_number].endTime= now;
        emit roomLocked(_amount, _mul, _number);
        //Players in this room wait for this emit to send their secret numbers
    }
    
    function leaveRoom() private {
        require(player[msg.sender].state == PlayerState.Joined);
        RoomIds storage inRoom= player[msg.sender].inRoom;
        //leave only if room still not locked
        require(!room[inRoom.amount][inRoom.mul][inRoom.number].locked);
        uint256 order= player[msg.sender].order;
        //l=length
        uint256 l= room[inRoom.amount][inRoom.mul][inRoom.number].playerAddress.length;
        address lastAddress= room[inRoom.amount][inRoom.mul][inRoom.number].playerAddress[l-1];
        room[inRoom.amount][inRoom.mul][inRoom.number].playerAddress[order]= lastAddress;
        delete room[inRoom.amount][inRoom.mul][inRoom.number].playerAddress[l-1]; 
        //remove last address in room
    }
    
    function joinRoom(uint256 _amount, uint256 _mul, uint256 _number, bytes32[] _hstring ) payable public {
        //can join direct without join joinQueue, check locked room
        address _from=msg.sender;
        assert(msg.value >= _amount.etherToWei());
        assert(player[msg.sender].state == PlayerState.Free);
        require(!room[_amount][_mul][_number].locked);
        require(_hstring.length == _mul.log()); // log _mul rounds to find the roundWinner
        uint256 _order= room[_amount][_mul][_number].playerAddress.length;
        player[_from].state= PlayerState.Joined;
        player[_from].hstring= _hstring;
        player[_from].order= _order;
        player[_from].inRoom.amount= _amount;
        player[_from].inRoom.mul= _mul;
        player[_from].inRoom.number= _number;
        
        room[_amount][_mul][_number].playerAddress.push(_from);
        emit joinSuccess(_from);
        pendingAmount.add(_amount.etherToWei());
        
        if (_order == _mul-1) lockRoom(_amount, _mul, _number);
    }
    
    function joinQueue(uint256 _amount, uint256 _mul, bytes32[] _hstring) external payable{ //tested
        require(amountExist[_amount]);
        require(mulExist[_mul]);
        require(msg.value >= _amount.etherToWei());
        uint256 _number= getFirstFreeRoom(_amount,_mul);
        joinRoom(_amount, _mul, _number, _hstring);
        //if room ready to Dice, lock room and emit
    }
    
    function leaveQueue() payable public { //tested
        //require(player[msg.sender].exist);
        require(player[msg.sender].state != PlayerState.Free);
        RoomIds storage inRoom= player[msg.sender].inRoom;
        require(!room[inRoom.amount][inRoom.mul][inRoom.number].locked); // Room locked, nobody can run
        uint256 refundAmount= inRoom.amount.etherToWei().div(100).mul(REFUND_PERCENT);
        require(refundAmount <= address(this).balance);
        leaveRoom();
        msg.sender.transfer(refundAmount);
        freePlayer(msg.sender);
        emit refundSuccess(msg.sender, refundAmount);
    }
   
}
