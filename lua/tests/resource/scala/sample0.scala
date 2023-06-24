package main

object Main {
  val name = "Minh"
//    ^^here

  def main(args: Array[String]): Unit = {
//         ^TODO: fix here, currently all variables are considered global
    print(s"Hello $name")
//                 ^^here
  }
}
