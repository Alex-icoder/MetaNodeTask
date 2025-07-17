package main

import (
	"errors"
	"fmt"
	"gorm.io/gorm"
	"time"
)

type Student struct {
	ID        uint
	Name      string
	Age       uint8
	Grade     string
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index"`
}

func main_基本CRUD操作() {
	db := getGorm()
	err := db.AutoMigrate(&Student{})
	if err != nil {
		panic(err)
	}
	//插入记录
	student := &Student{Name: "张三", Age: 23, Grade: "三年级"}
	result := db.Create(student)
	if errs := result.Error; errs != nil {
		panic(errs)
	}
	fmt.Println("插入成功，ID:", student.ID)
	//查询
	var students []Student
	resultQuery := db.Where("AGE > 18").Find(&students)
	if errs := resultQuery.Error; errs != nil {
		panic(errs)
	}
	fmt.Printf("查询结果共[%d]条,分别为%v", len(students), students)
	//修改
	var errUpdate = db.Model(&Student{}).Where("name=?", "张三").Update("grade", "四年级").Error
	if errUpdate != nil {
		panic(errUpdate)
	}
	fmt.Println("修改成功")
	//删除-软删除
	resultSoft := db.Where("age < 15").Delete(&Student{})
	if errs := resultSoft.Error; errs != nil {
		panic(errs)
	}
	fmt.Println("软删除成功")
	//删除-永久删除
	resultHard := db.Unscoped().Where("age < ?", 15).Delete(&Student{})
	if errs := resultHard.Error; errs != nil {
		panic(errs)
	}
	fmt.Println("永久删除成功")
}

type Account struct {
	gorm.Model
	Name    string
	Balance float64
}

type Transaction struct {
	gorm.Model
	FromAccountId uint
	ToAccountId   uint
	Amount        float64
}

func main_事务语句() {
	db := getGorm()
	db.AutoMigrate(&Account{})
	db.AutoMigrate(&Transaction{})

	accounts := []Account{
		{Name: "A", Balance: 500},
		{Name: "B", Balance: 100},
	}
	db.Create(&accounts)
	fmt.Println("插入结果：")
	for _, account := range accounts {
		fmt.Println(account)
	}

	err := trans(db, "A", "B", 100)
	if err != nil {
		fmt.Println("交易失败:", err.Error())
		return
	}
	fmt.Println("交易成功")
}

func trans(db *gorm.DB, from string, to string, amount float64) error {
	return db.Transaction(func(tx *gorm.DB) error {
		accountFrom := Account{Name: from}
		aDB := tx.Where("name =?", from).First(&accountFrom)
		if err := aDB.Error; err != nil {
			return err
		}
		if accountFrom.Balance < amount {
			return errors.New("账户" + from + "余额不足")
		}

		accountTo := Account{Name: to}
		bDB := tx.Where("name =?", to).First(&accountTo)
		if err := bDB.Error; err != nil {
			return err
		}
		//更新记录
		accountFrom.Balance -= amount
		accountTo.Balance += amount
		trans := Transaction{FromAccountId: accountFrom.ID, ToAccountId: accountTo.ID, Amount: amount}
		if err := tx.Create(&trans).Error; err != nil {
			return err
		}

		if err := tx.Model(&accountFrom).Update("balance", accountFrom.Balance).Error; err != nil {
			return err
		}
		if err := tx.Model(&accountTo).Update("balance", accountTo.Balance).Error; err != nil {
			return err
		}
		return nil
	})
}
