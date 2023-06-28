package main

// support inline var declaration in ifs

var msg = "global message"
//  ^^here

func main() {
    if msg, ok := "local message", true; ok {
//     ^^   ^^                           ^^
        println(msg) // refers to the `msg` declared locally in if block
//              ^^
    }
    println(msg) // refers to the `msg` in the global scope
//          ^^here
}
