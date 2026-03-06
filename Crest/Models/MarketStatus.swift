import Foundation
import SwiftUI

enum MarketStatus {
    case open(closesIn: TimeInterval)
    case preMarket(opensIn: TimeInterval)
    case afterHours(closesIn: TimeInterval)
    case closed

    init?(periods: YFTradingPeriods) {
        let now = Date()
        let regularStart = Date(timeIntervalSince1970: periods.regular.start)
        let regularEnd   = Date(timeIntervalSince1970: periods.regular.end)

        if now >= regularStart && now < regularEnd {
            self = .open(closesIn: regularEnd.timeIntervalSinceNow)
            return
        }
        if let pre = periods.pre {
            let preStart = Date(timeIntervalSince1970: pre.start)
            if now >= preStart && now < regularStart {
                self = .preMarket(opensIn: regularStart.timeIntervalSinceNow)
                return
            }
        }
        if let post = periods.post {
            let postEnd = Date(timeIntervalSince1970: post.end)
            if now >= regularEnd && now < postEnd {
                self = .afterHours(closesIn: postEnd.timeIntervalSinceNow)
                return
            }
        }
        self = .closed
    }

    var dotColor: Color {
        switch self {
        case .open:        return .green
        case .preMarket:   return Color.orange
        case .afterHours:  return Color.orange
        case .closed:      return .secondary
        }
    }

    var label: String {
        switch self {
        case .open(let t):        return "Open · closes \(formatInterval(t))"
        case .preMarket(let t):   return "Pre-market · opens \(formatInterval(t))"
        case .afterHours(let t):  return "After hours · closes \(formatInterval(t))"
        case .closed:             return "Closed"
        }
    }
}

private func formatInterval(_ t: TimeInterval) -> String {
    guard t > 0 else { return "now" }
    let m = Int(t) / 60
    let h = m / 60
    let rem = m % 60
    return h > 0 ? "in \(h)h \(rem)m" : "in \(rem)m"
}
