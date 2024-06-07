import Foundation

protocol ASCIIFormatter {
    func format(_ string: String, style: ASCIIStyle) -> String
}

struct GlobalASCIIFormatter: ASCIIFormatter {
    static let resetCode = "\u{001B}[0;0m"

    var procesInfo: ProcessInfo = .processInfo

    func format(_ string: String, style: ASCIIStyle) -> String {
        return "\(style.code)\(string)\(Self.resetCode)"
    }
}

enum ASCIIStyle: String {
    case bold

    case black
    case red
    case green
    case yellow
    case blue
    case magenta
    case cyan
    case white

    case blackBold
    case redBold
    case greenBold
    case yellowBold
    case blueBold
    case magentaBold
    case cyanBold
    case whiteBold

    var code: String {
        switch self {
        case .bold: return "\u{001B}[1;4"
        case .black: return "\u{001B}[0;30m"
        case .red: return "\u{001B}[0;31m"
        case .green: return "\u{001B}[0;32m"
        case .yellow: return "\u{001B}[0;33m"
        case .blue: return "\u{001B}[0;34m"
        case .magenta: return "\u{001B}[0;35m"
        case .cyan: return "\u{001B}[0;36m"
        case .white: return "\u{001B}[0;37m"
        case .blackBold: return "\u{001B}[1;4;30m"
        case .redBold: return "\u{001B}[1;4;31m"
        case .greenBold: return "\u{001B}[1;4;32m"
        case .yellowBold: return "\u{001B}[1;4;33m"
        case .blueBold: return "\u{001B}[1;4;34m"
        case .magentaBold: return "\u{001B}[1;4;35m"
        case .cyanBold: return "\u{001B}[1;4;36m"
        case .whiteBold: return "\u{001B}[1;4;37m"
        }
    }
}

extension String {
    /// Wraps the string in terminal color codes.
    func applyingAsciiFormatting(_ style: ASCIIStyle, formatter: ASCIIFormatter = GlobalASCIIFormatter()) -> String {
        formatter.format(self, style: style)
    }
}
