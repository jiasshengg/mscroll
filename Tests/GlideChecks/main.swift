import CoreGraphics

enum CheckFailure: Error, CustomStringConvertible {
    case mismatch(String)

    var description: String {
        switch self {
        case .mismatch(let message): message
        }
    }
}

@main
enum GlideChecks {
    static func main() throws {
        try reversesLineBasedScrollAxes()
        try leavesContinuousScrollEventsUnchanged()
        print("Glide checks passed")
    }

    private static func reversesLineBasedScrollAxes() throws {
        guard let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .line,
            wheelCount: 2,
            wheel1: 3,
            wheel2: -2,
            wheel3: 0
        ) else {
            throw CheckFailure.mismatch("Could not create a line-based scroll event")
        }

        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 0)
        let originalPointAxis1 = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
        let originalPointAxis2 = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2)
        let originalFixedAxis1 = event.getIntegerValueField(.scrollWheelEventFixedPtDeltaAxis1)
        let originalFixedAxis2 = event.getIntegerValueField(.scrollWheelEventFixedPtDeltaAxis2)

        try expect(ScrollEventTransformer.reverseLineBasedScroll(event), "Line-based event was not reversed")
        try expect(event.getIntegerValueField(.scrollWheelEventDeltaAxis1) == -3, "Vertical line delta has the wrong sign")
        try expect(event.getIntegerValueField(.scrollWheelEventDeltaAxis2) == 2, "Horizontal line delta has the wrong sign")
        try expect(hasOppositeSign(originalPointAxis1, event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)), "Vertical point delta has the wrong sign")
        try expect(hasOppositeSign(originalPointAxis2, event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2)), "Horizontal point delta has the wrong sign")
        try expect(event.getIntegerValueField(.scrollWheelEventFixedPtDeltaAxis1) == -originalFixedAxis1, "Vertical fixed-point delta has the wrong sign")
        try expect(event.getIntegerValueField(.scrollWheelEventFixedPtDeltaAxis2) == -originalFixedAxis2, "Horizontal fixed-point delta has the wrong sign")
    }

    private static func leavesContinuousScrollEventsUnchanged() throws {
        guard let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 1,
            wheel1: 12,
            wheel2: 0,
            wheel3: 0
        ) else {
            throw CheckFailure.mismatch("Could not create a continuous scroll event")
        }

        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        let originalDelta = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)

        try expect(!ScrollEventTransformer.reverseLineBasedScroll(event), "Continuous event was incorrectly reversed")
        try expect(event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1) == originalDelta, "Continuous event was modified")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else {
            throw CheckFailure.mismatch(message)
        }
    }

    private static func hasOppositeSign(_ original: Int64, _ transformed: Int64) -> Bool {
        (original > 0 && transformed < 0) || (original < 0 && transformed > 0) || (original == 0 && transformed == 0)
    }
}
