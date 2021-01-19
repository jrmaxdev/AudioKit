// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

#if !os(tvOS)
import CoreMIDI

struct MIDIBytes: Equatable {
    var group: UInt8 = 0
    var status: UInt8 = 0
    var data1: UInt8 = 0
    var data2: UInt8 = 0

    init(group: UInt8 = 0, status: UInt8) {
        self.group = group
        self.status = status
    }

    init(group: UInt8 = 0, status: UInt8, data1: UInt8, data2: UInt8 = 0) {
        self.group = group
        self.status = status
        self.data1 = data1
        self.data2 = data2
    }

    var fieldsDescription: String {
        "group: \(group), status: \(status), data1: \(data1), data2: \(data2)"
    }
}

private extension UInt8 {
    static func status(_ type: MIDIData.ChannelVoice, _ channel: UInt8) -> Self {
        type.rawValue << 4 + channel
    }
}

extension MIDIBytes {
    var channelVoiceType: MIDIData.ChannelVoice? {
        MIDIData.ChannelVoice(rawValue: status >> 4)
    }
}

extension MIDIBytes {
    static func noteOff(group: UInt8 = 0, channel: UInt8 = 0, number: UInt8, velocity: UInt8 = 0x40) -> Self {
        .init(group: group, status: .status(.noteOff, channel), data1: number, data2: velocity)
    }

    static func noteOn(group: UInt8 = 0, channel: UInt8 = 0, number: UInt8, velocity: UInt8) -> Self {
        .init(group: group, status: .status(.noteOn, channel), data1: number, data2: velocity)
    }

    static func polyPressure(group: UInt8 = 0, channel: UInt8 = 0, number: UInt8, value: UInt8) -> Self {
        .init(group: group, status: .status(.polyPressure, channel), data1: number, data2: value)
    }

    static func controlChange(group: UInt8 = 0, channel: UInt8 = 0, number: UInt8, value: UInt8) -> Self {
        .init(group: group, status: .status(.controlChange, channel), data1: number, data2: value)
    }

    static func programChange(group: UInt8 = 0, channel: UInt8 = 0, number: UInt8) -> Self {
        .init(group: group, status: .status(.programChange, channel), data1: number)
    }

    static func channelPressure(group: UInt8 = 0, channel: UInt8 = 0, value: UInt8) -> Self {
        .init(group: group, status: .status(.channelPressure, channel), data1: value)
    }

    static func pitchBend(group: UInt8 = 0, channel: UInt8 = 0, lsb: UInt8, msb: UInt8) -> Self {
        .init(group: group, status: .status(.pitchBend, channel), data1: lsb, data2: msb)
    }
}
#endif
