// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

#if !os(tvOS)
import CoreMIDI

private extension UInt8 {
    static let firstRealTime = MIDISystemCommand.clock.rawValue
    static let firstSystem = MIDISystemCommand.sysEx.rawValue
    static let sysexStart = MIDISystemCommand.sysEx.rawValue
    var highNibble: UInt8 {
        get {
            self >> 4
        }
        set {
            self = self & 0x0F + newValue << 4
        }
    }
}

struct MIDIDataSequence<Bytes: RandomAccessCollection> : Sequence, IteratorProtocol
where Bytes.Element == UInt8, Bytes.Index == Int {

    var bytes: Bytes
    var index: Int
    private var builder: Builder?

    init(bytes: Bytes) {
        self.bytes = bytes
        index = bytes.startIndex
    }
}

extension MIDIDataSequence {
    @discardableResult
    mutating func pop() -> UInt8? {
        guard bytes.indices.contains(index) else {
            return nil
        }
        defer {
            index += 1
        }
        return bytes[index]
    }

    func peek() -> UInt8? {
        guard bytes.indices.contains(index) else {
            return nil
        }
        return bytes[index]
    }
}

private enum BuildResult {
    case building(MIDIData? = nil)
    case finished(MIDIData? = nil)
    case failed(MIDIData? = nil)
}

private protocol Builder {
    mutating func add(_ byte: UInt8?) -> BuildResult
}

extension MIDIDataSequence {

    private struct SysexBuilder: Builder {
        enum SysexBuilderType {
            case startOrComplete
            case continueOrEnd
        }

        var type: SysexBuilderType
        var data: [UInt8]

        mutating func add(_ byte: UInt8?) -> BuildResult {
            guard let byte = byte  else {
                switch type {
                case .startOrComplete:
                    return .finished(.sysex(type: .start, data: data))
                case .continueOrEnd:
                    return .finished(.sysex(type: .continue, data: data))
                }
            }
            if byte < 128 {
                data.append(byte)
                return .building()
            }
            if byte == MIDIData.SysexOpCode.end.rawValue {
                switch type {
                case .startOrComplete:
                    return .finished(.sysex(type: .complete, data: data))
                case .continueOrEnd:
                    return .finished(.sysex(type: .end, data: data))
                }
            } else {
                switch type {
                case .startOrComplete:
                    return .failed(.sysex(type: .start, data: data))
                case .continueOrEnd:
                    return .failed(.sysex(type: .continue, data: data))
                }
            }
        }

        static func continueOrEnd(first: UInt8) -> Self {
            .init(type: .continueOrEnd, data: [first])
        }

        static func startOrComplete() -> Self {
            .init(type: .startOrComplete, data: [])
        }
    }

    private struct ChannelVoiceBuilder: Builder {
        var data: MIDIBytes
        let numBytes: Int
        var dataIndex = 0
        init(status: UInt8) {
            data = MIDIBytes(status: status)
            numBytes = MIDIData.ChannelVoice(rawValue: status.highNibble)!.numDataBytes
        }
        mutating func add(_ byte: UInt8?) -> BuildResult {
            guard let byte = byte else {
                return .failed()
            }
            guard byte < 128 else {
                return .failed()
            }
            switch dataIndex {
            case 0:
                dataIndex = 1
                data.data1 = byte
                if numBytes > 1 {
                    return .building()
                }
                return .building(.channelVoice(data))
            default:
                if byte == 0 && data.status.highNibble == MIDIData.ChannelVoice.noteOn.rawValue {
                    data.status.highNibble = MIDIData.ChannelVoice.noteOff.rawValue
                    data.data2 = 0x40
                } else {
                    data.data2 = byte
                }
                dataIndex = 0
                return .building(.channelVoice(data))
            }
        }
    }

    private struct SongPositionBuilder: Builder {
        var lsb: UInt8 = 0
        var dataIndex = 0
        mutating func add(_ byte: UInt8?) -> BuildResult {
            guard let byte = byte else {
                return .failed()
            }
            guard byte < 128 else {
                return .failed()
            }
            switch dataIndex {
            case 0:
                lsb = byte
                dataIndex = 1
                return .building()
            default:
                return .finished(.songPosition(lsb: lsb, msb: byte))
            }
        }
    }

    private struct SystemCommonBuilder: Builder {
        let finish: (UInt8) -> MIDIData
        init(finish: @escaping (UInt8) -> MIDIData) {
            self.finish = finish
        }
        mutating func add(_ byte: UInt8?) -> BuildResult {
            guard let byte = byte else {
                return .failed()
            }
            guard byte < 128 else {
                return .failed()
            }
            return .finished(finish(byte))
        }
    }
}

extension MIDIDataSequence {
    public mutating func next() -> MIDIData? {

        while true {
            guard let byte = peek() else {
                if builder != nil {
                    guard let data = build(with: nil) else {
                        return nil
                    }
                    return data
                }
                return nil
            }
            if byte >= .firstRealTime {
                pop()
                guard let type = MIDIData.RealTime(rawValue: byte) else {
                    continue
                }
                return .realtime(type: type)
            }
            if builder != nil {
                guard let data = build(with: byte) else {
                    continue
                }
                return data
            }
            if byte < 128 {
                builder = SysexBuilder.continueOrEnd(first: byte)
                pop()
                continue
            }
            if byte < .firstSystem {
                builder = ChannelVoiceBuilder(status: byte)
                pop()
                continue
            }
            if byte == .sysexStart {
                builder = SysexBuilder.startOrComplete()
                pop()
                continue
            }
            pop()
            if let data = systemCommon(with: byte) {
                return data
            }
        }
    }

    private mutating func build(with byte: UInt8?) -> MIDIData? {
        switch builder!.add(byte) {
        case .building(let event):
            pop()
            return event
        case .finished(let event):
            pop()
            self.builder = nil
            return event
        case .failed(let event):
            self.builder = nil
            return event
        }
    }

    private mutating func systemCommon(with byte: UInt8) -> MIDIData? {
        switch byte {
        case MIDIData.SystemCommon.tuneRequest.rawValue:
            return .tuneRequest()
        case MIDIData.SystemCommon.timeCodeQuarterFrame.rawValue:
            builder = SystemCommonBuilder { byte in
                .timeCodeQuarterFrame(value: byte)
            }
            return nil
        case MIDIData.SystemCommon.songSelect.rawValue:
            builder = SystemCommonBuilder { byte in
                .songSelect(number: byte)
            }
            return nil
        case MIDIData.SystemCommon.songPosition.rawValue:
            builder = SongPositionBuilder()
            return nil
        default:
            return nil
        }
    }
}

#endif
