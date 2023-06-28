package main

// shadow

var msg = "global message"
//  ^^here

func main() {
    msg := "local message"
//  ^^
    println(msg) // refers to the `msg` in the local scope
//          ^^
}
