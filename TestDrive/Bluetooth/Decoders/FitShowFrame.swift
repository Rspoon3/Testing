//
//  FitShowFrame.swift
//  TestDrive
//

import Foundation

/// One framed packet from a FitShow-app treadmill.
///
/// Every FitShow packet has the same envelope:
///
/// ```
/// ┌──────┬─────┬─────┬─────────────┬──────────┬──────┐
/// │ 0x02 │ cmd │ par │ payload…    │ checksum │ 0x03 │
/// └──────┴─────┴─────┴─────────────┴──────────┴──────┘
///   [0]    [1]   [2]   [3…n-3]        [n-2]      [n-1]
/// ```
///
/// The checksum is an XOR of every byte from index 1 up to and including index
/// `n - 3` — that is, the command, the parameter, and the payload, but not the
/// header, the checksum itself, or the footer.
///
/// That envelope is what makes this protocol safe to probe. `FFF0`/`FFF1` are
/// generic vendor UUIDs shared by a great many unrelated BLE gadgets, so a value
/// arriving on one proves nothing on its own. A payload that opens with `0x02`,
/// closes with `0x03`, and carries a checksum that actually verifies is strong
/// evidence the machine really is speaking FitShow.
struct FitShowFrame {

    /// The byte every frame starts with.
    static let header: UInt8 = 0x02

    /// The byte every frame ends with.
    static let footer: UInt8 = 0x03

    /// The shortest possible frame: header, command, checksum, footer.
    static let minimumLength = 4

    /// The command byte, identifying the packet family.
    let command: UInt8

    /// The parameter byte, identifying the variant within the family.
    ///
    /// `nil` for a frame too short to carry one.
    let parameter: UInt8?

    /// The payload bytes between the parameter and the checksum.
    let payload: Data

    /// The checksum byte as transmitted.
    let transmittedChecksum: UInt8

    /// The checksum recomputed from the received bytes.
    let computedChecksum: UInt8

    /// The whole frame as received, for hex display.
    let rawFrame: Data

    // MARK: - Public Helpers

    /// Whether the transmitted checksum matches the recomputed one.
    var isChecksumValid: Bool { transmittedChecksum == computedChecksum }

    /// The command family this frame belongs to.
    var family: Family { Family(rawValue: command) ?? .unknown }

    /// The packet families a FitShow machine sends.
    enum Family: UInt8 {
        /// Machine capabilities: speed and incline limits, model, factory date.
        case info = 0x50

        /// Live status, including the running telemetry frame.
        case status = 0x51

        /// Session data: cumulative totals and the workout mode.
        case data = 0x52

        /// Acknowledgement of a control command.
        case control = 0x53

        /// A console key press.
        case key = 0x54

        /// A command byte this app does not recognise.
        case unknown = 0x00

        /// A readable name for the family.
        var name: String {
            switch self {
            case .info: "System Info"
            case .status: "System Status"
            case .data: "System Data"
            case .control: "System Control"
            case .key: "Console Key"
            case .unknown: "Unknown"
            }
        }
    }

    // MARK: - Initializer

    /// Parses a raw characteristic value as a FitShow frame.
    ///
    /// Returns `nil` when the envelope does not match, so a caller can fall back to
    /// a plain hex dump rather than presenting a misparse as fact. A frame whose
    /// checksum fails is still returned — ``isChecksumValid`` reports it — because
    /// seeing a corrupt frame is more useful than seeing nothing.
    /// - Parameter data: The raw characteristic value.
    init?(_ data: Data) {
        let bytes = [UInt8](data)

        guard bytes.count >= Self.minimumLength,
              bytes[0] == Self.header,
              bytes[bytes.count - 1] == Self.footer else {
            return nil
        }

        let checksumIndex = bytes.count - 2
        var checksum: UInt8 = 0
        for index in 1..<checksumIndex {
            checksum ^= bytes[index]
        }

        self.command = bytes[1]
        self.parameter = checksumIndex > 2 ? bytes[2] : nil
        self.payload = checksumIndex > 3 ? Data(bytes[3..<checksumIndex]) : Data()
        self.transmittedChecksum = bytes[checksumIndex]
        self.computedChecksum = checksum
        self.rawFrame = data
    }
}
