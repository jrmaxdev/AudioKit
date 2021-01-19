// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

#if !os(tvOS)
import CoreMIDI

private extension UInt8 {
    static func status(_ type: MIDIData.ChannelVoice, _ channel: UInt8) -> Self {
        type.rawValue << 4 + channel
    }
}

public extension Array where Element == UInt8 {

    // MARK: channel voice

    static func noteOff(channel: UInt8 = 0, number: UInt8, velocity: UInt8 = 0x40) -> Self {
        [.status(.noteOff, channel), number, velocity]
    }

    static func noteOn(channel: UInt8 = 0, number: UInt8, velocity: UInt8) -> Self {
        [.status(.noteOn, channel), number, velocity]
    }

    static func polyPressure(group: UInt8 = 0, channel: UInt8 = 0, number: UInt8, value: UInt8) -> Self {
        [.status(.polyPressure, channel), number, value]
    }

    static func controlChange(group: UInt8 = 0, channel: UInt8 = 0, number: UInt8, value: UInt8) -> Self {
        [.status(.controlChange, channel), number, value]
    }

    static func programChange(channel: UInt8 = 0, number: UInt8) -> Self {
        [.status(.programChange, channel), number]
    }

    static func channelPressure(channel: UInt8 = 0, value: UInt8) -> Self {
        [.status(.channelPressure, channel), value]
    }

    static func pitchBend(group: UInt8 = 0, channel: UInt8 = 0, lsb: UInt8, msb: UInt8) -> Self {
        [.status(.pitchBend, channel), lsb, msb]
    }

    // MARK: sysex

    static func sysexComplete(data: [UInt8]) -> Self {
        [MIDIData.SysexOpCode.start.rawValue] + data + [MIDIData.SysexOpCode.end.rawValue]
    }

    static func sysexStart(data: [UInt8]) -> Self {
        [MIDIData.SysexOpCode.start.rawValue] + data
    }

    static func sysexContinue(data: [UInt8]) -> Self {
        data
    }

    static func sysexEnd(data: [UInt8]) -> Self {
        data + [MIDIData.SysexOpCode.end.rawValue]
    }

    // MARK: system common

    static func tuneRequest() -> Self {
        [MIDIData.SystemCommon.tuneRequest.rawValue]
    }

    static func songPosition(lsb: UInt8, msb: UInt8) -> Self {
        [MIDIData.SystemCommon.songPosition.rawValue, lsb, msb]
    }

    static func timeCodeQuarterFrame(value: UInt8) -> Self {
        [MIDIData.SystemCommon.timeCodeQuarterFrame.rawValue, value]
    }

    static func songSelect(number: UInt8) -> Self {
        [MIDIData.SystemCommon.songSelect.rawValue, number]
    }

    // MARK: real time

    static var timingClock: Self {
        [MIDIData.RealTime.timingClock.rawValue]
    }

    static var start: Self {
        [MIDIData.RealTime.start.rawValue]
    }

    static var stop: Self {
        [MIDIData.RealTime.stop.rawValue]
    }

    static var `continue`: Self {
        [MIDIData.RealTime.continue.rawValue]
    }

    static var activeSensing: Self {
        [MIDIData.RealTime.activeSensing.rawValue]
    }

    static var reset: Self {
        [MIDIData.RealTime.reset.rawValue]
    }
}
#endif
