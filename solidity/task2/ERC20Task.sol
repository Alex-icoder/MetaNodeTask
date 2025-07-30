// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

/**
* 基于ERC20标准的代币合约
*/
contract ERC20TokenTask is IERC20Metadata { 
    //代币基本信息
    string _name; 
    string _symbol;
    uint8  _decimals;
    uint  _totalSupply;
    
    //合约所有者
    address public _owner; 

    //余额映射
    mapping(address => uint) balances;
    //授权映射：owner => spender => amount
    mapping(address => mapping(address => uint)) approves;


    /**
    * _name_ 代币名称
    * _symbol_ 代币符号
    * _decimals_ 小数位数
    * _totalSupply_ 供应量
    */
    constructor(string memory _name_,string memory _symbol_,uint8 _decimals_,uint _totalSupply_) {
        _name = _name_;
        _symbol = _symbol_;
        _decimals = _decimals_;
        _owner = msg.sender;

        _totalSupply = _totalSupply_ * 10 ** _decimals_; 
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
         return _transferFrom(msg.sender,to,amount);
    }

    function approve(address spender, uint256 amount) external returns(bool){
         _approve(msg.sender, spender, amount);
         return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
         address spender = msg.sender;
         uint256 currentAllowance = approves[from][spender];
         require(currentAllowance >= amount,"ERC20: insufficient allowance");

         _approve(from, spender, currentAllowance - amount);
         return _transferFrom(from,to,amount);
    }


    function balanceOf(address account) external view returns (uint256) {
         return balances[account];
    }

    function totalSupply() external view returns (uint256) {
         return _totalSupply;
    }

    /**
     * @dev 查询授权额度
     * @param owner 代币所有者
     * @param spender 被授权者
     * @return 授权额度
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return approves[owner][spender];
    }

    function _transferFrom(address from, address to, uint256 amount) internal  returns (bool) {
        require(from != address(0),"ERC20: transfer from the zero address");
        require(to != address(0),"ERC20: transfer to the zero address");

        require(balances[from] >= amount,"ERC20:transfer amount exceeds balance" );
         balances[from] -= amount;
         balances[to] += amount;
         emit Transfer(from, to, amount);
         return true;
    }

    /**
     * @dev 内部授权函数
     * @param owner_ 代币所有者
     * @param spender 被授权者
     * @param amount 授权数量
     */
    function _approve(address owner_,address spender,uint256 amount) internal   {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0),"ERC20: approve to the zero address");
        require(approves[owner_][spender] == 0,"ERC20: Spender is approved");

        approves[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

}