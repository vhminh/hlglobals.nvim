package main

// should support multi variable declaration in range clause

var k = "global key"
//  ^^here
var v = "global value"
//  ^^here

func main() {
    for k, v := range map[string]string{} {
//      ^^ ^^
        print(k, v)
//            ^^ ^^
    }
    for i, item := range []string{} {
//      ^^ ^^
        print(i, item)
//            ^^ ^^
    }

    print(k)
//        ^^here
    println(v)
//          ^^here
}
