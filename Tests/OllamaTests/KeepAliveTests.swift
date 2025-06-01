import Foundation
import Testing

@testable import Ollama

@Suite
struct KeepAliveTests {
    @Test
    func testKeepAliveConvenienceInitializers() throws {
        let tenSeconds: KeepAlive = .seconds(10)
        let thirtyMinutes: KeepAlive = .minutes(30)
        let twoHours: KeepAlive = .hours(2)

        // Verify structure
        switch tenSeconds {
        case .duration(.seconds(let value)):
            #expect(value == 10)
        default:
            Issue.record("Expected duration(.seconds(10))")
        }

        switch thirtyMinutes {
        case .duration(.minutes(let value)):
            #expect(value == 30)
        default:
            Issue.record("Expected duration(.minutes(30))")
        }

        switch twoHours {
        case .duration(.hours(let value)):
            #expect(value == 2)
        default:
            Issue.record("Expected duration(.hours(2))")
        }
    }

    @Test
    func testKeepAliveValueConversion() throws {
        // Test default
        let defaultKeepAlive: KeepAlive = .default
        let defaultValue = defaultKeepAlive.value
        #expect(defaultValue == nil)

        // Test none
        let none: KeepAlive = .none
        let noneValue = none.value
        if case .int(let val) = noneValue {
            #expect(val == 0)
        } else {
            Issue.record("Expected none to convert to .int(0)")
        }

        // Test forever
        let forever: KeepAlive = .forever
        let foreverValue = forever.value
        if case .int(let val) = foreverValue {
            #expect(val == -1)
        } else {
            Issue.record("Expected forever to convert to .int(-1)")
        }

        // Test duration
        let fiveMinutes: KeepAlive = .minutes(5)
        let fiveMinutesValue = fiveMinutes.value
        if case .string(let val) = fiveMinutesValue {
            #expect(val == "5m")
        } else {
            Issue.record("Expected 5 minutes to convert to .string(\"5m\")")
        }

        let tenSeconds: KeepAlive = .seconds(10)
        let tenSecondsValue = tenSeconds.value
        if case .string(let val) = tenSecondsValue {
            #expect(val == "10s")
        } else {
            Issue.record("Expected 10 seconds to convert to .string(\"10s\")")
        }

        let twoHours: KeepAlive = .hours(2)
        let twoHoursValue = twoHours.value
        if case .string(let val) = twoHoursValue {
            #expect(val == "2h")
        } else {
            Issue.record("Expected 2 hours to convert to .string(\"2h\")")
        }
    }

    @Test
    func testKeepAliveZeroDurations() throws {
        let none: KeepAlive = .none
        let zeroSeconds: KeepAlive = .seconds(0)
        let zeroMinutes: KeepAlive = .minutes(0)
        let zeroHours: KeepAlive = .hours(0)

        // Test value conversion
        if case .int(let val) = zeroSeconds.value {
            #expect(val == 0)
        } else {
            Issue.record("Expected 0 seconds to convert to .int(0)")
        }

        if case .int(let val) = zeroMinutes.value {
            #expect(val == 0)
        } else {
            Issue.record("Expected 0 minutes to convert to .int(0)")
        }

        if case .int(let val) = zeroHours.value {
            #expect(val == 0)
        } else {
            Issue.record("Expected 0 hours to convert to .int(0)")
        }

        // Test equality
        #expect(none.value == zeroSeconds.value)
        #expect(none.value == zeroMinutes.value)
        #expect(none.value == zeroHours.value)
    }

    @Test
    func testKeepAliveNegativeDurations() throws {
        let forever: KeepAlive = .forever
        let negativeSeconds: KeepAlive = .seconds(-5)
        let negativeMinutes: KeepAlive = .minutes(-5)
        let negativeHours: KeepAlive = .hours(-5)

        // Test value conversion
        if case .int(let val) = negativeSeconds.value {
            #expect(val == -1)
        } else {
            Issue.record("Expected negative seconds to convert to .int(-1)")
        }

        if case .int(let val) = negativeMinutes.value {
            #expect(val == -1)
        } else {
            Issue.record("Expected negative minutes to convert to .int(-1)")
        }

        if case .int(let val) = negativeHours.value {
            #expect(val == -1)
        } else {
            Issue.record("Expected negative hours to convert to .int(-1)")
        }

        // Test equality
        #expect(forever.value == negativeSeconds.value)
        #expect(forever.value == negativeMinutes.value)
        #expect(forever.value == negativeHours.value)
    }

    @Test
    func testKeepAliveDescription() throws {
        // Test default, none and forever
        let defaultKeepAlive: KeepAlive = .default
        #expect(defaultKeepAlive.description == "default")

        let none: KeepAlive = .none
        #expect(none.description == "none")

        let forever: KeepAlive = .forever
        #expect(forever.description == "forever")

        // Test duration descriptions (API format)
        let fiveMinutes: KeepAlive = .minutes(5)
        #expect(fiveMinutes.description == "5m")

        let tenSeconds: KeepAlive = .seconds(10)
        #expect(tenSeconds.description == "10s")

        let twoHours: KeepAlive = .hours(2)
        #expect(twoHours.description == "2h")
    }

    @Test
    func testKeepAliveEquality() throws {
        // Test basic equality
        let default1: KeepAlive = .default
        let default2: KeepAlive = .default
        #expect(default1 == default2)

        let none1: KeepAlive = .none
        let none2: KeepAlive = .none
        #expect(none1 == none2)

        let forever1: KeepAlive = .forever
        let forever2: KeepAlive = .forever
        #expect(forever1 == forever2)

        // Test duration equality
        let fiveMinutes1: KeepAlive = .minutes(5)
        let fiveMinutes2: KeepAlive = .minutes(5)
        #expect(fiveMinutes1 == fiveMinutes2)

        // Test inequality
        #expect(default1 != none1)
        #expect(default1 != forever1)
        #expect(default1 != fiveMinutes1)
        #expect(none1 != forever1)
        #expect(none1 != fiveMinutes1)
        #expect(forever1 != fiveMinutes1)

        let tenMinutes: KeepAlive = .minutes(10)
        #expect(fiveMinutes1 != tenMinutes)
    }

    @Test
    func testKeepAliveHashable() throws {
        // Test Set behavior
        var keepAliveSet: Set<KeepAlive> = []
        keepAliveSet.insert(.default)
        keepAliveSet.insert(.default)  // Should not increase count
        keepAliveSet.insert(.none)
        keepAliveSet.insert(.none)  // Should not increase count
        keepAliveSet.insert(.forever)
        keepAliveSet.insert(.minutes(5))
        keepAliveSet.insert(.minutes(5))  // Should not increase count
        keepAliveSet.insert(.minutes(10))

        #expect(keepAliveSet.count == 5)
        #expect(keepAliveSet.contains(.default))
        #expect(keepAliveSet.contains(.none))
        #expect(keepAliveSet.contains(.forever))
        #expect(keepAliveSet.contains(.minutes(5)))
        #expect(keepAliveSet.contains(.minutes(10)))
    }

    @Suite
    struct DurationTests {
        @Test
        func testDurationInitialization() throws {
            let seconds: KeepAlive.Duration = .seconds(30)
            let minutes: KeepAlive.Duration = .minutes(5)
            let hours: KeepAlive.Duration = .hours(2)

            // Test structure
            switch seconds {
            case .seconds(let value):
                #expect(value == 30)
            default:
                Issue.record("Expected .seconds(30)")
            }

            switch minutes {
            case .minutes(let value):
                #expect(value == 5)
            default:
                Issue.record("Expected .minutes(5)")
            }

            switch hours {
            case .hours(let value):
                #expect(value == 2)
            default:
                Issue.record("Expected .hours(2)")
            }
        }

        @Test
        func testDurationDescription() throws {
            let seconds: KeepAlive.Duration = .seconds(30)
            #expect(seconds.description == "30s")

            let minutes: KeepAlive.Duration = .minutes(5)
            #expect(minutes.description == "5m")

            let hours: KeepAlive.Duration = .hours(2)
            #expect(hours.description == "2h")
        }

        @Test
        func testDurationEquality() throws {
            let fiveMinutes1: KeepAlive.Duration = .minutes(5)
            let fiveMinutes2: KeepAlive.Duration = .minutes(5)
            #expect(fiveMinutes1 == fiveMinutes2)

            let tenMinutes: KeepAlive.Duration = .minutes(10)
            #expect(fiveMinutes1 != tenMinutes)

            let threeHundredSeconds: KeepAlive.Duration = .seconds(300)
            // Note: 5 minutes = 300 seconds, but these are different cases so not equal
            #expect(fiveMinutes1 != threeHundredSeconds)
        }

        @Test
        func testDurationHashable() throws {
            var durationSet: Set<KeepAlive.Duration> = []
            durationSet.insert(.seconds(30))
            durationSet.insert(.seconds(30))  // Should not increase count
            durationSet.insert(.minutes(5))
            durationSet.insert(.hours(2))

            #expect(durationSet.count == 3)
            #expect(durationSet.contains(.seconds(30)))
            #expect(durationSet.contains(.minutes(5)))
            #expect(durationSet.contains(.hours(2)))
        }

        @Test
        func testKeepAliveComparison() throws {
            let defaultKeepAlive: KeepAlive = .default
            let none: KeepAlive = .none
            let fiveMinutes: KeepAlive = .minutes(5)
            let tenMinutes: KeepAlive = .minutes(10)
            let oneHour: KeepAlive = .hours(1)
            let forever: KeepAlive = .forever

            // Test default is smallest
            #expect(defaultKeepAlive < none)
            #expect(defaultKeepAlive < fiveMinutes)
            #expect(defaultKeepAlive < tenMinutes)
            #expect(defaultKeepAlive < oneHour)
            #expect(defaultKeepAlive < forever)

            // Test none is second smallest
            #expect(none < fiveMinutes)
            #expect(none < tenMinutes)
            #expect(none < oneHour)
            #expect(none < forever)

            // Test duration comparisons
            #expect(fiveMinutes < tenMinutes)
            #expect(tenMinutes < oneHour)
            #expect(fiveMinutes < oneHour)

            // Test reflexivity
            #expect(!(defaultKeepAlive < defaultKeepAlive))
            #expect(!(none < none))
            #expect(!(fiveMinutes < fiveMinutes))
            #expect(!(forever < forever))
        }

        @Test
        func testDurationComparison() throws {
            let thirtySeconds: KeepAlive.Duration = .seconds(30)
            let oneMinute: KeepAlive.Duration = .minutes(1)
            let ninetySeconds: KeepAlive.Duration = .seconds(90)
            let twoMinutes: KeepAlive.Duration = .minutes(2)
            let oneHour: KeepAlive.Duration = .hours(1)

            // Test basic comparisons
            #expect(thirtySeconds < oneMinute)  // 30s < 60s
            #expect(oneMinute < ninetySeconds)  // 60s < 90s
            #expect(ninetySeconds < twoMinutes)  // 90s < 120s
            #expect(twoMinutes < oneHour)  // 120s < 3600s

            // Test cross-unit comparisons
            #expect(thirtySeconds < twoMinutes)
            #expect(oneMinute < oneHour)

            // Test same values in different units
            let sixtySeconds: KeepAlive.Duration = .seconds(60)
            #expect(!(oneMinute < sixtySeconds))  // 60s == 60s (same total duration)
            #expect(!(sixtySeconds < oneMinute))  // 60s == 60s (same total duration)
            // Note: These are different enum cases, so they're not equal (==), but they compare as equivalent for ordering
        }

        @Test
        func testKeepAliveSorting() throws {
            let values: [KeepAlive] = [
                .forever,
                .hours(2),
                .none,
                .minutes(30),
                .default,
                .minutes(5),
                .seconds(45),
            ]

            let sorted = values.sorted()

            // Expected order: default < none < seconds < minutes < hours < forever
            #expect(sorted[0] == .default)
            #expect(sorted[1] == .none)
            #expect(sorted[2] == .seconds(45))
            #expect(sorted[3] == .minutes(5))
            #expect(sorted[4] == .minutes(30))
            #expect(sorted[5] == .hours(2))
            #expect(sorted[6] == .forever)
        }

        @Test
        func testDurationSorting() throws {
            let durations: [KeepAlive.Duration] = [
                .hours(1),
                .seconds(30),
                .minutes(5),
                .seconds(90),
                .minutes(1),
                .hours(2),
            ]

            let sorted = durations.sorted()

            // Expected order by total seconds: 30s, 60s, 90s, 300s, 3600s, 7200s
            #expect(sorted[0] == .seconds(30))  // 30s
            #expect(sorted[1] == .minutes(1))  // 60s
            #expect(sorted[2] == .seconds(90))  // 90s
            #expect(sorted[3] == .minutes(5))  // 300s
            #expect(sorted[4] == .hours(1))  // 3600s
            #expect(sorted[5] == .hours(2))  // 7200s
        }

        @Test
        func testZeroDurations() throws {
            // Test comparison - all zero durations should be equal in comparison
            let zeroSecondsDuration: KeepAlive.Duration = .seconds(0)
            let zeroMinutesDuration: KeepAlive.Duration = .minutes(0)
            let zeroHoursDuration: KeepAlive.Duration = .hours(0)

            #expect(!(zeroSecondsDuration < zeroMinutesDuration))
            #expect(!(zeroMinutesDuration < zeroSecondsDuration))
            #expect(!(zeroSecondsDuration < zeroHoursDuration))
            #expect(!(zeroHoursDuration < zeroSecondsDuration))
        }

        @Test
        func testLargeDurations() throws {
            let largeSeconds: KeepAlive = .seconds(999999)
            let largeMinutes: KeepAlive = .minutes(99999)
            let largeHours: KeepAlive = .hours(9999)

            // Test value conversion
            if case .string(let val) = largeSeconds.value {
                #expect(val == "999999s")
            } else {
                Issue.record("Expected large seconds to convert properly")
            }

            if case .string(let val) = largeHours.value {
                #expect(val == "9999h")
            } else {
                Issue.record("Expected large hours to convert properly")
            }

            // Test comparison still works with large values
            #expect(largeSeconds < largeMinutes)  // seconds < minutes in total time
        }

        @Test
        func testNegativeDurations() throws {
            // Note: Negative durations are converted to forever (.int(-1))
            let negativeSeconds: KeepAlive = .seconds(-5)
            let negativeMinutes: KeepAlive = .minutes(-1)

            // Test value conversion - negative durations become forever
            if case .int(let val) = negativeSeconds.value {
                #expect(val == -1)
            } else {
                Issue.record("Expected negative seconds to convert to .int(-1)")
            }

            if case .int(let val) = negativeMinutes.value {
                #expect(val == -1)
            } else {
                Issue.record("Expected negative minutes to convert to .int(-1)")
            }

            // Test comparison with negative values
            let negativeSecondsDuration: KeepAlive.Duration = .seconds(-5)
            let negativeMinutesDuration: KeepAlive.Duration = .minutes(-1)
            let positiveSecondsDuration: KeepAlive.Duration = .seconds(5)

            #expect(negativeSecondsDuration < positiveSecondsDuration)
            #expect(negativeMinutesDuration < negativeSecondsDuration)  // -60s < -5s
        }

        @Test
        func testMixedComparisons() throws {
            // Test edge cases for cross-unit comparisons
            let almostOneMinute: KeepAlive.Duration = .seconds(59)
            let exactlyOneMinute: KeepAlive.Duration = .minutes(1)
            let justOverOneMinute: KeepAlive.Duration = .seconds(61)

            #expect(almostOneMinute < exactlyOneMinute)  // 59s < 60s
            #expect(exactlyOneMinute < justOverOneMinute)  // 60s < 61s
            #expect(almostOneMinute < justOverOneMinute)  // 59s < 61s

            // Test hour/minute boundaries
            let almostOneHour: KeepAlive.Duration = .minutes(59)
            let exactlyOneHour: KeepAlive.Duration = .hours(1)
            let justOverOneHour: KeepAlive.Duration = .minutes(61)

            #expect(almostOneHour < exactlyOneHour)  // 3540s < 3600s
            #expect(exactlyOneHour < justOverOneHour)  // 3600s < 3660s
        }
    }
}
