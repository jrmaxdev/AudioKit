// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

@testable import AudioKit
import XCTest
import CoreMIDI

private extension UInt8 {
    static func status(_ type: MIDIData.ChannelVoice, _ channel: UInt8) -> Self {
        type.rawValue << 4 + channel
    }
}

private extension Array where Element == UInt8 {

    static func noteOffRunning(number: UInt8, velocity: UInt8 = 0x40) -> Self {
        [number, velocity]
    }

    static func noteOffTooShort(channel: UInt8 = 0, number: UInt8) -> Self {
        [.status(.noteOff, channel), number]
    }

    static func noteOffWithRealTimeInbetween(channel: UInt8 = 0, number: UInt8, velocity: UInt8 = 0x40) -> Self {
        [.status(.noteOff, channel),
         MIDIData.RealTime.reset.rawValue,
         number,
         MIDIData.RealTime.reset.rawValue,
         velocity]
    }

    static func songPositionPointerTooShort(lsb: UInt8) -> Self {
        [MIDIData.SystemCommon.songPosition.rawValue, lsb]
    }

    static func songSelectTooShort() -> Self {
        [MIDIData.SystemCommon.songSelect.rawValue]
    }

    static func systemCommonReserved() -> Self {
        [MIDIData.SystemCommon.songSelect.rawValue + 1]
    }

    static func realTimeReserved() -> Self {
        [MIDIData.RealTime.stop.rawValue + 1]
    }
}

private extension MIDIBytePacketList {
    convenience init(_ bytes: [UInt8] ...) {
        self.init(timeStamp: 0, bytes: Array(bytes.joined()))
    }

    convenience init(_ bytes: [[UInt8]]) {
        self.init(timeStamp: 0, bytes: Array(bytes.joined()))
    }
}

private extension UnsafePointer where Pointee == MIDIPacketList {
    var firstPacketData: [MIDIData]? {
        var iterator = unsafePacketSequence().makeIterator()
        guard let packet = iterator.next() else {
            return nil
        }
        return Array(packet.unsafeMIDIData())
    }
}

class ByteParsingTests: XCTestCase {

    func assertEqual(packed bytes: [[UInt8]], unpacket expected: [MIDIData]) {
        let list = MIDIBytePacketList(bytes)
        let unpackedData = list.withUnsafePointer(\.firstPacketData)
        XCTAssertEqual(unpackedData, expected)
    }

    func testNoteOff() throws {
        assertEqual(packed: [.noteOff(channel: 1, number: 2, velocity: 3)],
                    unpacket: [.noteOff(channel: 1, number: 2, velocity: 3)])
    }

    func testNoteOn() throws {
        assertEqual(packed: [.noteOn(channel: 2, number: 3, velocity: 4)],
                    unpacket: [.noteOn(channel: 2, number: 3, velocity: 4)])
    }

    func testPolyPressure() throws {
        assertEqual(packed: [.polyPressure(channel: 2, number: 3, value: 4)],
                    unpacket: [.polyPressure(channel: 2, number: 3, value: 4)])
    }

    func testControlChange() throws {
        assertEqual(packed: [.controlChange(channel: 2, number: 3, value: 4)],
                    unpacket: [.controlChange(channel: 2, number: 3, value: 4)])
    }

    func testProgramChange() throws {
        assertEqual(packed: [.programChange(channel: 2, number: 3)],
                    unpacket: [.programChange(channel: 2, number: 3)])
    }

    func testChannelPressure() throws {
        assertEqual(packed: [.channelPressure(channel: 2, value: 3)],
                    unpacket: [.channelPressure(channel: 2, value: 3)])
    }

    func testPitchBend() throws {
        assertEqual(packed: [.pitchBend(channel: 2, lsb: 3, msb: 4)],
                    unpacket: [.pitchBend(channel: 2, lsb: 3, msb: 4)])
    }

    // MARK: system common

    func testTimeCodeQuarterFrame() throws {
        assertEqual(packed: [.timeCodeQuarterFrame(value: 34)],
                    unpacket: [.timeCodeQuarterFrame(value: 34)])
    }

    func testSongPosition() throws {
        assertEqual(packed: [.songPosition(lsb: 3, msb: 4)],
                    unpacket: [.songPosition(lsb: 3, msb: 4)])
    }

    func testSongSelect() throws {
        assertEqual(packed: [.songSelect(number: 34)],
                    unpacket: [.songSelect(number: 34)])
    }

    func testTuneReset() throws {
        assertEqual(packed: [.tuneRequest()],
                    unpacket: [.tuneRequest()])
    }

    // MARK: real time

    func testTimingClock() {
        assertEqual(packed: [.timingClock],
                    unpacket: [.timingClock()])
    }

    func testStart() {
        assertEqual(packed: [.start],
                    unpacket: [.start()])
    }

    func testContinue() {
        assertEqual(packed: [.continue],
                    unpacket: [.continue()])
    }

    func testStop() {
        assertEqual(packed: [.stop],
                    unpacket: [.stop()])
    }

    func testActiveSensing() {
        assertEqual(packed: [.activeSensing],
                    unpacket: [.activeSensing()])
    }

    func testReset() throws {
        assertEqual(packed: [.reset],
                    unpacket: [.reset()])
    }

    // MARK: sysex

    func testSysexComplete() throws {
        assertEqual(packed: [.sysexComplete(data: [3, 4, 5, 6])],
                    unpacket: [.sysexComplete(data: [3, 4, 5, 6])])
    }

    func testSysexStart() throws {
        assertEqual(packed: [.sysexStart(data: [3, 4, 5, 6])],
                    unpacket: [.sysexStart(data: [3, 4, 5, 6])])
    }

    func testSysexContinue() throws {
        assertEqual(packed: [.sysexContinue(data: [3, 4, 5, 6])],
                    unpacket: [.sysexContinue(data: [3, 4, 5, 6])])
    }

    func testSysexEnd() throws {
        assertEqual(packed: [.sysexEnd(data: [3, 4, 5, 6])],
                    unpacket: [.sysexEnd(data: [3, 4, 5, 6])])
    }

    // MARK: edge cases

    func testNoteOnThreeTimes() throws {
        assertEqual(packed: [.noteOn(channel: 1, number: 2, velocity: 3),
                             .noteOn(channel: 1, number: 2, velocity: 3),
                             .noteOn(channel: 1, number: 2, velocity: 3)],
                    unpacket: [.noteOn(channel: 1, number: 2, velocity: 3),
                               .noteOn(channel: 1, number: 2, velocity: 3),
                               .noteOn(channel: 1, number: 2, velocity: 3)])
    }

    func testNoteOffRunningStatus() throws {
        assertEqual(packed: [.noteOff(number: 13, velocity: 14),
                             .noteOffRunning(number: 15, velocity: 16)],
                    unpacket: [.noteOff(number: 13, velocity: 14),
                               .noteOff(number: 15, velocity: 16)])
    }

    func testNoteOffTooShort() throws {
        assertEqual(packed: [.noteOffTooShort(number: 13)],
                    unpacket: [])
    }

    func testNoteOffWithRealTimeInbetween() throws {
        assertEqual(packed: [.noteOffWithRealTimeInbetween(number: 13)],
                    unpacket: [.realtime(type: .reset),
                               .realtime(type: .reset),
                               .noteOff(number: 13)])
    }

    func testNoteOffTooShortFollowedByStatus() throws {
        assertEqual(packed: [.noteOffTooShort(number: 13), .noteOff(number: 14)],
                    unpacket: [.noteOff(number: 14)])
    }

    func testNoteOnVelocity0() throws {
        assertEqual(packed: [.noteOn(number: 3, velocity: 0)],
                    unpacket: [.noteOff(number: 3, velocity: 0x40)])
    }

    func testSongPositionTooShort() throws {
        assertEqual(packed: [.songPositionPointerTooShort(lsb: 3)],
                    unpacket: [])
    }

    func testSongPositionTooShortFollowedByStatus() throws {
        assertEqual(packed: [.songPositionPointerTooShort(lsb: 3), .noteOff(number: 4)],
                    unpacket: [.noteOff(number: 4)])
    }

    func testSongSelectTooShort() throws {
        assertEqual(packed: [.songSelectTooShort()],
                    unpacket: [])
    }

    func testSongSelectTooShortFollowedByStatus() throws {
        assertEqual(packed: [.songSelectTooShort(), .noteOff(number: 3)],
                    unpacket: [.noteOff(number: 3)])
    }

    func testSystemCommonReserved() throws {
        assertEqual(packed: [.systemCommonReserved()],
                    unpacket: [])
    }

    func testSysexStartDelimitedByStatus() throws {
        assertEqual(packed: [.sysexStart(data: [3, 4, 5, 6]),
                             .noteOff(number: 3)],
                    unpacket: [.sysexStart(data: [3, 4, 5, 6]),
                               .noteOff(number: 3)])
    }

    func testSysexContinueDelimitedByStatus() throws {
        assertEqual(packed: [.sysexContinue(data: [3, 4, 5, 6]),
                             .noteOff(number: 3)],
                    unpacket: [.sysexContinue(data: [3, 4, 5, 6]),
                               .noteOff(number: 3)])
    }

    func testRealTimeReserved() throws {
        assertEqual(packed: [.realTimeReserved()],
                    unpacket: [])
    }
}
