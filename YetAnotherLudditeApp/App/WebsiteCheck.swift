import Foundation

/// Draft edits never change the host whose result is on screen.
struct WebsiteCheck {
    var input: String
    private(set) var checkedHost: String?
    private(set) var error: String?

    init(initialHost: String) {
        input = initialHost
        if !initialHost.isEmpty { _ = submit() }
    }

    @discardableResult
    mutating func submit() -> Bool {
        do {
            checkedHost = try DomainPattern.parse(input, scope: .exactHost).host
            error = nil
            return true
        } catch {
            self.error = error.localizedDescription + (checkedHost.map {
                " The result still describes \($0)."
            } ?? " No address has been checked yet.")
            return false
        }
    }
}
