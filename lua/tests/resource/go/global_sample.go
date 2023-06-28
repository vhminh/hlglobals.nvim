package main

// global variable declaration and usage should be highlighted

var msg = "Hello, world"
//  ^^here

func main() {
    println(msg) // refers to `msg` in global scope, should be highlighted
//          ^^here
}
