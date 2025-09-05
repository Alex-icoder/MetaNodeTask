//测试辅助
const {ethers} = require("hardhat");
async function increase(sec){
  await ethers.provider.send("evm_increaseTime",[sec]);
  await ethers.provider.send("evm_mine",[]);
}
module.exports = {increase};