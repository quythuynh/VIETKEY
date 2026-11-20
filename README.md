# VIET — Bộ gõ tiếng Việt cho macOS

Bộ gõ tiếng Việt kiểu UniKey, viết bằng Swift trên InputMethodKit. Chạy như một nguồn nhập (Input Source)
chính thức của macOS: không cần quyền Accessibility để gõ, an toàn với ô mật khẩu.

- Yêu cầu: macOS 14 trở lên. Phát triển: Xcode 27, Swift 6.
- Thiết kế: [`Docs/PLAN.md`](Docs/PLAN.md) · Quy tắc đặt dấu: [`Docs/TONE_RULES.md`](Docs/TONE_RULES.md)

## Tính năng

**Gõ**
- Telex, Telex mở rộng (`[` → ơ, `]` → ư), VNI, VIQR
- Đặt dấu kiểu mới (hoà, thuỷ) hoặc kiểu cũ (hòa, thủy); gõ dấu ở đâu trong từ cũng được (`tienef` → tiền, `toio` → tôi)
- Gõ lặp để huỷ dấu (`aaa` → aa, `ss` → s, `ww` → w)
- Kiểm tra chính tả ngay khi gõ: từ không phải tiếng Việt giữ nguyên phím đã gõ (`text`, `internet`, `vietnamese`)
- Gõ tắt, nhập / xuất file định dạng UniKey / OpenKey (`key:value`)

**Ứng dụng**
- Chuyển tiếng Việt / tiếng Anh bằng ⌃⇧ (đổi được), nhãn **V** / **E** trên thanh menu, nhớ theo từng ứng dụng
- Danh sách ứng dụng luôn gõ tiếng Anh
- Hai cách hiển thị: gạch chân khi đang gõ (mặc định) hoặc thay thế trực tiếp, chọn theo từng ứng dụng
- TeamViewer, AnyDesk, Screen Sharing, Parallels…: tự chuyển sang bàn phím ABC khi ứng dụng ở phía trước
- **Gõ nhanh** ⌃⌥V: ô nổi để gõ tiếng Việt, Enter để dán vào ứng dụng phía trước (dùng cho TeamViewer, máy ảo)
- Chuyển mã clipboard: Unicode, Unicode tổ hợp, TCVN3, VNI-Windows, VIQR, bỏ dấu
- Giao diện tiếng Việt / tiếng Anh

## Cài đặt và sử dụng

```sh
git clone https://github.com/quythuynh/VIETKEY.git
```

1. Mở `vietKey.app` (từ DMG hoặc bản build) → bấm **Cài VIET**. App tự chép vào `~/Library/Input Methods` rồi thoát.
2. **System Settings → Keyboard → Input Sources → Edit… → + → Vietnamese → VIET**.
3. Chọn **VIET** trên thanh menu (nhãn **V**) và gõ.

| Thao tác | Cách làm |
|---|---|
| Chuyển Việt / Anh | ⌃⇧ (nhấn rồi thả), hoặc chọn *VIET* / *VIET – Tiếng Anh* trên thanh menu |
| Đổi kiểu gõ, chính tả, gõ tắt | Menu của nhãn **V** trên thanh menu, hoặc **Cài đặt VIET…** |
| Gõ vào TeamViewer / máy ảo | ⌃⌥V → gõ → Enter. Tự dán cần bật VIET trong *Privacy & Security → Accessibility* |
| Máy ở xa là Windows | Bật *Dán bằng ⌃V thay vì ⌘V* trong Cài đặt → Chung |

Nếu thanh menu vẫn hiện tên hoặc icon cũ sau khi cập nhật: xoá rồi thêm lại VIET trong Input Sources.

## Cấu trúc

| Thành phần | Vai trò |
|---|---|
| `Packages/VietKeyCore` → `VietEngine` | Lõi xử lý phím: kiểu gõ, đặt dấu, chính tả, gõ tắt. Chỉ dùng Swift stdlib |
| `Packages/VietKeyCore` → `VietCharset` | Chuyển mã |
| `vietKey/InputMethod` | `VKInputController` (nhận lời gọi IMK) → `InputSession` (logic), ánh xạ phím, phím tắt, cách xuất chữ, menu |
| `vietKey/QuickInput` | Ô gõ nhanh, phím tắt toàn hệ thống, dán |
| `vietKey/Settings` | `AppSettings` và cửa sổ cài đặt SwiftUI |
| `vietKey/Installer` | Tự cài vào `~/Library/Input Methods` |
| `vietKeyTests` | Test cho app với IMK / TIS giả lập |

`VietKeyCore` là Swift package local; app chỉ dùng phần `public` của engine.

## Phát triển

```sh
# Test engine và chuyển mã (45 test, gồm gõ lại hơn 15.000 âm tiết bằng cả 4 kiểu gõ)
cd Packages/VietKeyCore && swift test

# Test app (20 test)
xcodebuild test -project vietKey.xcodeproj -scheme vietKey -destination 'platform=macOS'

# Build Debug, cài vào ~/Library/Input Methods và đăng ký với hệ thống
Scripts/install-dev.sh
```

- **Không thử bộ gõ bằng nút Run của Xcode**: bản chạy từ Xcode trùng bundle ID, chặn bản đã cài và gõ không ra chữ.
  Cài bằng script rồi chuyển nguồn nhập ABC → VIET.
- Bản Debug ghi log từng phím (chỉ để chẩn đoán); dùng hằng ngày nên cài bản Release.
- Log: `log stream --level debug --predicate 'subsystem == "htq.inputmethod.vietKey"'`.
  Debug: **Debug → Attach to Process by Name… → `vietKey`**.
- Ký code bằng cùng một certificate giữa các lần build; đổi certificate có thể khiến macOS từ chối nạp bộ gõ.
- Bundle ID phải chứa `inputmethod` (`htq.inputmethod.vietKey`).

## Phát hành

`Scripts/notarize.sh`: archive Release, ký Developer ID, tạo DMG, notarize và staple
(cần chứng chỉ Developer ID và hồ sơ `notarytool`, xem đầu script).

## Chưa làm

- Tự cập nhật (Sparkle)
- Gõ trực tiếp ra TCVN3 / VNI-Windows (chỉ có trong công cụ chuyển mã)
- Bàn phím iOS
