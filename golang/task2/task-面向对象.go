package main

import "fmt"

type Shape interface {
	Area() float64
	Perimeter() float64
}

type Rectangle struct {
	width  float64
	height float64
}

func (r *Rectangle) Area() float64 {
	return r.width * r.height
}
func (r *Rectangle) Perimeter() float64 {
	return 2 * (r.width + r.height)
}

type Circle struct {
	radius float64
}

func (c *Circle) Area() float64 {
	return 3.14 * c.radius * c.radius
}

func (c *Circle) Perimeter() float64 {
	return 2 * 3.14 * c.radius
}

func main_面向对象() {
	//题目1
	shapes := []Shape{
		&Rectangle{width: 4, height: 5},
		&Circle{radius: 10},
	}
	for _, shape := range shapes {
		fmt.Printf("Area: %.2f, Perimeter: %.2f\n", shape.Area(), shape.Perimeter())
	}
	//题目2
	employee := Employee{
		EmployeeID: "E12345",
		Person: Person{
			Name: "John Doe",
			Age:  30,
		},
	}
	employee.PrintInfo()
}

type Person struct {
	Name string
	Age  int
}

type Employee struct {
	EmployeeID string
	Person
}

func (p Employee) PrintInfo() {
	fmt.Printf("Name: %s, Age: %d,EmployeeID:%s \n", p.Name, p.Age, p.EmployeeID)
}
