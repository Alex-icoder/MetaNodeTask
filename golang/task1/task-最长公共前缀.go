package main

import "fmt"

func main_longestCommonPrefix() {
	str := [...]string{"flower", "flow", "flight"}
	fmt.Println(longestCommonPrefix(str[:]))
}

func longestCommonPrefix(slice []string) string {
	prefix := ""
	if len(slice) == 0 {
		return prefix
	}
	for i := 0; i < len(slice[0]); i++ {
		for j := 1; j < len(slice); j++ {
			if i == len(slice[j]) || slice[0][i] != slice[j][i] {
				return slice[0][:i]
			}
		}
	}
	return prefix
}
