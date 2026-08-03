# Nomad Wealth Native iOS v1.4

This is a real SwiftUI application. It does not use WebView and does not load the website.

Included:
- Local signup and login
- Dashboard
- Money In and Money Out
- Accounts and balance adjustments
- Recent transaction history
- Budgets
- Loans, automatic installment calculation and payment history
- Calculator
- Dark/light/system appearance
- Five font styles
- First 1 million Coming Soon goal
- Offline local storage using UserDefaults

## Install on your iPhone

1. Delete the previous Nomad Wealth test app from the iPhone.
2. Restart the iPhone and Xcode.
3. Enable Developer Mode:
   Settings → Privacy & Security → Developer Mode
4. Connect the phone by cable and unlock it.
5. Open `NomadWealth.xcodeproj`.
6. Select the NomadWealth target → Signing & Capabilities.
7. Select your Personal Team.
8. Keep Automatically manage signing enabled.
9. Change the Bundle Identifier if Xcode asks. Example:
   `com.hafizuddin.nomadwealthnative2026`
10. Choose your connected iPhone as the run destination.
11. In Xcode use Product → Clean Build Folder.
12. Press Run.

## If CoreDeviceError 3002 appears again

- Click Show Details and find the first `Failure Reason` or `IXUserPresentableErrorDomain` line.
- Delete the old app from the iPhone.
- Xcode → Settings → Accounts → select your Apple Account → Manage Certificates.
- Make sure an Apple Development certificate exists.
- Window → Devices and Simulators → select the iPhone and wait until it is fully connected.
- Clean Build Folder and run again.

This project uses a generated Info.plist to avoid malformed-bundle installation problems.


## v1.1 compatibility fix

This version removes the iOS 16.1-only `fontDesign` modifier.

The project still targets iOS 16.0, and font styles now use:

`font(.system(.body, design: ...))`

Before running:

1. Delete the older extracted project folder.
2. Open this v1.1 project.
3. Product → Clean Build Folder.
4. Select your iPhone and press Run.


## v1.2 authentication fix

The native app now uses the same Supabase authentication as the website.

You can log in with the same email and password used on the Nomad Wealth website.

Important:
- If the account requires email confirmation, confirm it before logging in.
- Internet access is required for login and signup.
- Financial data is still stored locally on the iPhone in this version.
- Authentication tokens are stored in the iOS Keychain.


## v1.3 charts, animation and interaction upgrade

Included:
- Native Swift Charts on Dashboard
- Six-month income vs expense chart
- Spending-by-category donut chart
- Account balance chart
- Loan repayment chart
- 30-day Analytics screen
- Animated card entrances and chart switching
- Standard iOS button press animation
- Haptic feedback for important actions
- Loading state for login and signup
- Smooth native sheets for Money In and Money Out
- Improved save animations and feedback
- All existing finance features retained

The minimum deployment target remains iOS 16.0 because Swift Charts is available from iOS 16.


## v1.3.1 iOS 16 compatibility fix

Removed the iOS 17-only welcome animation APIs:
- symbolEffect
- pulse
- repeating symbol effects

The welcome logo now uses an iOS 16-compatible scale and opacity animation.

Minimum deployment target remains iOS 16.0.


## v1.3.2 complete iOS 16 chart compatibility

Removed the iOS 17-only `SectorMark` used by the spending-category donut chart.

The category chart is now a horizontal native Swift Charts bar chart compatible with iOS 16.

Also removed the numeric content-transition modifier to avoid newer availability requirements.

Verified that the Swift source no longer contains:
- SectorMark
- symbolEffect
- pulse symbol effect
- numericText content transition
- fontDesign


## v1.3.3 Supabase authentication key fix

The previous native build contained a mistyped Supabase anonymous API key.

This version uses the exact Supabase URL and anon key from the working Nomad Wealth website configuration.

Before testing:
1. Delete the old app from the iPhone.
2. Open this v1.3.3 Xcode project.
3. Product → Clean Build Folder.
4. Run it again on the iPhone.
5. Log in with the same confirmed email and password used on the website.


## v1.4 web-style native UI

- Dashboard now greets the signed-in user by name.
- Added a profile shortcut on the Dashboard.
- Rebuilt the public home page to follow the Nomad Wealth website design.
- Added native feature cards and a finance preview before login.
- Rebuilt Settings as a polished Profile screen.
- Profile now includes avatar, user details, app statistics, appearance, font and currency controls.
- Existing Supabase authentication, charts, accounts, transactions, loans, budgets and calculators remain unchanged.
