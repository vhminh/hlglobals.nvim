package main

var i = -1
//  ^^here

func main() {
    for i := 0; i < 5; i++ {
//      ^^      ^^     ^^
        println(i)
//              ^^
    }
    println(i)
//          ^^here
}
