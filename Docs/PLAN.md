# vietKey — Kế hoạch thiết kế bộ gõ tiếng Việt cho macOS

> Bản tổng hợp sau 4 vòng rà soát. Đây là tài liệu chốt để bắt đầu code.
> Ngày: 2026-11-20

## Trạng thái (2026-11-20)

Giai đoạn 1–5 đã được cài đặt; build sạch, 41 test của package đều qua. Chưa chạy thử gõ thật
trên máy (cần `Scripts/install-dev.sh` + bật nguồn nhập), chưa notarize.

Khác biệt so với plan:
- `VowelUnit` → `Letter` + `LetterMod` (gồm cả đ).
- `VietKeyCore` được liên kết như package local; app và target test `vietKeyTests` dùng `VietEngine`, `VietCharset`.
- Tên hiển thị là **VIET**; bundle ID giữ `htq.inputmethod.vietKey`.
- Bundle ID `htq.inputmethod.vietKey`; app chỉ chạy IMKServer khi nằm trong `~/Library/Input Methods`,
  ở nơi khác thì mở cửa sổ cài đặt.
- Thêm file: `HotkeyMonitor`, `InputModeSwitcher` (chuyển chế độ V/E qua TIS), `DisplayNames`,
  `VIQRCodec`, `InfoPlist.xcstrings` (tên chế độ gõ trong menu), `Scripts/notarize.sh`.
- Kiểm tra chính tả + khôi phục chạy khi kết thúc từ (dấu cách, dấu câu), không chạy giữa từ.

---

## 1. Mục tiêu

Bộ gõ tiếng Việt kiểu UniKey, chạy native trên macOS, có:

- Kiểu gõ: Telex (cơ bản + mở rộng), VNI, VIQR
- Đặt dấu thanh đúng quy tắc, chọn kiểu cũ (hòa) hoặc kiểu mới (hoà)
- Gõ dấu tự do, gõ lặp phím để huỷ dấu, kiểm tra chính tả, khôi phục từ tiếng Anh
- Gõ tắt (macro), nhớ trạng thái V/E theo từng ứng dụng
- Công cụ chuyển mã clipboard (Unicode / TCVN3 / VNI-Windows / VIQR, bỏ dấu)
- Icon V/E trên menu bar, chuyển bằng phím tắt

---

## 2. Quyết định kỹ thuật đã chốt

| Vấn đề | Quyết định | Lý do |
|---|---|---|
| Cách bắt phím | **InputMethodKit (IMK)** | Là Input Source chính thức, không cần quyền Accessibility, an toàn với ô mật khẩu, hệ thống tự lo icon menu bar |
| Ngôn ngữ | **100% Swift** | Gọi IMK/AppKit trực tiếp, Swift Testing có sẵn, tái dùng được cho bàn phím iOS. Rust/C++ chỉ thêm FFI mà không thêm giá trị vì engine xử lý < 10 ký tự mỗi phím |
| Số process | **1 app duy nhất** = Input Method + cửa sổ Settings | Không cần App Group, không đồng bộ liên process, không bị 2 icon |
| Icon menu bar | Dùng **ô Input Source của hệ thống**, khai báo **2 input mode `vi` / `en`** | Hệ thống tự đổi icon V/E, không cần `NSStatusItem` hay `MenuBarExtra` |
| Info.plist | `LSUIElement = YES` (không dùng `LSBackgroundOnly`) | Để cửa sổ Settings nhận được focus |
| Xuất chữ ra app | Mặc định **marked text**; tuỳ chọn **thay thế trực tiếp** theo từng app | Marked text ổn định nhất; thay thế trực tiếp không có gạch chân nhưng một số app không hỗ trợ |
| Phân phối | **Ngoài App Store**, ký Developer ID + notarize, **không sandbox** | IM phải nằm trong `~/Library/Input Methods/`, app sandbox không tự copy vào được |
| Engine | `struct`, `Sendable`, **chỉ dùng Swift stdlib**, không Foundation/AppKit | Test độc lập, có thể port sang nền tảng khác |
| Deployment target | macOS 14+ | `@Observable`, SwiftUI Settings hiện đại |
| Concurrency | Swift 6 strict concurrency, controller trên MainActor | |

### Không dùng lại mã nguồn UniKey / OpenKey

UniKey dùng giấy phép GPL. Nếu tái sử dụng, toàn bộ app phải mở mã theo GPL. Viết lại từ đầu.

---

## 3. Cấu trúc thư mục

```
vietKey/
├── vietKey.xcodeproj
├── plan.md
│
├── Scripts/
│   └── install-dev.sh                 build → copy vào ~/Library/Input Methods → pkill → đăng ký lại
│
├── Packages/VietKeyCore/              Swift Package local, toàn bộ logic, không UI
│   ├── Package.swift
│   ├── Sources/
│   │   ├── VietEngine/                ← stdlib-only
│   │   │   ├── Model/
│   │   │   │   ├── KeyInput.swift             phím đầu vào, độc lập NSEvent
│   │   │   │   ├── EngineOutput.swift         deleteCount (UTF-16), insert, committed, consumed
│   │   │   │   ├── Syllable.swift             phụ âm đầu, nguyên âm, phụ âm cuối, thanh, mask chữ hoa
│   │   │   │   ├── Letter.swift               base + LetterMod (circumflex / breve / horn / stroke)
│   │   │   │   └── ToneMark.swift             ToneMark + LetterMod
│   │   │   ├── InputMethods/
│   │   │   │   ├── InputMethod.swift          protocol + KeyAction
│   │   │   │   ├── Telex.swift                cơ bản + mở rộng ([ ] w)
│   │   │   │   ├── VNI.swift
│   │   │   │   └── VIQR.swift
│   │   │   ├── Phonology/
│   │   │   │   ├── Initials.swift             bảng phụ âm đầu hợp lệ
│   │   │   │   ├── Rhymes.swift               bảng vần hợp lệ
│   │   │   │   ├── SpellChecker.swift
│   │   │   │   └── TonePlacer.swift           đặt dấu kiểu cũ / mới
│   │   │   ├── Core/
│   │   │   │   ├── VietEngine.swift           API công khai: process / reset / commit
│   │   │   │   ├── SyllableBuilder.swift      dựng lại âm tiết từ rawKeys
│   │   │   │   ├── Renderer.swift             Syllable → chuỗi Unicode
│   │   │   │   └── OutputDiff.swift           chỉ dùng cho chế độ thay thế trực tiếp
│   │   │   ├── Macro/
│   │   │   │   ├── MacroTable.swift
│   │   │   │   ├── MacroExpander.swift
│   │   │   │   └── MacroFileFormat.swift      nhập/xuất định dạng UniKey/OpenKey (key:value)
│   │   │   └── EngineOptions.swift            struct cấu hình, Sendable
│   │   │
│   │   └── VietCharset/               ← được dùng Foundation (NFC/NFD)
│   │       ├── Charset.swift                  unicode / unicodeNFD / tcvn3 / vniWin / viqr
│   │       ├── Tables/
│   │       │   ├── TCVN3Table.swift
│   │       │   └── VNIWindowsTable.swift
│   │       ├── CharsetConverter.swift         chuyển hai chiều
│   │       └── ToneStripper.swift             bỏ dấu
│   │
│   └── Tests/VietKeyCoreTests/
│       ├── Engine/
│       │   ├── TelexTests.swift
│       │   ├── VNITests.swift
│       │   ├── VIQRTests.swift
│       │   ├── TonePlacerTests.swift
│       │   ├── SpellCheckerTests.swift
│       │   ├── BackspaceTests.swift
│       │   ├── MacroTests.swift
│       │   └── DictionaryRoundTripTests.swift  gõ lại toàn bộ âm tiết sinh từ Initials × Rhymes × Tones
│       ├── Charset/
│       │   └── CharsetConverterTests.swift
│       ├── Fixtures/
│       └── PerformanceTests.swift              mục tiêu < 1ms mỗi phím
│
├── vietKey/                           ← 1 target: Input Method + Settings
│   ├── main.swift                             IMKServer + NSApplication.run
│   ├── InputMethod/
│   │   ├── VKInputController.swift            mỏng: map phím → engine → xuất chữ; giữ engine state
│   │   ├── KeyEventMapper.swift               NSEvent → KeyInput (theo event.characters, không theo keyCode)
│   │   ├── IMMenu.swift                       menu của icon Input Source
│   │   └── Output/
│   │       ├── OutputStrategy.swift           protocol
│   │       ├── MarkedTextStrategy.swift       mặc định
│   │       ├── DirectReplaceStrategy.swift    giai đoạn 5
│   │       └── StrategyResolver.swift         chọn theo bundle ID app đích
│   ├── Settings/
│   │   ├── AppSettings.swift                  @Observable, lưu UserDefaults.standard, sinh EngineOptions
│   │   ├── SettingsWindow.swift
│   │   ├── Tabs/
│   │   │   ├── GeneralTab.swift
│   │   │   ├── InputMethodTab.swift
│   │   │   ├── MacroTab.swift
│   │   │   ├── AppRulesTab.swift
│   │   │   └── ConverterTab.swift
│   │   └── Components/
│   │       └── HotkeyRecorder.swift
│   ├── Installer/
│   │   └── InputSourceInstaller.swift         copy vào ~/Library/Input Methods, TISRegister / TISEnable
│   ├── Logging/
│   │   └── Log.swift                          os.Logger, subsystem com.<you>.vietKey
│   ├── Resources/
│   │   ├── vi.tiff, en.tiff                   icon 2 input mode
│   │   ├── Localizable.xcstrings              UI Việt / Anh
│   │   └── Assets.xcassets
│   ├── Info.plist
│   └── vietKey.entitlements
│
└── Docs/
    ├── README.md                              kiến trúc + dev setup + phạm vi
    └── TONE_RULES.md                          quy tắc đặt dấu
```

### Quy tắc phụ thuộc

```
VietEngine    ← không phụ thuộc gì (stdlib)
VietCharset   ← Foundation
vietKey (app) → VietEngine, VietCharset, InputMethodKit, SwiftUI
```

Không module nào được phụ thuộc ngược. `VKInputController` không chứa logic tiếng Việt.

---

## 4. Thiết kế engine

### 4.1 Luồng xử lý một phím

```
key ─► phân loại ─┬─ phím ngắt từ (space, dấu câu, Enter, mũi tên) ─► commit + reset
                  ├─ Backspace ─► bỏ phím cuối trong rawKeys, dựng lại cả từ
                  ├─ Cmd / Ctrl / Option + phím ─► commit, cho qua
                  └─ chữ cái / số ─► rawKeys.append ─► SyllableBuilder.rebuild(rawKeys)
                                                        │
                       ┌────────────────────────────────┘
                       ▼
              Syllable ─► SpellChecker hợp lệ?
                       │ có   → TonePlacer → Renderer → chuỗi mới
                       │ không → (nếu bật khôi phục) trả về rawKeys nguyên gốc
                       ▼
              EngineOutput → OutputStrategy xuất ra app
```

**Nguyên tắc cốt lõi:** mỗi phím mới, engine **dựng lại cả âm tiết từ `rawKeys`**, không vá dần. Backspace, gõ dấu tự do, khôi phục từ sai đều trở nên đơn giản và test được chắc chắn. `n ≤ ~10` nên luôn dưới 50µs.

### 4.2 Bảng kiểu gõ (dạng dữ liệu, không viết cứng)

| Chức năng | Telex | VNI | VIQR |
|---|---|---|---|
| sắc / huyền / hỏi / ngã / nặng | s f r x j | 1 2 3 4 5 | ' ` ? ~ . |
| â ê ô | aa ee oo | a6 e6 o6 | a^ e^ o^ |
| ă | aw | a8 | a( |
| ơ ư | ow uw, `w` đứng riêng → ư; mở rộng: `[` `]` | o7 u7 | o+ u+ |
| đ | dd | d9 | dd |
| xoá dấu | z | 0 | - |

Gõ lặp để huỷ: `aa`→`â`, `aaa`→`aa`; `ss` → bỏ sắc, giữ `s`.

### 4.3 Quy tắc đặt dấu thanh

1. `qu`, `gi` đứng trước nguyên âm khác → `u`/`i` thuộc phụ âm đầu (quà, giữa).
2. Có nguyên âm biến đổi (â ê ô ơ ư ă) → đặt lên nó; `ươ` → lên `ơ` (người, được).
3. Một nguyên âm → đặt lên nó.
4. Ba nguyên âm → nguyên âm giữa (khoái, ngoẹo); `uyê` → `ê`.
5. Hai nguyên âm:
   - Có phụ âm cuối → nguyên âm thứ hai (toán, hoàng).
   - Không có phụ âm cuối:
     - `oa`, `oe`, `uy`: kiểu **mới** → thứ hai (hoà, thuỷ); kiểu **cũ** → thứ nhất (hòa, thủy). Người dùng chọn.
     - Còn lại (ai, ao, au, ay, eo, ia, iu, oi, ua, ui, ưa, ưu, ...) → thứ nhất.

### 4.4 Kiểm tra chính tả

- Phụ âm đầu ∈ {b c ch d đ g gh gi h k kh l m n ng ngh nh p ph qu r s t th tr v x}
- Vần ∈ bảng vần tiếng Việt
- `c / ch / p / t` cuối chỉ đi với sắc hoặc nặng
- `k / gh / ngh` chỉ đứng trước `i / e / ê`
- Từ không hợp lệ → hiển thị lại phím gốc (Telex: `text` không thành `tẽt`)

### 4.5 Hiệu năng

- Kiểu giá trị, không trạng thái toàn cục
- Mảng `Unicode.Scalar` nhỏ, bảng tra `static let`, không Regex, không `Dictionary<String>` trên đường nóng
- `OutputDiff.deleteCount` tính theo **UTF-16 units** (vì `NSRange` của client dùng UTF-16)
- Mục tiêu < 1ms mỗi phím, có `PerformanceTests`

---

## 5. Lớp Input Method (IMK)

### Info.plist

```
InputMethodConnectionName            = vietKey_Connection
InputMethodServerControllerClass     = vietKey.VKInputController
tsInputMethodCharacterRepertoireKey  = [Latn]
tsInputMethodIconFileKey             = vi.tiff
LSUIElement                          = YES
ComponentInputModeDict
  tsInputModeListKey
    com.<you>.vietKey.vi   → icon vi.tiff, tsInputModePrimaryInScriptKey = YES
    com.<you>.vietKey.en   → icon en.tiff
  tsVisibleInputModeOrderedArrayKey  = [vi, en]
```

### VKInputController

- `recognizedEvents()` → `keyDown` + `flagsChanged`
- `handle(_:client:)` → `KeyEventMapper` → `engine.process` → `OutputStrategy.apply`
- `setValue(_:forTag:client:)` → nhận input mode hiện tại (vi / en)
- `commitComposition`, `deactivateServer` → commit + reset
- Phím tắt V/E → `client.selectMode(_:)` để hệ thống đổi icon
- Nhớ V/E theo app: dựa trên `client.bundleIdentifier()` + mode

### Menu trên menu bar (qua `menu()`)

```
┌────────────────────────────┐
│ ✓ Tiếng Việt (vietKey)     │  hệ thống
│   English (vietKey)        │
│   ABC                      │
├────────────────────────────┤
│ Kiểu gõ          ▸ Telex   │  của mình
│                    VNI     │
│                    VIQR    │
│ Chuyển mã clipboard…       │
│ Cài đặt…                   │
├────────────────────────────┤
│ Show Emoji & Symbols       │  hệ thống
│ Open Keyboard Settings…    │
└────────────────────────────┘
```

Icon chỉ hiện khi vietKey đang là input source được chọn (hành vi chuẩn macOS).

### Xuất chữ

| Chiến lược | Cách làm | Khi nào |
|---|---|---|
| `MarkedTextStrategy` | `setMarkedText` khi đang gõ, `insertText` khi kết thúc từ | Mặc định |
| `DirectReplaceStrategy` | `insertText(_:replacementRange:)` dựa trên `selectedRange()` | Tuỳ chọn, không gạch chân; tự fallback về marked text với app không hỗ trợ (Terminal, Electron, JetBrains, ...) |

Reset buffer khi: click chuột, phím mũi tên, đổi app, con trỏ đổi vị trí.

---

## 6. Settings (SwiftUI, trong cùng process)

| Tab | Nội dung |
|---|---|
| Chung | Phím tắt V/E (HotkeyRecorder), khởi động, ngôn ngữ UI |
| Kiểu gõ | Telex / VNI / VIQR, biến thể Telex, đặt dấu cũ / mới, gõ dấu tự do, kiểm tra chính tả, khôi phục từ sai, bảng mã Unicode NFC / NFD |
| Gõ tắt | Bảng macro, nhập / xuất file định dạng UniKey/OpenKey |
| Theo ứng dụng | Nhớ V/E theo app, danh sách app loại trừ, chiến lược xuất chữ theo app |
| Chuyển mã | Chuyển clipboard giữa Unicode ↔ TCVN3 ↔ VNI-Windows ↔ VIQR, bỏ dấu |

`AppSettings` là `@Observable`, lưu `UserDefaults.standard`, mọi controller đọc chung một instance → thay đổi có hiệu lực ngay.

---

## 7. Quy trình dev

Input Method **không chạy bằng nút Run**. Hệ thống tự spawn process và cache bundle cũ.

1. `Scripts/install-dev.sh`: build → copy vào `~/Library/Input Methods/vietKey.app` → `pkill vietKey` → `TISRegisterInputSource`. Gắn vào Scheme → Build → Post-action.
2. Lần đầu: System Settings → Keyboard → Input Sources → thêm "Tiếng Việt (vietKey)".
3. Debug: Xcode → Debug → Attach to Process by Name → `vietKey`. Log qua `os.Logger` + Console.app.
4. **Code signing phải nhất quán**: ký bằng cert khác lần trước → macOS từ chối load IM mà không báo lỗi. Dùng Development cert cố định.
5. Luồng cài cho người dùng cuối: mở app từ Downloads → app phát hiện chưa nằm trong Input Methods → `InputSourceInstaller` copy + đăng ký + mở System Settings.

---

## 8. Kiểm thử

- **Swift Testing** cho package, test tham số:
  ```swift
  @Test(arguments: [("vieejt","việt"), ("nguwowif","người"), ("hoaf","hoà"), ("text","text"), ("ddaay","đây")])
  func telex(input: String, expected: String) { #expect(VietEngine.type(input, .telex) == expected) }
  ```
- `DictionaryRoundTripTests`: sinh toàn bộ âm tiết từ Initials × Rhymes × Tones (~7.000), lọc theo luật, gõ bằng 3 kiểu, so khớp. Không cần từ điển ngoài.
- Thử thủ công: TextEdit, Safari (thanh địa chỉ), Chrome, VS Code, Terminal, Messages, Word, Excel.

---

## 9. Lộ trình

| Giai đoạn | Nội dung | Kết quả |
|---|---|---|
| 1 | Tạo `Packages/VietKeyCore`, `Scripts/install-dev.sh`, chuyển target `vietKey` thành IM (Info.plist, `main.swift`, controller rỗng). Engine: Model → Telex → SyllableBuilder → TonePlacer → Renderer, kèm test | Khung chạy được, engine Telex đúng qua test |
| 2 | `VKInputController` + `MarkedTextStrategy` + `KeyEventMapper` | Gõ được tiếng Việt trong TextEdit / Safari |
| 3 | 2 input mode vi/en, `IMMenu`, phím tắt V/E, `AppSettings`, cửa sổ Settings cơ bản, `InputSourceInstaller` | Dùng được hằng ngày |
| 4 | VNI, VIQR, Telex mở rộng, đặt dấu cũ / mới, `SpellChecker`, khôi phục từ sai, Macro + nhập file, nhớ V/E theo app | Ngang tính năng UniKey |
| 5 | `DirectReplaceStrategy` + `StrategyResolver`, `VietCharset` + tab Chuyển mã, `Localizable.xcstrings`, notarize + DMG | Phát hành |

---

## 10. Ngoài phạm vi ban đầu (cố ý để sau)

- Tự cập nhật (Sparkle) → sau khi phát hành
- Backend CGEventTap → chỉ làm nếu IMK không đáp ứng một số app cụ thể
- Gõ trực tiếp ra TCVN3 / VNI-Windows → chỉ có trong công cụ chuyển mã
- `NSStatusItem` riêng luôn hiện kiểu UniKey Windows → tuỳ chọn tắt mặc định, nếu có nhu cầu
- Bàn phím iOS → tái dùng `VietEngine`, dự án riêng

---

## 11. Rủi ro chỉ lộ ra khi chạy thật

- App nào xử lý marked text kém (gạch chân lạ, mất chữ khi commit)
- `selectedRange()` có đúng trong Chrome / Electron không (ảnh hưởng `DirectReplaceStrategy`)
- Hệ thống cache bundle IM thế nào khi cập nhật phiên bản
- Hành vi `flagsChanged` khi phím tắt V/E trùng với phím tắt hệ thống

Không rà plan thêm được nữa; giải quyết khi đến giai đoạn tương ứng.
