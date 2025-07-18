package main

import "fmt"

type Employee struct {
	ID         int
	Name       string
	Department string
	Salary     float64
}

func main_使用SQL扩展库进行查询() {
	db := getSqlx()
	var employees []Employee
	err := db.Select(&employees, "select id,name,department,salary from employees where department = ?", "技术部")
	if err != nil {
		panic(err)
	}
	fmt.Println("技术部员工信息查询结果：", employees)

	var employee Employee
	errs := db.Get(&employee, "select id,name,department,salary from employees  order by salary desc limit 1")
	if errs != nil {
		panic(errs)
	}
	fmt.Println("薪水最高的员工信息查询结果:", employee)
}

func main_实现类型安全映射() {
	db := getSqlx()
	var books []Book
	err := db.Select(&books, "select id,title,author,price from books where price > ?", 50)
	if err != nil {
		panic(err)
	}
	fmt.Println("查询到的价格大于50元的书籍数量为:", len(books))
	for _, book := range books {
		fmt.Printf("ID:%d,书名:%s,作者:%s,价格:%.2f\n", book.ID, book.Title, book.Author, book.Price)
	}
}

type Book struct {
	ID     int
	Title  string
	Author string
	Price  float64
}
