package main

import (
	"fmt"
	"strconv"
)

func main_addOne() {
	digits := []int{4, 3, 2, 2}
	fmt.Println(addOne(digits))
}

func addOne(num []int) []int {
	if len(num) == 0 {
		return []int{}
	}
	numStr := ""
	for _, v := range num {
		numStr += strconv.Itoa(v)
	}
	numUi64, err := strconv.ParseUint(numStr, 10, 32)
	if err != nil {
		panic(err)
	}
	numUi64 += 1
	numStr2 := strconv.FormatUint(numUi64, 10)
	array := []int{}
	for _, v := range numStr2 {
		char := string(v)
		charNum, err := strconv.Atoi(char)
		if err != nil {
			panic(err)
		}
		array = append(array, charNum)
	}
	return array
}
