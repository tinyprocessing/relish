extension StringProtocol {
    var trimmed: String {
        let startIndex = firstIndex(where: { !$0.isWhitespace }) ?? self.startIndex
        let endIndex = lastIndex(where: { !$0.isWhitespace }) ?? self.endIndex
        return isEmpty ? String(self) : String(self[startIndex...endIndex])
    }
}
