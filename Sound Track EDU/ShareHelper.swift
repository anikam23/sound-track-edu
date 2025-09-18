import Foundation
import SwiftUI
import UIKit

enum ShareHelper {

    /// Build a simple .txt export for a transcript and return the temporary file URL.
    static func temporaryFile(for record: TranscriptRecord) -> URL {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        let dateLine = df.string(from: record.createdAt)

        var lines: [String] = []
        lines.append(record.displayTitle)
        lines.append("Date: \(dateLine)")
        lines.append("Period: \(record.period)")
        lines.append("Subject: \(record.subject)")
        lines.append(String(repeating: "—", count: 30))

        if let summary = record.summary, !summary.isEmpty {
            lines.append("Summary:")
            lines.append(summary)
            lines.append(String(repeating: "—", count: 30))
        }

        lines.append("Transcript:")
        lines.append(record.text)

        let body = lines.joined(separator: "\n\n")

        let tmpDir = FileManager.default.temporaryDirectory
        let base = record.displayTitle.sanitizedFilename()
        let url = tmpDir.appendingPathComponent("\(base).txt")

        try? body.data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }

    /// Present the iOS share sheet for a list of file URLs.
    static func presentShareSheet(with urls: [URL]) {
        let vc = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        vc.excludedActivityTypes = [.assignToContact, .addToReadingList, .openInIBooks]

        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let root = scene.keyWindow?.rootViewController else {
            return
        }

        root.presentFromTop(vc, animated: true)
    }
}

// MARK: - helpers

private extension String {
    func sanitizedFilename() -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return self
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")
            .components(separatedBy: invalid).joined()
    }
}

private extension UIWindowScene {
    var keyWindow: UIWindow? {
        return self.windows.first(where: { $0.isKeyWindow })
    }
}

private extension UIViewController {
    func topMost() -> UIViewController {
        if let presented = presentedViewController { return presented.topMost() }
        if let nav = self as? UINavigationController { return nav.visibleViewController?.topMost() ?? nav }
        if let tab = self as? UITabBarController { return tab.selectedViewController?.topMost() ?? tab }
        return self
    }

    func presentFromTop(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        topMost().present(viewController, animated: animated, completion: completion)
    }
}
