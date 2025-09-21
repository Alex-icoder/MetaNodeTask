// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 引入 OpenZeppelin ERC20 标准合约
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 接口：流动性池交互（如Uniswap V2 Router）
interface IUniswapV2Router {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
}

contract MemeToken is ERC20, Ownable {
    // 代币税相关变量
    uint256 public taxRate; // 税率，单位为百分比（如5表示5%）
    address public taxRecipient; // 税收接收地址

    // 交易限制相关变量
    uint256 public maxTxAmount; // 单笔最大交易额度
    mapping(address => uint256) public dailyTxCount; // 每日交易次数统计
    mapping(address => uint256) public lastTxDay; // 记录最后交易日期
    uint256 public maxDailyTx; // 每日最大交易次数

    // 流动性池路由器地址
    IUniswapV2Router public router;

    // 事件
    event TaxRateUpdated(uint256 newRate);
    event TaxRecipientUpdated(address newRecipient);
    event MaxTxAmountUpdated(uint256 newMaxTx);
    event MaxDailyTxUpdated(uint256 newMaxCount);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_,
        uint256 taxRate_,
        address taxRecipient_,
        address router_
    ) ERC20(name_, symbol_) {
        _mint(msg.sender, initialSupply_);
        taxRate = taxRate_;
        taxRecipient = taxRecipient_;
        maxTxAmount = initialSupply_ / 100; // 默认单笔最大为总供应量的1%
        maxDailyTx = 10; // 默认每日最多10笔
        router = IUniswapV2Router(router_);
    }

    // ******** 代币转账重写，加入税收和限制逻辑 ********
    function _transfer(address from, address to, uint256 amount) internal override {
        require(amount <= maxTxAmount, "Exceeds max tx amount");

        // 获取今天的日期（UTC 0点为界，以区块时间为准）
        uint256 today = block.timestamp / 1 days;
        if (lastTxDay[from] < today) {
            dailyTxCount[from] = 0;
            lastTxDay[from] = today;
        }
        require(dailyTxCount[from] < maxDailyTx, "Exceeds daily tx limit");
        dailyTxCount[from] += 1;

        // 税收逻辑
        uint256 taxAmount = (amount * taxRate) / 100;
        uint256 sendAmount = amount - taxAmount;

        // 税收转给税收地址
        super._transfer(from, taxRecipient, taxAmount);
        // 剩余部分转给收款人
        super._transfer(from, to, sendAmount);
    }

    // ******** 管理员功能：修改参数 ********
    function setTaxRate(uint256 newRate) external onlyOwner {
        require(newRate <= 20, "Tax too high");
        taxRate = newRate;
        emit TaxRateUpdated(newRate);
    }

    function setTaxRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "Invalid address");
        taxRecipient = newRecipient;
        emit TaxRecipientUpdated(newRecipient);
    }

    function setMaxTxAmount(uint256 newMaxTx) external onlyOwner {
        require(newMaxTx > 0, "Must be positive");
        maxTxAmount = newMaxTx;
        emit MaxTxAmountUpdated(newMaxTx);
    }

    function setMaxDailyTx(uint256 newMaxCount) external onlyOwner {
        require(newMaxCount > 0, "Must be positive");
        maxDailyTx = newMaxCount;
        emit MaxDailyTxUpdated(newMaxCount);
    }

    // ******** 流动性池交互（Uniswap举例） ********
    // 添加流动性（需要提前 approve 合约转账）
    function addLiquidity(uint amountToken, uint amountETHMin, uint deadline) external payable onlyOwner {
        _approve(address(this), address(router), amountToken);
        router.addLiquidityETH{value: msg.value}(
            address(this),
            amountToken,
            0,
            amountETHMin,
            owner(),
            deadline
        );
    }

    // 移除流动性
    function removeLiquidity(uint liquidity, uint amountTokenMin, uint amountETHMin, uint deadline) external onlyOwner {
        router.removeLiquidityETH(
            address(this),
            liquidity,
            amountTokenMin,
            amountETHMin,
            owner(),
            deadline
        );
    }

    // 接收 ETH
    receive() external payable {}
}