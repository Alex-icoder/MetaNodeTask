// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BeggingContract is ReentrancyGuard {
    event Donation(address indexed donor,uint256 amount,uint256 timestamp);
    event Withdraw(address indexed owner,uint256 amount,uint256 timeStamp);
    event timeRestrictionUpdate(uint256 startTime,uint256 endTime,bool enable);

    // 合约所有者
    address owner;
     // 合约总接收金额
    uint256 totalAmount;
    //记录每个捐赠者的捐赠金额
    mapping(address => uint) donates;
    // 记录所有捐赠者的地址（用于排行榜功能）
    address[] donors;
    // 捐赠开始和结束时间
    uint256 public donationStartTime;
    uint256 public donationEndTime;
    //是否启用时间限制
    bool  public timeRestrictionEnabled;

   


    modifier onlyOwner() {
        require(owner == msg.sender,"only owner can operate");
        _;
    }

    modifier withinTimeimit() {
        if(timeRestrictionEnabled) {
            require(block.timestamp >= donationStartTime && 
            block.timestamp <= donationEndTime,
            "Donation is not allowed at this time");
        }
        _;
    }

     constructor() {
        owner = msg.sender;
        donationStartTime = block.timestamp;
        donationEndTime = block.timestamp + 90 days;//默认90天
        timeRestrictionEnabled = false;
    }

    receive() external payable { }
    fallback() external payable { }


    //允许用户向合约发送以太币，并记录捐赠信息
    function donate() public  payable withinTimeimit returns(bool){
        require(msg.value > 0,"donor amount must be greater than zero");
        if (donates[msg.sender] == 0) {
            donors.push(msg.sender);
        }
        totalAmount += msg.value;
        donates[msg.sender] += msg.value;
        emit Donation(msg.sender,msg.value,block.timestamp);
        return true;
    }

    //允许合约所有者提取所有资金
    function withdraw() public payable onlyOwner nonReentrant returns(uint256) {
        uint256 balance = address(this).balance;
        require(balance > 0,"withdraw amount is zero");
        // (bool success, ) = payable(owner).call{value: address(this).balance}("");
        // require(success, "Withdraw failed");
        payable(owner).transfer(balance);
        return balance;
    }

    function getDonation(address donor) public view returns(uint) {
        return donates[donor];
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    //获取总的捐赠信息
    function getTotalInfo() public view returns(uint256,uint256) { 
        return (totalAmount,donors.length);
    }

    //获取捐赠排行榜前N名
    function getTopDonors(uint256 topN) public view returns(address[] memory topDonors,uint256[] memory topAmounts) {
        require(topN > 0 && topN <= donors.length,"Invalid topN value");
        //创建临时数组用于排序
        address[] memory tempDonors = new address[](donors.length);
        uint256[] memory tempAmounts = new uint256[](donors.length);
        // 复制数据
        for (uint256 i=0;i<donors.length;i++) {
            tempDonors[i] = donors[i];
            tempAmounts[i] = donates[donors[i]];
        }
        //冒泡排序-降序
        for (uint256 i=0;i<tempDonors.length-1;i++) {
            for (uint256 j=0;j<tempDonors.length-1-i;j++) {
                if (tempAmounts[j]<tempAmounts[j+1]) {
                    //交换金额和地址
                    uint256 tempAmount = tempAmounts[j];
                    tempAmounts[j] = tempAmounts[j+1];
                    tempAmounts[j+1] = tempAmount;

                    address tempDonor = tempDonors[j];
                    tempDonors[j] = tempDonors[j+1];
                    tempDonors[j+1] = tempDonor;
                }
            }
        }

        //获取前N名
        topDonors = new address[](topN);
        topAmounts = new uint256[](topN);
        for (uint256 i=0;i<topN;i++) {
           topDonors[i] = tempDonors[i];
           topAmounts[i] = tempAmounts[i];
        }
        return (topDonors,topAmounts);
    }

    //设置捐赠时间限制
    function setTimeRestriction(uint256 startTime,uint256 endTime,bool enable) public onlyOwner {
        require(startTime < endTime,"End time must be after start time");
        donationStartTime = startTime;
        donationEndTime = endTime;
        timeRestrictionEnabled = enable;
        emit timeRestrictionUpdate(startTime, endTime, enable);
    }

    //紧急停止捐赠功能
    function emergencyStop() public onlyOwner{
        timeRestrictionEnabled = true;
        donationEndTime = block.timestamp;
    }

    
}