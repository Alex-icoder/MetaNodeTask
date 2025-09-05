// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockERC20 {
    string public name = "MockToken";
    string public symbol = "MKT";
    uint8 public decimals = 18;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);

    function mint(address to,uint256 amount) external {
        balanceOf[to]+=amount;
        emit Transfer(address(0),to,amount);
    }
    function approve(address spender,uint256 amount) external returns(bool){
        allowance[msg.sender][spender]=amount;
        emit Approval(msg.sender,spender,amount);
        return true;
    }
    function transfer(address to,uint256 amount) external returns(bool){
        _transfer(msg.sender,to,amount);
        return true;
    }
    function transferFrom(address from,address to,uint256 amount) external returns(bool){
        uint256 a=allowance[from][msg.sender];
        require(a>=amount,"allowance");
        allowance[from][msg.sender]=a-amount;
        _transfer(from,to,amount);
        return true;
    }
    function _transfer(address f,address t,uint256 a) internal {
        require(balanceOf[f]>=a,"bal");
        balanceOf[f]-=a;
        balanceOf[t]+=a;
        emit Transfer(f,t,a);
    }
}