import Foundation

extension String: StyledText {}

extension StyledText where Self == String {
    static func standardText(_ value: String) -> String {
        value
    }
}
