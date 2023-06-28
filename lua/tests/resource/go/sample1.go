package hlglobals

// should not highlight local vars

func main() {
    var msg = "Hello, world"
//      ^^
    println(msg)
//          ^^
}
