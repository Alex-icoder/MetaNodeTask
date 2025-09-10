package task1

import (
	"context"
	"crypto/ecdsa"
	"dapp/task/task1/myCounter"
	"fmt"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"log"
	"math/big"
)

// 合约代码生成
func GenerateContractCode() {
	privateKey := "f18c6d819443d59ccf01e33d2a6aedc2047e02e55930b40add0bcae22bd0345"
	//部署合约
	var contractAddr string
	contractAddr = deploy(privateKey)
	//执行合约
	execute(contractAddr, privateKey)
}

func deploy(privateKeyStr string) (contractAddr string) {
	client, err := ethclient.Dial("https://sepolia.infura.io/v3/cfca4096ab1b471c990e5b5042730b77")
	if err != nil {
		log.Fatal(err)
	}

	privateKey, err := crypto.HexToECDSA(privateKeyStr)
	if err != nil {
		log.Fatal(err)
	}

	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal("cannot assert type: publicKey is not of type *ecdsa.PublicKey")
	}

	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)
	nonce, err := client.PendingNonceAt(context.Background(), fromAddress)
	if err != nil {
		log.Fatal(err)
	}

	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	chainId, err := client.NetworkID(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	auth, err := bind.NewKeyedTransactorWithChainID(privateKey, chainId)
	if err != nil {
		log.Fatal(err)
	}
	auth.Nonce = big.NewInt(int64(nonce))
	auth.Value = big.NewInt(0)     // in wei
	auth.GasLimit = uint64(300000) // in units
	auth.GasPrice = gasPrice
	//部署合约
	address, tx, instance, err := myCounter.DeployMyCounter(auth, client)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("合约地址：", address.Hex())
	fmt.Println("交易哈希：", tx.Hash().Hex())
	_ = instance
	return address.Hex()
}

func execute(contractAddr string, fromPrivateKey string) {
	client, err := ethclient.Dial("https://sepolia.infura.io/v3/cfca4096ab1b471c990e5b5042730b77")
	if err != nil {
		log.Fatal(err)
	}
	contract, err := myCounter.NewMyCounter(common.HexToAddress(contractAddr), client)
	if err != nil {
		log.Fatal(err)
	}
	privateKey, err2 := crypto.HexToECDSA(fromPrivateKey)
	if err2 != nil {
		log.Fatal(err2)
	}
	chainID, err3 := client.NetworkID(context.Background())
	if err3 != nil {
		log.Fatal(err3)
	}
	auth, err4 := bind.NewKeyedTransactorWithChainID(privateKey, chainID)
	if err4 != nil {
		log.Fatal(err4)
	}
	// 获取gasPrice并增加10%避免交易被拒
	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		log.Fatal(err)
	}
	auth.GasPrice = new(big.Int).Mul(gasPrice, big.NewInt(11))
	auth.GasPrice = auth.GasPrice.Div(auth.GasPrice, big.NewInt(10))
	tx, err5 := contract.Increment(auth)
	if err5 != nil {
		log.Fatal(err5)
	}
	fmt.Println("执行合约 tx hash:", tx.Hash().Hex())
	//查询调用结果
	callOpt := &bind.CallOpts{Context: context.Background()}
	valueInContract, err := contract.Counter(callOpt)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("执行合约后，counter值为：", valueInContract)
}
