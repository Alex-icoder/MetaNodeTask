package main

import "fmt"

type stack []rune

func (s *stack) push(value rune) {
	*s = append(*s, value)
}

func (s *stack) pop() (rune, bool) {
	if s.isEmpty() {
		return 0, false
	}
	index := len(*s) - 1
	element := (*s)[index]
	*s = (*s)[:index]
	return element, true
}

func (s *stack) peek() (rune, bool) {
	if s.isEmpty() {
		return 0, false
	}
	return (*s)[len(*s)-1], true
}

func (s *stack) isEmpty() bool {
	return len(*s) == 0
}

func (s *stack) size() int {
	return len(*s)
}

// 字符串
func main_string() {
	// 测试用例
	fmt.Println(isValid("()[]{}")) // 输出: true
	fmt.Println(isValid("([)]"))   // 输出: false
}

func isValid(s string) bool {
	stack := stack{}
	mapValid := map[rune]rune{
		')': '(',
		']': '[',
		'}': '{',
	}
	for _, char := range s {
		if char == '(' || char == '[' || char == '{' {
			stack.push(char)
		} else if val, ok := mapValid[char]; ok {
			popped, ok := stack.pop()
			if !ok || popped != val {
				return false
			}
		}
	}
	return stack.isEmpty()
}
