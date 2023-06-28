package hlglobals

// simple test case
// global variable usage should be highlighted

var msg = "Hello, world"
//  ^^here

func main() {
    println(msg)
//          ^^here
}
