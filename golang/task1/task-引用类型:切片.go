package main

import (
	"fmt"
	"sort"
)

func main_slice() {
	nums := []int{0, 0, 1, 1, 1, 2, 2, 3, 3, 4}
	fmt.Println(removeDuplicates(nums))
	intervals := [][]int{{1, 5}, {1, 3}, {6, 9}, {8, 10}, {15, 18}}
	fmt.Println(merge(intervals))
}

func removeDuplicates(nums []int) int {
	if len(nums) == 0 {
		return 0
	}
	i := 1
	for j := 1; j < len(nums); j++ {
		if nums[j] != nums[i-1] {
			nums[i] = nums[j]
			i++
		}
	}
	return i
}

func merge(intervals [][]int) [][]int {
	if len(intervals) == 0 {
		return nil
	}
	sort.Slice(intervals, func(i, j int) bool {
		return intervals[i][0] < intervals[j][0]
	})
	array := [][]int{intervals[0]}
	for i := 1; i < len(intervals); i++ {
		current := intervals[i]
		last := array[len(array)-1]
		// 如果当前区间起始位置 <= 上一个区间的结束位置，则合并
		if current[0] <= last[1] {
			// 更新结束位置为两者中较大的值
			if current[1] > last[1] {
				last[1] = current[1]
			}
		} else {
			// 无重叠，直接加入结果集
			array = append(array, current)
		}
	}
	return array
}
