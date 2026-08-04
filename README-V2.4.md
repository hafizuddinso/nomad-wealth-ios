# Nomad Wealth Native iOS v2.4 Compile Fix

This build preserves all v2.3 features and fixes the remaining SwiftUI compile errors.

Fixes:
- Uses explicit `Color.secondary`, `Color.red`, and `Color.green` in conditional foreground styles.
- Corrects Swift string interpolation in budget, travel, account, and transaction labels.
- Removes the unnecessary local transaction currency constant while preserving account-based currency display.

No user-facing feature was removed or changed.
