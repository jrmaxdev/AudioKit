// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

#if !os(tvOS)
import CoreMIDI

import CoreMIDI

public extension MIDIPacket {
    /// Mimics MIDIPacket.ByteCollection for systems prior to iOS 13.0 or OSX 14.0.
    typealias LegacyByteCollection = UnsafeBufferPointer<UInt8>
}

extension UnsafePointer where Pointee == MIDIPacket {
    private static let dataOffset = MemoryLayout<MIDIPacket>.offset(of: \MIDIPacket.data)!
    private var dataPointer: UnsafePointer<UInt8> {
        (UnsafeRawPointer(self) + Self.dataOffset).assumingMemoryBound(to: UInt8.self)
    }

    /// Mimics MIDIPacketPointer.bytes() for systems prior to iOS 13.0 or OSX 14.0.
    public func legacyBytes()-> MIDIPacket.LegacyByteCollection {
        return .init(start: dataPointer, count: Int(pointee.length))
    }
}

#endif
