# TestDrive

A multi-platform Xcode project for experimenting with various iOS, iPadOS, watchOS, and macOS development concepts.

## Overview

This repository serves as a testing ground for different development ideas across Apple's platforms. Each branch contains specific experiments or feature implementations.

## Platforms

- **iOS** - Primary development platform
- **iPadOS** - Tablet-optimized features and layouts
- **watchOS** - Apple Watch companion features (occasional)
- **macOS** - Desktop application experiments (occasional)

## Branch Structure

Different branches are used to isolate and test various concepts. Check the branch list to explore specific features or experiments.

**Important:** Never commit directly to `main`. The main branch serves as a clean starting point for new experiments. Always create a new branch for your work.

## Getting Started

1. Clone the repository
2. Open the `.xcodeproj` file in Xcode
3. Select your target platform and device
4. Build and run

## Requirements

- Xcode (latest version recommended)
- macOS development environment
- iOS/iPadOS Simulator or physical device for testing

---

## Documentation

### Audit Log System

A comprehensive audit logging system for tracking all vault, credential, and secret operations. Provides complete visibility into "who did what and when" for compliance, security monitoring, and user accountability.

**📖 [Read the complete Audit Log documentation →](./AUDIT_LOG.md)**

**Key Features:**
- Complete activity tracking (create, update, delete, copy, reveal, rotate, share, revoke)
- User attribution via CloudKit integration
- Unified timeline across all entity types
- Rich JSON-based metadata
- CloudKit sync across all devices
- Performance optimized with async logging and comprehensive indexes
- Privacy-conscious (no secret values logged, userIDs pseudonymized)

**Quick Links:**
- [Why Audit Logging?](./AUDIT_LOG.md#why-audit-logging)
- [Architecture Overview](./AUDIT_LOG.md#architecture)
- [Data Model & Schema](./AUDIT_LOG.md#data-model)
- [Services (UserContextService, AuditLogger)](./AUDIT_LOG.md#services)
- [Integration Points](./AUDIT_LOG.md#integration-points)
- [User Interface Design](./AUDIT_LOG.md#user-interface)
- [Implementation Roadmap](./AUDIT_LOG.md#implementation-roadmap)
- [Verification Checklist](./AUDIT_LOG.md#verification-checklist)

### Other Documentation

- [CloudKit Setup Guide](./CLOUDKIT_SETUP.md)
- [CloudKit Sharing Implementation](./CLOUDKIT_SHARING_IMPL.md)
- [Sharing Guide](./SHARING_GUIDE.md)
- [Implementation Summary](./IMPLEMENTATION_SUMMARY.md)
- [Release Notes](./RELEASE_NOTES.md)
- [Testing Checklist](./TESTING_CHECKLIST.md)
- [Features](./Features.md)