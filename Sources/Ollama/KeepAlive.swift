import Foundation

/// Controls how long a model will stay loaded into memory following a request.
public enum KeepAlive: Hashable, Sendable, Comparable {
    /// Use the server's default keep-alive behavior.
    case `default`

    /// Unload the model immediately after the request.
    case none

    /// Keep the model loaded for a specific duration.
    case duration(Duration)

    /// Keep the model loaded indefinitely.
    case forever

    /// Converts the KeepAlive enum to a Value for API requests.
    var value: Value? {
        switch self {
        case .default:
            return nil
        case .none:
            return .int(0)
        case .forever:
            return .int(-1)
        case .duration(let duration):
            switch duration.totalSeconds {
            case ..<0:
                return .int(-1)
            case 0:
                return .int(0)
            default:
                return .string(duration.description)
            }
        }
    }

    /// Duration specifications for keeping a model loaded.
    public enum Duration: Hashable, Sendable, Comparable {
        /// Keep loaded for the specified number of seconds.
        /// - Note: Zero values convert to `.none`, negative values convert to `.indefinite`.
        case seconds(Int)

        /// Keep loaded for the specified number of minutes.
        /// - Note: Zero values convert to `.none`, negative values convert to `.indefinite`.
        case minutes(Int)

        /// Keep loaded for the specified number of hours.
        /// - Note: Zero values convert to `.none`, negative values convert to `.indefinite`.
        case hours(Int)
    }
}

// MARK: - Convenience Initializers

extension KeepAlive {
    /// Creates a KeepAlive value for the specified number of seconds.
    /// - Parameter seconds: The number of seconds to keep the model loaded.
    ///   Zero converts to `.none`, negative values convert to `.indefinite`.
    /// - Returns: A KeepAlive value with the specified duration.
    public static func seconds(_ seconds: Int) -> KeepAlive {
        .duration(.seconds(seconds))
    }

    /// Creates a KeepAlive value for the specified number of minutes.
    /// - Parameter minutes: The number of minutes to keep the model loaded.
    ///   Zero converts to `.none`, negative values convert to `.indefinite`.
    /// - Returns: A KeepAlive value with the specified duration.
    public static func minutes(_ minutes: Int) -> KeepAlive {
        .duration(.minutes(minutes))
    }

    /// Creates a KeepAlive value for the specified number of hours.
    /// - Parameter hours: The number of hours to keep the model loaded.
    ///   Zero converts to `.none`, negative values convert to `.indefinite`.
    /// - Returns: A KeepAlive value with the specified duration.
    public static func hours(_ hours: Int) -> KeepAlive {
        .duration(.hours(hours))
    }
}

// MARK: - Comparable

extension KeepAlive {
    public static func < (lhs: KeepAlive, rhs: KeepAlive) -> Bool {
        switch (lhs, rhs) {
        // Equal cases always return false
        case (.default, .default):
            return false
        case (.none, .none):
            return false
        case (.forever, .forever):
            return false

        // Default is less than everything except itself
        case (.default, _):
            return true
        case (_, .default):
            return false

        // None is less than forever and duration, but greater than default
        case (.none, .forever), (.none, .duration):
            return true
        case (.none, _):
            return false

        // Forever is greater than everything except itself
        case (.forever, _):
            return false
        case (_, .forever):
            return true

        // Duration cases compare their total seconds
        case (.duration(let lhsDuration), .duration(let rhsDuration)):
            return lhsDuration < rhsDuration

        // Duration is greater than none
        case (.duration, .none):
            return false

        // Everything else is greater than none
        case (_, .none):
            return true
        }
    }
}

extension KeepAlive.Duration {
    public static func < (lhs: KeepAlive.Duration, rhs: KeepAlive.Duration) -> Bool {
        return lhs.totalSeconds < rhs.totalSeconds
    }

    /// Returns the total duration in seconds for comparison purposes.
    var totalSeconds: Int {
        switch self {
        case .seconds(let value):
            return value
        case .minutes(let value):
            return value * 60
        case .hours(let value):
            return value * 3600
        }
    }
}

// MARK: - CustomStringConvertible

extension KeepAlive: CustomStringConvertible {
    public var description: String {
        switch self {
        case .default:
            return "default"
        case .none:
            return "none"
        case .forever:
            return "forever"
        case .duration(let duration):
            return duration.description
        }
    }
}

extension KeepAlive.Duration: CustomStringConvertible {
    public var description: String {
        switch self {
        case .seconds(let value):
            return "\(value)s"
        case .minutes(let value):
            return "\(value)m"
        case .hours(let value):
            return "\(value)h"
        }
    }
}
