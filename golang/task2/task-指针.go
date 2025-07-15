package main

import "fmt"

func add(i *int) int {
	return *i + 10
}

func multiply(slice []int) []int {
	for i := range slice {
		slice[i] *= 2
	}
	return slice
}

func main_指针() {
	//题目1
	var i int = 5
	j := add(&i)
	fmt.Printf("原值为：%d,新值为：%d\n", i, j)

	//题目2
	slice := []int{1, 2, 3, 4, 5}
	fmt.Println("切片元素乘以2后的结果为", multiply(slice))
}
