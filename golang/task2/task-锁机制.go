package main

import (
	"fmt"
	"sync"
	"sync/atomic"
	"time"
)

type counterWithLock struct {
	count int
	lock  sync.Mutex
}

func (c *counterWithLock) increment() {
	c.lock.Lock()
	defer c.lock.Unlock()
	c.count++
}

func (c *counterWithLock) getCount() int {
	c.lock.Lock()
	defer c.lock.Unlock()
	return c.count
}

func main_锁机制() {
	//题目1
	counter := counterWithLock{}
	for range 10 {
		go func() {
			for range 1000 {
				counter.increment()
			}
		}()
	}
	time.Sleep(5 * time.Second)
	fmt.Printf("Final count: %d\n", counter.getCount())
	//题目2
	counterWithNoLock := counterWithNoLock{}
	var wg sync.WaitGroup
	wg.Add(10)
	for range 10 {
		go func(w *sync.WaitGroup) {
			defer wg.Done()
			for range 1000 {
				counterWithNoLock.counter.Add(1)
			}
		}(&wg)
	}
	wg.Wait()
	fmt.Printf("Final count without lock: %d\n", counterWithNoLock.counter.Load())
}

type counterWithNoLock struct {
	counter atomic.Int32
}
