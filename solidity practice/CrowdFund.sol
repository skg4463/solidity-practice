pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount) external;
}

contract CrowdFund {
    address public beneficiary; //수익자 
    uint public fundingGoal; //청약목표
    uint public deadline; //마감시간
    uint public price; //
    uint public amountRaised; //모금총액

    token public tokenReward; //interface token 호출하여 tokenReward에 배정
    mapping(address => uint256) public balanceOf;
    bool public fundingGoalReached = false;
    bool public crowdsaleClosed = false;
    //public 형 상태변수는 그에 맞는 getter 함수가 자동 생성되어 상태전이과정을 볼 수 있음

    event GoalReached(address beneficiaryAddress, uint amountRaisedValue);
    event FundTransfer(address backer, uint amount, bool isContribution);

    constructor(address ifSuccessfulSendTo, //청약 성공할 경우 보낼 곳(받는사람)
                uint fundingGoalInEthers, //ether goal
                uint durationInMinutes, //모금기간
                uint etherCostOfEachToken, //토근-이더 교환비율
                address addressOfTokenUsedAsReward) public { //token contract address
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = etherCostOfEachToken * 1 ether;
        tokenReward = token(addressOfTokenUsedAsReward);
    }

    function c() external payable{
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount / price);
        emit FundTransfer(msg.sender, amount, true); //기부 ok
    }

    modifier afterDeadline(){ if(now >= deadline) _; } //function modifier

    function checkGoalReached() external afterDeadline { //달성완료
        if(amountRaised >= fundingGoal){
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }
    
    function safeWithdrawal() external afterDeadline { // 모금기간이 지낫는데 달성하지 못했을 때
        if(!fundingGoalReached){
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if(amount > 0){ //amount가 잇고
                if(msg.sender.send(amount)){ 
                    emit FundTransfer(msg.sender, amount, false); //기부 no
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }
        if(fundingGoalReached && beneficiary == msg.sender){
            if(beneficiary.send(amountRaised)){
                emit FundTransfer(beneficiary, amountRaised, false);
            } else {
                fundingGoalReached = false;
            }
        }
    }

    functon() public payable{
        goalAmount -= int(msg.value);

        if( goalAmount > 0) {
            if(fundAddress.call(bytes4(keccak256("withdrawBalance()")))){
                WithdrawBalance("Succeeded in fallback", msg.gas);
            } else {
                WithdrawBalance("failed in fallback",msg.gas);
            }
        }
    }

    function deposit() public payable {
        if(fundAddress.call.value(msg.sender).gas(msg.gas)
            bytes4(keccak256("addToBalance()"))) == false) {
                revert();
            }
    }

}