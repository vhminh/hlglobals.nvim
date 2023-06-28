package main

// ifs should create a new scope

var msg = "global message"
//  ^^here

func main() {
    if true {
        msg := "local message"
//      ^^
        println(msg) // refers to the `msg` declared locally in if block
//              ^^
    }
    println(msg) // refers to the `msg` in the global scope
//          ^^here
}
