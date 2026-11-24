<p align="center">
  <img src="Branding/avatar.png" width="128" alt="Skrrt">
</p>

<p align="center">
  <img src="Branding/wordmark-blue.png" width="260" alt="Skrrt">
</p>

<p align="center">A fast, private WebKit browser for iPhone, built with SwiftUI and Liquid Glass.</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-26%2B-0A84FF?style=flat-square&logo=apple&logoColor=white" alt="iOS 26+">
  <img src="https://img.shields.io/badge/Swift-6-0A84FF?style=flat-square&logo=swift&logoColor=white" alt="Swift 6">
  <img src="https://img.shields.io/badge/engine-WebKit-0A84FF?style=flat-square" alt="WebKit">
  <img src="https://img.shields.io/badge/license-GPL--3.0-0A84FF?style=flat-square" alt="GPL-3.0">
</p>

## Features

- Liquid Glass interface with an address bar that collapses while you scroll
- Tabs with a visual switcher and private tabs
- Ad and tracker blocking powered by WebKit content rules
- Protection badge under the Dynamic Island, tap it to switch the shield
- Hidden addresses that turn into a living dot field until you tap them
- Bookmarks and history with search
- Site mode switch: Safari, Chrome or Desktop
- Google search from the address bar
- Light, dark and system appearance

## Install

Add the source in AltStore or SideStore:

```
https://raw.githubusercontent.com/yunseen/skrrt/main/altstore.json
```

You can also download the latest `.ipa` from the Releases page and install it with Sideloadly.

## Build from source

Requires Xcode 26 and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```
xcodegen generate
open Skrrt.xcodeproj
```

## Structure

```
Skrrt/
  App/        entry point and root layout
  Browser/    address bar, toolbar, start page, protection badge
  Tabs/       tab model, session store, tab switcher
  Web/        WKWebView container, delegate, content blocker, search
  Library/    bookmarks and history
  Settings/   settings model and screens
  Privacy/    address concealing
  Theme/      palette and animated background
  Resources/  asset catalog and block list
Branding/     logos and avatars
```

## License

Released under the GNU General Public License v3.0.
