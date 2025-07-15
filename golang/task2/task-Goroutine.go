package main

import (
	"fmt"
	"sync"
	"time"
)

func main_Goroutine() {
	//题目1：
	go func() {
		for i := 1; i <= 10; i++ {
			if i%2 != 0 {
				fmt.Printf("协程1在打印1-10的奇数：%d\n", i)
			}
		}
	}()
	go func() {
		for i := 1; i <= 10; i++ {
			if i%2 == 0 {
				fmt.Printf("协程1在打印2-10的偶数：%d\n", i)
			}
		}
	}()
	time.Sleep(2 * time.Second)

	//题目2：
	tasks := []task{
		{1, func() {
			time.Sleep(100 * time.Millisecond)
			fmt.Println("task 1 executing")
		}},
		{
			2, func() {
				time.Sleep(200 * time.Millisecond)
				fmt.Println("task 2 executing")
			}},
		{
			3, func() {
				time.Sleep(150 * time.Millisecond)
				fmt.Println("task 3 executing")
			}},
	}

	var wg sync.WaitGroup
	wg.Add(len(tasks))
	for _, tsk := range tasks {
		go executeTask(tsk, &wg)
	}
	wg.Wait()
	fmt.Println("All tasks completed")
}

type task struct {
	id   int
	work func()
}

func executeTask(tsk task, wg *sync.WaitGroup) {
	defer wg.Done()
	start := time.Now()
	tsk.work()
	duration := time.Since(start)
	fmt.Printf("Task %d completed in %v\n", tsk.id, duration)
}
