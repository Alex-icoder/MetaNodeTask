package main

import "fmt"

func main_twoSum() {
	nums := []int{3, 3}
	target := 6
	fmt.Println(twoSum(nums, target))
}

func twoSum(nums []int, target int) []int {
	if len(nums) == 0 {
		return []int{}
	}
	for index, elem := range nums {
		if index == len(nums)-1 {
			break
		}
		other := target - elem
		for i := index + 1; i < len(nums); i++ {
			if other == nums[i] {
				return []int{index, i}
			}
		}

	}
	return []int{}
}
