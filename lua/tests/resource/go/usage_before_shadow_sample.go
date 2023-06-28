package main

// usage before local declaration

var msg = "global message"
//  ^^here

func main() {
    println(msg) // `msg` in the global scope
//          ^^here
    msg := "local message"
//  ^^
    print(msg) // `msg` in local scope
//        ^^
}
