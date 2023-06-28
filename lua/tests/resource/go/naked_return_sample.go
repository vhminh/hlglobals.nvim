package main

// currently, named returned variables are considered local
// TODO: may need to implement an option to highlight named return because they are hard to track in large functions

func sum(a int, b int) (result int) {
//       ^^     ^^      ^^
    result = a + b
//  ^^       ^^  ^^
    return
}

func main() {
    println(sum(1, 2))
}
