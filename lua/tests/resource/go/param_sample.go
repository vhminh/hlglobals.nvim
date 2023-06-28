package main

// parameters are considered local

func sum(a int, b int) int {
//       ^^     ^^
    return a + b
//         ^^  ^^
}
