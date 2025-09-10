package task1

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"log"
	"math/big"
)

// 区块链读写
func Main_blockchain_readAndWrite() {
	// 查询指定区块号的区块信息
	number := int64(5671744)
	queryBlockByNumber(number)
	// 发送以太币交易
	fromPrivateKey := "f18c6d819443d59ccf01e33d2a6aedc2047e02e55930b40add0bcae22bd04434"
	toAddressHex := "0x3b83fBd8e9b37c126f6944e057d8c5dFA5E140e0"
	valueInWei := int64(500_000_000_000_000_000) //0.5 eth
	transactETH(fromPrivateKey, toAddressHex, valueInWei)
}

func queryBlockByNumber(number int64) {
	client, err := ethclient.Dial("https://sepolia.infura.io/v3/cfca4096ab1b471c990e5b5042730b77")
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("获取指定区块号的区块信息,当前区块号：", number)
	blockNumber := big.NewInt(number)
	header, err := client.HeaderByNumber(context.Background(), blockNumber)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("区块头信息如下：")
	fmt.Println("区块号：", header.Number.Uint64())
	fmt.Println("时间戳：", header.Time)
	fmt.Println("难度：", header.Difficulty.Uint64())
	fmt.Println("哈希值：", header.Hash().Hex())
	block, err2 := client.BlockByNumber(context.Background(), blockNumber)
	if err2 != nil {
		log.Fatal(err2)
	}
	fmt.Println("完整区块信息如下：")
	fmt.Println("区块号:", block.Number().Uint64())
	fmt.Println("时间戳:", block.Time())
	fmt.Println("区块难度：", block.Difficulty().Uint64())
	fmt.Println("区块的哈希：", block.Hash().Hex())
	fmt.Println("区块的交易列表长度：", len(block.Transactions()))
	count, err := client.TransactionCount(context.Background(), block.Hash())
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("区块的交易量", count)
}

func transactETH(fromPrivateKey string, toAddressHex string, valueInWei int64) {
	client, err := ethclient.Dial("https://sepolia.infura.io/v3/cfca4096ab1b471c990e5b5042730b77")
	if err != nil {
		log.Fatal(err)
	}

	privateKey, err := crypto.HexToECDSA(fromPrivateKey)
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
	fmt.Println("nonce:", nonce)
	value := big.NewInt(valueInWei) // in wei
	gasLimit := uint64(21000)       // in units
	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	toAddress := common.HexToAddress(toAddressHex)
	tx := types.NewTx(&types.LegacyTx{
		Nonce:    nonce,
		To:       &toAddress,
		Value:    value,
		Gas:      gasLimit,
		GasPrice: gasPrice,
		Data:     nil,
	})

	chainID, err := client.NetworkID(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), privateKey)
	if err != nil {
		log.Fatal(err)
	}

	err = client.SendTransaction(context.Background(), signedTx)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("本次交易的哈希值: %s", signedTx.Hash().Hex())
}
