// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

#if !os(tvOS)
import CoreMIDI

enum MIDIData: Equatable {

    enum ChannelVoice: UInt8 {
        case noteOff = 0x8
        case noteOn = 0x9
        case polyPressure = 0xA
        case controlChange = 0xB
        case programChange = 0xC
        case channelPressure = 0xD
        case pitchBend = 0xE
        var numDataBytes: Int {
            switch self {
            case .programChange, .channelPressure: return 1
            default: return 2
            }
        }
    }

    enum SystemCommon: UInt8 {
        case timeCodeQuarterFrame = 0xF1
        case songPosition = 0xF2
        case songSelect = 0xF3
        case tuneRequest = 0xF6
    }

    enum SysexType: UInt8 {
        case complete
        case start
        case `continue`
        case end
    }

    enum SysexOpCode: UInt8 {
        case start = 0xF0
        case end = 0xF7
    }

    enum RealTime: UInt8 {
        case timingClock = 0xF8
        case start = 0xFA
        case `continue` = 0xFB
        case stop = 0xFC
        case activeSensing = 0xFE
        case reset = 0xFF
    }

    // channel voice
    case channelVoice(MIDIBytes)

    // system common
    case timeCodeQuarterFrame(group: UInt8 = 0, value: UInt8)
    case songPosition(group: UInt8 = 0, lsb: UInt8, msb: UInt8)
    case songSelect(group: UInt8 = 0, number: UInt8)
    case tuneRequest(group: UInt8 = 0)

    // sysex
    case sysex(group: UInt8 = 0, type: SysexType, data: [UInt8])

    // realtime
    case realtime(group: UInt8 = 0, type: RealTime)
}

extension MIDIData {
    // MARK: channel voice
    static func noteOff(group: UInt8 = 0, channel: UInt8 = 0, number: UInt8, velocity: UInt8 = 0x40) -> Self {
        .channelVoice(.noteOff(group: group, channel: channel, number: number, velocity: velocity))
    }

    static func noteOn(group: UInt8 = 0, channel: UInt8 = 0, number: UInt8, velocity: UInt8) -> Self {
        .channelVoice(.noteOn(group: group, channel: channel, number: number, velocity: velocity))
    }

    static func polyPressure(group: UInt8 = 0, channel: UInt8 = 0, number: UInt8, value: UInt8) -> Self {
        .channelVoice(.polyPressure(group: group, channel: channel, number: number, value: value))
    }

    static func controlChange(group: UInt8 = 0, channel: UInt8 = 0, number: UInt8, value: UInt8) -> Self {
        .channelVoice(.controlChange(group: group, channel: channel, number: number, value: value))
    }

    static func programChange(group: UInt8 = 0, channel: UInt8 = 0, number: UInt8) -> Self {
        .channelVoice(.programChange(group: group, channel: channel, number: number))
    }

    static func channelPressure(group: UInt8 = 0, channel: UInt8 = 0, value: UInt8) -> Self {
        .channelVoice(.channelPressure(group: group, channel: channel, value: value))
    }

    static func pitchBend(group: UInt8 = 0, channel: UInt8 = 0, lsb: UInt8, msb: UInt8) -> Self {
        .channelVoice(.pitchBend(group: group, channel: channel, lsb: lsb, msb: msb))
    }

    static func timingClock(group: UInt8 = 0) -> Self {
        .realtime(group: group, type: .timingClock)
    }

    static func start(group: UInt8 = 0) -> Self {
        .realtime(group: group, type: .start)
    }

    static func `continue`(group: UInt8 = 0) -> Self {
        .realtime(group: group, type: .continue)
    }

    static func stop(group: UInt8 = 0) -> Self {
        .realtime(group: group, type: .stop)
    }

    static func activeSensing(group: UInt8 = 0) -> Self {
        .realtime(group: group, type: .activeSensing)
    }

    static func reset(group: UInt8 = 0) -> Self {
        .realtime(group: group, type: .reset)
    }

    static func sysexComplete(group: UInt8 = 0, data: [UInt8]) -> Self {
        .sysex(group: group, type: .complete, data: data)
    }

    static func sysexStart(group: UInt8 = 0, data: [UInt8]) -> Self {
        .sysex(group: group, type: .start, data: data)
    }

    static func sysexContinue(group: UInt8 = 0, data: [UInt8]) -> Self {
        .sysex(group: group, type: .continue, data: data)
    }

    static func sysexEnd(group: UInt8 = 0, data: [UInt8]) -> Self {
        .sysex(group: group, type: .end, data: data)
    }
}

extension MIDIData: CustomStringConvertible {
    var description: String {
        switch self {
        case .channelVoice(let bytes):
            if let type = bytes.channelVoiceType {
                return "\(type)(\(bytes.fieldsDescription))"
            }
            return "channelVoice(\(bytes.fieldsDescription))"
        case .timeCodeQuarterFrame(let group, let value):
            return "timeCodeQuarterFrame(group: \(group), value: \(value))"
        case .songPosition(let group, let lsb, let msb):
            return "songPosition(group: \(group), lsb: \(lsb), msb: \(msb)"
        case .songSelect(let group, let number):
            return "songSelect(group: \(group), number: \(number))"
        case .tuneRequest(let group):
            return "tuneRequest(group: \(group)"
        case .sysex(let group, let type, let data):
            return "sysex(group: \(group), type: \(type), data: \(data))"
        case .realtime(let group, let type):
            return "\(type)(group: \(group)"
        }
    }
}

#endif
