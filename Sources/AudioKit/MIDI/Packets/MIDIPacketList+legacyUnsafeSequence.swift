// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

#if !os(tvOS)
import CoreMIDI

extension UnsafePointer where Pointee == MIDIPacketList {

    private static let packetOffset = MemoryLayout<MIDIPacketList>.offset(of: \MIDIPacketList.packet)!

    internal var packetPointer: UnsafePointer<MIDIPacket> {
        (UnsafeRawPointer(self) + Self.packetOffset).assumingMemoryBound(
            to: MIDIPacket.self)
    }
}

extension MIDIPacketList {
    // swiftlint:disable nesting

    /// Mimics MIDIPacketList.UnsafeSequence for systems prior to iOS 13.0 or OSX 14.0.
    public struct LegacyUnsafeSequence: Sequence {

        let packetList: UnsafePointer<MIDIPacketList>

        init(_ list: UnsafePointer<MIDIPacketList>) {
            self.packetList = list
        }

        public func makeIterator() -> MIDIPacketList.LegacyUnsafeSequence.Iterator {
            return MIDIPacketList.LegacyUnsafeSequence.Iterator(self)
        }

        public var count: Int {
            return Int(packetList.pointee.numPackets)
        }

        public struct Iterator: IteratorProtocol {

            let count: Int
            var currentPacketIndex = 0
            var currentPacket: UnsafePointer<MIDIPacket>

            public init(_ sequence: MIDIPacketList.LegacyUnsafeSequence) {
                count = sequence.count

                currentPacket = sequence.packetList.packetPointer
            }

            public mutating func next() -> UnsafePointer<MIDIPacket>? {
                guard currentPacketIndex <  count else {
                    return nil
                }
                defer {
                    currentPacket = UnsafePointer<MIDIPacket>(MIDIPacketNext(currentPacket))
                    currentPacketIndex += 1
                }
                return currentPacket
            }

            public typealias Element = UnsafePointer<MIDIPacket>
        }

        public typealias Element = UnsafePointer<MIDIPacket>
    }
}

public extension UnsafePointer where Pointee == MIDIPacketList {

    /// Mimics MIDIPacketListPointer.unsafeSequence() for systems prior to iOS 13.0 or OSX 14.0.
    func unsafePacketSequence() -> MIDIPacketList.LegacyUnsafeSequence {
        MIDIPacketList.LegacyUnsafeSequence(self)
    }
}

#endif
