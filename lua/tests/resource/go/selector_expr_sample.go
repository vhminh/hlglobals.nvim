package main

// should support selector expr for ex `p.Name`

type person struct {
    Name string
//  ^^
    Age int
//  ^^
}

var age0 = 69

var person0 = person{ Name: "Minh", Age: age0 }
//  ^^here            ^^            ^^   ^^here

func main() {
    print(person0.Name)
//        ^^here  ^^

    age1 := 420
    person1 := person{ Name: "Vu", Age: age1 }
//  ^^                 ^^          ^^   ^^
    print(person1.Name)
//        ^^      ^^
}
