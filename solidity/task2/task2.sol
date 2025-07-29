// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Metadata {
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);

   
    function totalSupply() external view returns (uint256);

    //查询账户余额
    function balanceOf(address account) external view returns (uint256);

    //转账
    function transfer(address to, uint256 value) external returns (bool);

   
    function allowance(address owner, address spender) external view returns (uint256);

    //授权额度
    function approve(address spender, uint256 value) external returns (bool);

    //代扣转账
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract ERC20Task is IERC20Metadata {
    string _name;
    // string _symbol;
    // uint8  _decimals;
    uint  _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) approves;

    constructor(string memory _name_,uint _totalSupply_) {
        _name = _name_;
        _totalSupply = _totalSupply_;
        balances[msg.sender] += _totalSupply_;
        emit Transfer(address(0), msg.sender, _totalSupply_);
    }

    function getName() external view returns (string memory){
        return _name;
    }


    function transfer(address to, uint256 amount) external returns (bool) {
         return _transferFrom(msg.sender,to,amount);
     }

      function approve(address spender, uint256 amount) external returns(bool){
         require(approves[msg.sender][spender] == 0,"ERC20: Spender is approved");
         approves[msg.sender][spender] += amount;
         emit Approval(msg.sender,spender, amount);
         return true;
      }

      function transferFrom(address from, address to, uint256 amount) external returns (bool) {
         require(approves[from][msg.sender] > 0,"Out of approval funds");
         approves[from][msg.sender] -= amount;
         return _transferFrom(from,to,amount);
      }

      function _transferFrom(address from, address to, uint256 amount) internal  returns (bool) {
        require(balances[from] >= amount,"ERC20:Out of funds" );
         balances[from] -= amount;
         balances[to] += amount;
         emit Transfer(from, to, amount);
         return true;
      }

      function balanceOf(address account) external view returns (uint256) {
         return balances[account];
      }

       function totalSupply() external view returns (uint256) {
         return _totalSupply;
       }

    function allowance(address owner, address spender) external view returns (uint256) {
        return approves[owner][spender];
    }

}