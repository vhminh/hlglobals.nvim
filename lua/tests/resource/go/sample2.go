package hlglobals

// should not highlight local vars

var msg = "global message"
//  ^^here

func main() {
    if true {
        msg := "local message"
//      ^^
        println(msg)
//              ^^
    }
    println(msg)
//          ^^here
}
