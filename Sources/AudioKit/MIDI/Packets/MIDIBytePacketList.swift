// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

#if !os(tvOS)
import CoreMIDI

extension MIDIPacketList {
    public static let maxByteSize = 65_536
    static let firstPacketDataOffset = MemoryLayout<MIDIPacketList>.offset(of: \MIDIPacketList.packet)!
        + MemoryLayout<MIDIPacket>.offset(of: \MIDIPacket.data)!

    static func acceptableSize(from inSize: Int) -> Int {

        var size = MemoryLayout<MIDIPacketList>.size

        if inSize > size {
            if inSize > maxByteSize {
                size = maxByteSize
            } else {
                size = inSize
            }
        }
        return size
    }
}

/// Mimics MIDIPacketList.Builder for systems prior to iOS 13.0 or OSX 14.0.
public final class MIDIBytePacketList {

    public let listByteSize: Int
    private let memory: UnsafeMutableRawPointer
    private let list: UnsafeMutablePointer<MIDIPacketList>
    private (set) var currentPacket: UnsafeMutablePointer<MIDIPacket>?

    public init(listByteSize: Int = MemoryLayout<MIDIPacketList>.size) {
        self.listByteSize = MIDIPacketList.acceptableSize(from: listByteSize)
        memory = UnsafeMutableRawPointer.allocate(
            byteCount: listByteSize,
            alignment: MemoryLayout<MIDIPacketList>.alignment)
        list = memory.bindMemory(to: MIDIPacketList.self, capacity: 1)
        currentPacket = MIDIPacketListInit(list)
    }

    public convenience init(packetDataSize: Int) {
        self.init(listByteSize: packetDataSize + MIDIPacketList.firstPacketDataOffset)
    }

    public convenience init(timeStamp: MIDITimeStamp, bytes: [UInt8]) {
        self.init(packetDataSize: bytes.count)
        _ = append(timeStamp: timeStamp, bytes: bytes)
    }

    deinit {
        memory.deallocate()
    }

    public func append(timeStamp: MIDITimeStamp, bytes: [UInt8]) -> Bool {
        currentPacket = MIDIPacketListAdd(list, listByteSize, currentPacket!, timeStamp, bytes.count, bytes)
        guard currentPacket != nil else {
            return false
        }
        return true
    }

    public func withUnsafePointer<Result>(
        _ block: (UnsafePointer<MIDIPacketList>) throws -> Result) rethrows -> Result {
        return try block(list)
    }
}

#endif
