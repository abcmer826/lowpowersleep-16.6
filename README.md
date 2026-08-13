# LowPowerSleep iOS 16.6

Fork/build configuration based on the original Hoangdus LowPowerSleep tweak.

## What changed

The original tweak used `_CDBatterySaver`. This version uses the iOS 15/16 `_PMLowPowerMode` runtime class while preserving the original lock/unlock behavior.

## GitHub Actions

The workflow builds two packages automatically:

- Rootless: `LowPowerSleep-0.0.1-rootless-iOS16.deb`
- Roothide: `LowPowerSleep-0.0.1-roothide-iOS16.deb`

Open **Actions → Build LowPowerSleep iOS 16.6 → Run workflow** after the files are committed. The two DEBs are provided as workflow artifacts.

The build uses an iOS 16.5 SDK for compiling this tweak for iOS 16.x; runtime behavior is intended for iOS 16.6.

## Credits

Original project by Hoangdus: https://github.com/Hoangdus/LowPowerSleep
