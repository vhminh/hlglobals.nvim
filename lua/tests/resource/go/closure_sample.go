package main

// highlight closure

func sum(a int) func(int) int {
//       ^^
    return func(b int) int {
//              ^^
        return a    +    b
//             ^^here    ^^
    }
}
