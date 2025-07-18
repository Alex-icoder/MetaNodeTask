package main

import (
	"fmt"
	"gorm.io/gorm"
)

type User struct {
	gorm.Model
	UserName string `gorm:"size:20;uniqueIndex;not null"`
	Email    string `gorm:"size:50;uniqueIndex;not null"`
	Password string `gorm:"size:255;not null"`
	Posts    []Post
}

type Post struct {
	gorm.Model
	Title    string `gorm:"size:50;not null"`
	Content  string `gorm:"type:text;not null"`
	UserId   uint
	Comments []Comment
}

type Comment struct {
	gorm.Model
	Content  string
	UserName string `gorm:"size:20;not null"`
	PostId   uint
}

func main_模型定义() {
	db := getGorm()
	err := db.AutoMigrate(&User{}, &Post{}, &Comment{})
	if err != nil {
		panic("创建表失败:" + err.Error())
	}
	fmt.Println("创建表成功")
}

func main_关联查询() {
	db := getGorm()

	createTestData(db)
	user := User{}
	err := db.Debug().Preload("Posts.Comments").Preload("Posts").Find(&user, "users.user_name=?", "user1").Error
	if err != nil {
		panic("查询失败:" + err.Error())
	}
	if user.ID == 0 {
		fmt.Println("查询的指定用户不存在")
	} else {
		fmt.Println("查询指定用户发布的所有文章及其对应的评论信息：")
		fmt.Printf("用户信息: ID:%d,用户名:%s,邮箱:%s \n", user.ID, user.UserName, user.Email)
		if len(user.Posts) > 0 {
			for _, post := range user.Posts {
				fmt.Printf(" 文章信息: ID:%d,标题:%s,内容:%s\n", post.ID, post.Title, post.Content)
				if len(post.Comments) > 0 {
					for _, comment := range post.Comments {
						fmt.Printf("  评论信息: ID:%d,内容:%s \n", comment.ID, comment.Content)
					}
				}
			}
		}
	}

	var post Post
	errs := db.Debug().Select("posts.*,count(comments.id) as comment_count").
		Joins("LEFT JOIN comments on posts.id = comments.post_id").
		Group("posts.id").Order("comment_count desc").First(&post).Error
	if errs != nil {
		panic(errs)
	}
	if post.ID == 0 {
		fmt.Println("评论数量最多的文章不存在")
	} else {
		fmt.Println("评论数量最多的文章信息:")
		fmt.Printf("文章id:%d,标题:%s,内容:%s,用户id:%d", post.ID, post.Title, post.Content, post.UserId)
	}
}

// 创建测试数据
func createTestData(db *gorm.DB) {
	//清空现有数据
	db.Exec("DELETE FROM comments")
	db.Exec("DELETE FROM posts")
	db.Exec("DELETE FROM users")

	//创建用户
	user1 := User{
		UserName: "user1",
		Email:    "919702669@qq.com",
		Password: "123456",
	}
	db.Create(&user1)

	//创建文章
	post1 := Post{
		Title:   "GORM高级指南",
		Content: "深入讲解GORM关联查询...",
		UserId:  user1.ID,
		Comments: []Comment{
			{Content: "非常实用！", UserName: user1.UserName},
			{Content: "期待更多内容", UserName: user1.UserName},
		},
	}
	db.Create(&post1)
	post2 := Post{
		Title:   "GORM高级指南2",
		Content: "深入讲解GORM关联查询2...",
		UserId:  user1.ID,
		Comments: []Comment{
			{Content: "非常实用2！", UserName: user1.UserName},
			{Content: "期待更多内容2", UserName: user1.UserName},
		},
	}
	db.Create(&post2)

	user2 := User{
		UserName: "user2",
		Email:    "919702667@qq.com",
		Password: "123457",
	}
	db.Create(&user2)

	post3 := Post{
		Title:   "GORM高级指南3",
		Content: "深入讲解GORM关联查询3..",
		UserId:  user2.ID,
		Comments: []Comment{
			{Content: "非常实用3！", UserName: user2.UserName},
		},
	}
	db.Create(&post3)

	post4 := Post{
		Title:   "GORM高级指南3",
		Content: "深入讲解GORM关联查询3..",
		UserId:  user2.ID,
	}
	db.Create(&post4)
}
