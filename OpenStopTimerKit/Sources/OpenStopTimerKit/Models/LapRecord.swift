import Foundation

/// One recorded lap in the lap stopwatch.
public struct LapRecord: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var index: Int
    public var lapTime: TimeInterval
    public var cumulativeTime: TimeInterval
    public var timestamp: Date

    public init(
        id: UUID = UUID(),
        index: Int,
        lapTime: TimeInterval,
        cumulativeTime: TimeInterval,
        timestamp: Date = .now
    ) {
        self.id = id
        self.index = index
        self.lapTime = lapTime
        self.cumulativeTime = cumulativeTime
        self.timestamp = timestamp
    }
}
