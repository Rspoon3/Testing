# Shared Vault Policy

This sample includes a sharing authorization scaffold for shared-vault key distribution:

- ``VaultShareRole``
- ``SharedVaultProvisioningPolicy``

## Rules

- Owner:
  - Can provision any participant/device.
  - Can modify membership.
  - Can rotate vault key.
- Writer:
  - Can edit content in higher layers of the app.
  - Can provision any participant/device.
  - Cannot rotate vault key.
- Viewer:
  - Can self-provision own additional devices only.
  - Cannot provision other participants.
  - Cannot modify membership.
  - Cannot rotate vault key.

## Scope

This module intentionally keeps these checks in a pure policy layer. CloudKit integration and server-side enforcement are outside this minimal sample, but this policy is structured to be reusable by those implementations.
