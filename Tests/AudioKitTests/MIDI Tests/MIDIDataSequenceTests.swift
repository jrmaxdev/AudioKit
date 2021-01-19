// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

@testable import AudioKit
import XCTest

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

extension MIDIDataSequence {
    var elements: [MIDIData] {
        .init(self)
    }
}

extension MIDIDataSequence where Bytes == [UInt8] {
    init(_ bytes: [[UInt8]]) {
        self.init(bytes: Array(bytes.joined()))
    }
}

class MIDIDataSequenceTests: XCTestCase {

    // MARK: channel voice
    func testNoteOff() throws {
        let bytes: [[UInt8]] = [.noteOff(channel: 2, number: 3, velocity: 4)]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.noteOff(channel: 2, number: 3, velocity: 4)])
    }

    func testNoteOn() throws {
        let bytes: [[UInt8]] = [.noteOn(channel: 2, number: 3, velocity: 4)]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.noteOn(channel: 2, number: 3, velocity: 4)])
    }

    func testPolyPressure() throws {
        let bytes: [[UInt8]] = [.polyPressure(channel: 2, number: 3, value: 4)]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.polyPressure(channel: 2, number: 3, value: 4)])
    }

    func testControlChange() throws {
        let bytes: [[UInt8]] = [.controlChange(channel: 2, number: 3, value: 4)]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.controlChange(channel: 2, number: 3, value: 4)])
    }

    func testProgramChange() throws {
        let bytes: [[UInt8]] = [.programChange(channel: 2, number: 3)]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.programChange(channel: 2, number: 3)])
    }

    func testChannelPressure() throws {
        let bytes: [[UInt8]] = [.channelPressure(channel: 2, value: 3)]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.channelPressure(channel: 2, value: 3)])
    }

    func testPitchBend() throws {
        let bytes: [[UInt8]] = [.pitchBend(channel: 2, lsb: 3, msb: 4)]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.pitchBend(channel: 2, lsb: 3, msb: 4)])
    }

    // MARK: system common

    func testTimeCodeQuarterFrame() throws {
        let bytes: [[UInt8]] = [.timeCodeQuarterFrame(value: 34)]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.timeCodeQuarterFrame(value: 34)])
    }

    func testSongPosition() throws {
        let bytes: [[UInt8]] = [.songPosition(lsb: 3, msb: 4)]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.songPosition(lsb: 3, msb: 4)])
    }

    func testSongSelect() throws {
        let bytes: [[UInt8]] = [.songSelect(number: 34)]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.songSelect(number: 34)])
    }

    func testTuneReset() throws {
        let bytes: [[UInt8]] = [.tuneRequest()]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.tuneRequest()])
    }

    // MARK: real time

    func testTimingClock() {
        let bytes: [[UInt8]] = [.timingClock]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.timingClock()])
    }

    func testStart() {
        let bytes: [[UInt8]] = [.start]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.start()])
    }

    func testContinue() {
        let bytes: [[UInt8]] = [.continue]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.continue()])
    }

    func testStop() {
        let bytes: [[UInt8]] = [.stop]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.stop()])
    }

    func testActiveSensing() {
        let bytes: [[UInt8]] = [.activeSensing]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.activeSensing()])
    }

    func testReset() throws {
        let bytes: [[UInt8]] = [.reset]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.reset()])
    }

    // MARK: sysex

    func testSysexComplete() throws {
        let bytes: [[UInt8]] = [.sysexComplete(data: [3, 4, 5, 6])]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.sysex(type: .complete, data: [3, 4, 5, 6])])
    }

    func testSysexStart() throws {
        let bytes: [[UInt8]] = [.sysexStart(data: [3, 4, 5, 6])]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.sysex(type: .start, data: [3, 4, 5, 6])])
    }

    func testSysexContinue() throws {
        let bytes: [[UInt8]] = [.sysexContinue(data: [3, 4, 5, 6])]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.sysex(type: .continue, data: [3, 4, 5, 6])])
    }

    func testSysexEnd() throws {
        let bytes: [[UInt8]] = [.sysexEnd(data: [3, 4, 5, 6])]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.sysex(type: .end, data: [3, 4, 5, 6])])
    }

    // MARK: edge cases

    func testNoteOnThreeTimes() throws {
        let bytes: [[UInt8]] = [.noteOn(channel: 1, number: 2, velocity: 3),
                                .noteOn(channel: 1, number: 2, velocity: 3),
                                .noteOn(channel: 1, number: 2, velocity: 3)]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.noteOn(channel: 1, number: 2, velocity: 3),
                                           .noteOn(channel: 1, number: 2, velocity: 3),
                                           .noteOn(channel: 1, number: 2, velocity: 3)])
    }

    func testNoteOffRunningStatus() throws {
        let bytes: [[UInt8]] = [.noteOff(number: 13, velocity: 14),
                                .noteOffRunning(number: 15, velocity: 16)]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.noteOff(number: 13, velocity: 14), .noteOff(number: 15, velocity: 16)])
    }

    func testNoteOffTooShort() throws {
        let bytes: [[UInt8]] = [.noteOffTooShort(number: 13)]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [])
    }

    func testNoteOffWithRealTimeInbetween() throws {
        let bytes: [[UInt8]] = [.noteOffWithRealTimeInbetween(number: 13)]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.realtime(type: .reset), .realtime(type: .reset), .noteOff(number: 13)])
    }

    func testNoteOffTooShortFollowedByStatus() throws {
        let bytes: [[UInt8]] = [.noteOffTooShort(number: 13), .noteOff(number: 14)]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.noteOff(number: 14)])
    }

    func testNoteOnVelocity0() throws {
        let bytes: [[UInt8]] = [.noteOn(number: 3, velocity: 0)]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.noteOff(number: 3, velocity: 0x40)])
    }

    func testSongPositionTooShort() throws {
        let bytes: [[UInt8]] = [.songPositionPointerTooShort(lsb: 3)]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [])
    }

    func testSongPositionTooShortFollowedByStatus() throws {
        let bytes: [[UInt8]] = [.songPositionPointerTooShort(lsb: 3), .noteOff(number: 4)]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.noteOff(number: 4)])
    }

    func testSongSelectTooShort() throws {
        let bytes: [[UInt8]] = [.songSelectTooShort()]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [])
    }

    func testSongSelectTooShortFollowedByStatus() throws {
        let bytes: [[UInt8]] = [.songSelectTooShort(), .noteOff(number: 3)]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.noteOff(number: 3)])
    }

    func testSystemCommonReserved() throws {
        let bytes: [[UInt8]] = [.systemCommonReserved()]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [])
    }

    func testSysexStartDelimitedByStatus() throws {
        let bytes: [[UInt8]] = [.sysexStart(data: [3, 4, 5, 6]), .noteOff(number: 3)]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.sysex(type: .start, data: [3, 4, 5, 6]), .noteOff(number: 3)])
    }

    func testSysexContinueDelimitedByStatus() throws {
        let bytes: [[UInt8]] = [.sysexContinue(data: [3, 4, 5, 6]), .noteOff(number: 3)]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [.sysex(type: .continue, data: [3, 4, 5, 6]), .noteOff(number: 3)])
    }

    func testRealTimeReserved() throws {
        let bytes: [[UInt8]] = [.realTimeReserved()]
        let sequence = MIDIDataSequence(bytes)
        XCTAssertEqual(sequence.elements, [])
    }
}
