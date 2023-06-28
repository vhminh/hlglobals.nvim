package main

// don't highlight local vars

func main() {
    var msg = "Hello, world"
//      ^^
    println(msg) // refers to `msg` in local scope, should not be highlighted
//          ^^
}
