// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

#if !os(tvOS)
import CoreMIDI

extension UnsafePointer where Pointee == MIDIPacket {
    func unsafeMIDIData() -> MIDIDataSequence<MIDIPacket.LegacyByteCollection> {
        MIDIDataSequence(bytes: legacyBytes())
    }
}

#endif
