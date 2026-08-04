# Nomad Wealth Native iOS v2

## Added
- Home Screen long-press quick actions: Share Nomad Wealth, Add Transaction, Open Dashboard
- Standard iOS Share Sheet with AirDrop support
- Connected weekly/monthly/yearly budgets
- Shared expense category list
- Empty forms with instructional placeholders
- Investment add/edit and performance chart
- Travel mode
- Currency converter in More/Settings area
- Profile picture selection and removal
- Time-based dashboard greeting (already present)
- Improved loans with account connection, deposit and automatic repayment expense

## Important sharing limitation
The long-press Share action shares a download/website link through AirDrop. iOS does not allow an installed app binary to be copied directly from the Home Screen.

## Build
1. Open `NomadWealth.xcodeproj`.
2. Select the NomadWealth target.
3. Choose your iPhone or simulator.
4. Press Run.
5. Launch the app once, return to the Home Screen, then long-press the app icon.

## Cloud note
Authentication uses the existing Supabase project. This package preserves the app's existing local finance store. Full website-to-iOS record synchronization still requires a dedicated Global v7 cloud adapter matching the live website payload and should be tested against a staging Supabase project before production use.
