package main

import (
	"fmt"
	"sync"
	"time"
)

func sendMessage(ch chan<- int, wg *sync.WaitGroup) {
	defer wg.Done()
	for i := 1; i <= 10; i++ {
		ch <- i
		fmt.Println("Message sent:", i)
		time.Sleep(time.Duration(i) * 100 * time.Millisecond) // 模拟发送延迟
	}
	close(ch)
}

func receiveMessage(ch <-chan int, wg *sync.WaitGroup) {
	defer wg.Done()
	for msg := range ch {
		fmt.Println("Message received:", msg)
	}
}

func main_Channel() {
	//题目1
	ch := make(chan int)
	var wg sync.WaitGroup
	wg.Add(2)
	go sendMessage(ch, &wg)
	go receiveMessage(ch, &wg)
	wg.Wait()
	fmt.Println("All messages processed")

	//题目2
	ch2 := make(chan int, 3)
	var wg2 sync.WaitGroup
	wg2.Add(1)
	go sendMessage(ch2, &wg2)
	wg2.Add(1)
	go receiveMessage(ch2, &wg2)
	wg2.Wait()
	fmt.Println("All messages processed second time")
}
