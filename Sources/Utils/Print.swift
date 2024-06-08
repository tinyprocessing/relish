import Foundation

func printIfVerbose(_ isVerbose: Bool, _ value: Any, separator: String = " ", terminator: String = "\n") {
    guard isVerbose
    else {
        return
    }
    print(value, separator: separator, terminator: terminator)
}
