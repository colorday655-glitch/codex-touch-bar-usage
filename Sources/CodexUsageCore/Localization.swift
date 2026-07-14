import Foundation

public struct CodexLocalization: Sendable {
    private let locale: Locale

    public init(locale: Locale = .autoupdatingCurrent) {
        self.locale = locale
    }

    public var isChinese: Bool {
        locale.identifier.lowercased().hasPrefix("zh")
    }

    public var resetCreditsLabel: String {
        isChinese ? "可重置次数" : "Reset credits"
    }

    public var weeklyLabel: String {
        isChinese ? "1周" : "1w"
    }

    public var resetSoon: String {
        isChinese ? "即将重置" : "Reset soon"
    }

    public var unauthenticatedMessage: String {
        isChinese ? "请先在 Codex 登录" : "Sign in to Codex first"
    }

    public var unavailableMessage: String {
        isChinese ? "Codex 用量暂不可用" : "Codex usage unavailable"
    }

    public var outdatedReleaseMessage: String {
        isChinese ? "当前版本已过期，请安装 GitHub 最新版" : "This release is outdated. Install the latest GitHub release."
    }

    public var inactivePlaceholder: String {
        "\u{2060}"
    }

    public var firstColumnTargetWidth: Int {
        isChinese ? 10 : 13
    }

    public func resetFormatter(style: ResetStyle, timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        switch style {
        case .fiveHour:
            formatter.setLocalizedDateFormatFromTemplate("jmm")
        case .weekly:
            formatter.setLocalizedDateFormatFromTemplate("MMMd")
        }
        return formatter
    }

    public enum ResetStyle: Sendable {
        case fiveHour
        case weekly
    }
}
