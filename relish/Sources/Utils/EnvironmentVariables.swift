import Foundation

extension ProcessInfo {
    var isDebugging: Bool {
        environment["is_debugging"] == "true"
    }

    var isJenkinsUser: Bool {
        environment["JENKINS_USER"] != nil
    }

    var githubToken: String? {
        environment["GITHUB_TOKEN"]
    }

    var pullNumber: Int? {
        environment["GITHUB_PR_NUMBER"].flatMap(Int.init)
    }

    var isXcode: Bool {
        (environment["XCODE_VERSION_ACTUAL"] ?? "") != ""
    }
}
