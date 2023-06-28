package main

// should support multi variable declaration

var msg = "global message"
//  ^^here

func main() {
    dummy, msg := 0, 1
//  ^^     ^^
    print(dummy)
//        ^^
    println(msg) // refers to the `msg` in the local scope
//          ^^
}
