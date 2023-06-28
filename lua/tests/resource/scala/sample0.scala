package main

object Main {
  val name = "Minh"
//    ^^here

  def main(args: Array[String]): Unit = {
//         ^ ^TODO: ignored, currently focusing on support golang first
    print(s"Hello $name")
//                 ^^here
  }
}
