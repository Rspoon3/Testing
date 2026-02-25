import Dependencies
import Foundation
import SQLiteData

/// Persistence adapter for account-level key-wrap metadata.
final class AccountMetadataStore: @unchecked Sendable {
    /// Store-level errors.
    enum StoreError: Error {
        case accountNotFound
        case deviceEnrollmentNotFound
        case unsupportedRecoveryKDFVersion(Int)
        case bootstrapAccountMismatch
    }

    @Dependency(\.defaultDatabase) private var database

    /// Saves account root wraps and first device enrollment atomically.
    func saveBootstrap(_ wraps: AccountRootWraps, _ enrollment: DeviceEnrollment) throws {
        guard wraps.accountID == enrollment.accountID else {
            throw StoreError.bootstrapAccountMismatch
        }

        let wrapsRow = Self.rootWrapRow(from: wraps)
        let enrollmentRow = Self.deviceEnrollmentRow(from: enrollment)

        try database.write { db in
            try AccountRootWrapRow.where { $0.id.eq(wraps.accountID) }
                .delete()
                .execute(db)
            try AccountRootWrapRow.insert { wrapsRow }
                .execute(db)

            try DeviceEnrollmentRow.where { $0.id.eq(enrollment.deviceID) }
                .delete()
                .execute(db)
            try DeviceEnrollmentRow.insert { enrollmentRow }
                .execute(db)
        }
    }

    /// Saves (or replaces) account root wraps for one account.
    func saveRootWraps(_ wraps: AccountRootWraps) throws {
        let row = Self.rootWrapRow(from: wraps)
        try database.write { db in
            try AccountRootWrapRow.where { $0.id.eq(wraps.accountID) }
                .delete()
                .execute(db)
            try AccountRootWrapRow.insert { row }
                .execute(db)
        }
    }

    /// Loads account root wraps by account identifier.
    func loadRootWraps(accountID: UUID) throws -> AccountRootWraps {
        guard let row = try database.read({ db in
            try AccountRootWrapRow.where { $0.id.eq(accountID) }
                .fetchOne(db)
        }) else {
            throw StoreError.accountNotFound
        }
        guard let recoveryKDFVersion = RecoveryWrapKeyDerivationVersion(rawValue: row.recoveryKDFVersion) else {
            throw StoreError.unsupportedRecoveryKDFVersion(row.recoveryKDFVersion)
        }

        return AccountRootWraps(
            accountID: row.id,
            recoverySalt: row.recoverySalt,
            recoveryKDFVersion: recoveryKDFVersion,
            arkKeyID: row.arkKeyID,
            recoveryWrappedByKeyID: row.recoveryWrappedByKeyID,
            recoveryCryptoVersion: row.recoveryCryptoVersion,
            recoveryAADVersion: row.recoveryAADVersion,
            wrappedARKByRecovery: row.wrappedARKByRecovery,
            syncWrappedByKeyID: row.syncWrappedByKeyID,
            syncCryptoVersion: row.syncCryptoVersion,
            syncAADVersion: row.syncAADVersion,
            wrappedARKBySync: row.wrappedARKBySync
        )
    }

    /// Loads the first account root wraps row, if one exists.
    func loadFirstRootWraps() throws -> AccountRootWraps? {
        guard let row = try database.read({ db in
            try AccountRootWrapRow
                .order { $0.id.asc() }
                .fetchOne(db)
        }) else { return nil }
        guard let recoveryKDFVersion = RecoveryWrapKeyDerivationVersion(rawValue: row.recoveryKDFVersion) else {
            throw StoreError.unsupportedRecoveryKDFVersion(row.recoveryKDFVersion)
        }

        return AccountRootWraps(
            accountID: row.id,
            recoverySalt: row.recoverySalt,
            recoveryKDFVersion: recoveryKDFVersion,
            arkKeyID: row.arkKeyID,
            recoveryWrappedByKeyID: row.recoveryWrappedByKeyID,
            recoveryCryptoVersion: row.recoveryCryptoVersion,
            recoveryAADVersion: row.recoveryAADVersion,
            wrappedARKByRecovery: row.wrappedARKByRecovery,
            syncWrappedByKeyID: row.syncWrappedByKeyID,
            syncCryptoVersion: row.syncCryptoVersion,
            syncAADVersion: row.syncAADVersion,
            wrappedARKBySync: row.wrappedARKBySync
        )
    }

    /// Saves (or replaces) one device enrollment.
    func saveDeviceEnrollment(_ enrollment: DeviceEnrollment) throws {
        let row = Self.deviceEnrollmentRow(from: enrollment)
        try database.write { db in
            try DeviceEnrollmentRow.where { $0.id.eq(enrollment.deviceID) }
                .delete()
                .execute(db)
            try DeviceEnrollmentRow.insert { row }
                .execute(db)
        }
    }

    /// Loads one device enrollment for a given account and device.
    func loadDeviceEnrollment(accountID: UUID, deviceID: UUID) throws -> DeviceEnrollment {
        guard let row = try database.read({ db in
            try DeviceEnrollmentRow
                .where { $0.id.eq(deviceID) }
                .where { $0.accountID.eq(accountID) }
                .fetchOne(db)
        }) else {
            throw StoreError.deviceEnrollmentNotFound
        }

        return DeviceEnrollment(
            accountID: row.accountID,
            deviceID: row.id,
            arkKeyID: row.arkKeyID,
            wrappedByKeyID: row.wrappedByKeyID,
            cryptoVersion: row.cryptoVersion,
            aadVersion: row.aadVersion,
            wrappedARKByDevice: row.wrappedARKByDevice
        )
    }

    /// Loads the first enrolled device for an account.
    func loadFirstDeviceEnrollment(accountID: UUID) throws -> DeviceEnrollment? {
        guard let row = try database.read({ db in
            try DeviceEnrollmentRow
                .where { $0.accountID.eq(accountID) }
                .order { $0.id.asc() }
                .fetchOne(db)
        }) else { return nil }

        return DeviceEnrollment(
            accountID: row.accountID,
            deviceID: row.id,
            arkKeyID: row.arkKeyID,
            wrappedByKeyID: row.wrappedByKeyID,
            cryptoVersion: row.cryptoVersion,
            aadVersion: row.aadVersion,
            wrappedARKByDevice: row.wrappedARKByDevice
        )
    }

    var client: AccountMetadataClient {
        AccountMetadataClient(
            saveBootstrap: { wraps, enrollment in
                try self.saveBootstrap(wraps, enrollment)
            },
            saveRootWraps: { wraps in
                try self.saveRootWraps(wraps)
            },
            loadRootWraps: { accountID in
                try self.loadRootWraps(accountID: accountID)
            },
            saveDeviceEnrollment: { enrollment in
                try self.saveDeviceEnrollment(enrollment)
            },
            loadDeviceEnrollment: { accountID, deviceID in
                try self.loadDeviceEnrollment(accountID: accountID, deviceID: deviceID)
            }
        )
    }

    private static func rootWrapRow(from wraps: AccountRootWraps) -> AccountRootWrapRow {
        AccountRootWrapRow(
            id: wraps.accountID,
            recoverySalt: wraps.recoverySalt,
            recoveryKDFVersion: wraps.recoveryKDFVersion.rawValue,
            arkKeyID: wraps.arkKeyID,
            recoveryWrappedByKeyID: wraps.recoveryWrappedByKeyID,
            recoveryCryptoVersion: wraps.recoveryCryptoVersion,
            recoveryAADVersion: wraps.recoveryAADVersion,
            wrappedARKByRecovery: wraps.wrappedARKByRecovery,
            syncWrappedByKeyID: wraps.syncWrappedByKeyID,
            syncCryptoVersion: wraps.syncCryptoVersion,
            syncAADVersion: wraps.syncAADVersion,
            wrappedARKBySync: wraps.wrappedARKBySync
        )
    }

    private static func deviceEnrollmentRow(from enrollment: DeviceEnrollment) -> DeviceEnrollmentRow {
        DeviceEnrollmentRow(
            id: enrollment.deviceID,
            accountID: enrollment.accountID,
            arkKeyID: enrollment.arkKeyID,
            wrappedByKeyID: enrollment.wrappedByKeyID,
            cryptoVersion: enrollment.cryptoVersion,
            aadVersion: enrollment.aadVersion,
            wrappedARKByDevice: enrollment.wrappedARKByDevice
        )
    }
}
