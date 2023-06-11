package main

// simple test case
// global variable usage should be highlighted

var msg = "Hello, world"

func f() {
	println(msg)
	//      ^here
}

