package main

import "fmt"

// 控制流程
func main_onlyOnceNumber() {
	array := [...]int{1, 1, 2, 2, 3, 4, 4, 5, 5}
	elem := onlyOnceNumber(array[:])
	if elem < 0 {
		fmt.Println("只出现了一次的元素不存在")
	} else {
		fmt.Println("只出现了一次的元素是:", elem)
	}
}

func onlyOnceNumber(slice []int) int {
	if len(slice) == 0 {
		return -1
	}
	mapCount := make(map[int]int)
	for _, elem := range slice {
		v, exist := mapCount[elem]
		if !exist {
			mapCount[elem] = 1
		} else {
			mapCount[elem] = v + 1
		}
	}
	for k, v := range mapCount {
		if v == 1 {
			return k
		}
	}
	return -1
}
