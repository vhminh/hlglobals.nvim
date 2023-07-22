package main

// methods with receiver are `method_declaration`s in golang treesitter

type person struct{}

func (p *person) greet(name string) {
//    ^^               ^^
    msg := "hello, " + name
//  ^^                 ^^
    println(msg)
//          ^^
}
