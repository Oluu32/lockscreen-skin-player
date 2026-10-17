# Lock Skin Player

A small SwiftUI player for audio files you choose in Files. It copies imported files into the app's Documents folder, keeps a local library, and uses AVAudioPlayer, background audio, MPNowPlayingInfoCenter and MPRemoteCommandCenter. The selected retro-inspired theme is rendered as the track's cover image. Four themes: Classic Green, Amber LCD, Midnight Blue and Ruby Deck. This changes the artwork inside Apple's system Now Playing widget; it does not reskin the system controls or other apps' widgets. The artwork's bars and buttons are decorative. There is no Live Activity in this first version.

## Build

Open Actions > Build unsigned IPA > Run workflow, or push to main. The workflow uses a macOS runner, XcodeGen and `xcodebuild archive` with signing disabled. It packages `LockSkinPlayer.app` into `Payload/` and uploads `LockSkinPlayer-unsigned.ipa` in the `LockSkinPlayer-unsigned-IPA` artifact. Download and unzip the GitHub Actions artifact to get the IPA. This IPA is unsigned and is not an App Store build. Source deployment target: iOS 16.0. No signing material or secrets are included.

## Install with Sideloadly

1. On a PC, install Sideloadly and Apple's iTunes/iCloud drivers from the official Sideloadly instructions. Connect and trust your iPhone (USB or supported Wi-Fi sync).
2. Download the workflow artifact from the successful run and unzip it. Drag `LockSkinPlayer-unsigned.ipa` into Sideloadly and select your device.
3. Let Sideloadly sign it with your own Apple ID and install it. If iOS asks, trust your developer profile in Settings > General > VPN & Device Management. You may need to enable Developer Mode in Settings > Privacy & Security and restart the phone.
4. Open the app, tap Import audio and choose playable files from Files. Press play, lock the phone, then choose a skin in the app to change the Now Playing cover. This has not been tested on Dami's device.

Free Apple ID sideloaded apps generally expire after seven days and require re-signing; Apple imposes other free provisioning limits. Do not put your Apple ID or password into this repository or its workflow. Sideloadly handles signing on your PC. The unsigned IPA may still need compatible iOS and a working Sideloadly setup.

## Apple Music

Not included in this first version. Apple Music playback requires a separate MusicKit integration, an Apple Music subscription for catalog playback, and developer setup with the required Apple Developer key/token and capabilities. A free Apple ID cannot provide the paid developer setup needed for this integration. Do not embed developer private keys in this repository or an IPA. Other apps' Now Playing widgets, including Spotify's, cannot be skinned by this app.

## Limits

File formats are limited to what iOS `AVAudioPlayer` can decode; protected and DRM media are not imported. Artwork is static rather than an animated visualizer. The library is local to this app and may disappear when the app is removed. No App Store submission or device test is part of this repository.
