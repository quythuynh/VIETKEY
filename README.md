# VIET — Bộ gõ tiếng Việt cho macOS

Bộ gõ tiếng Việt kiểu UniKey, chạy như một nguồn nhập (Input Source) chính thức của macOS:
không cần quyền Accessibility để gõ, an toàn với ô mật khẩu. Yêu cầu macOS 14 trở lên.

## Tính năng

- Telex, Telex mở rộng, VNI, VIQR; đặt dấu kiểu mới (hoà) hoặc cũ (hòa), gõ dấu ở đâu trong từ cũng được
- Kiểm tra chính tả: từ không phải tiếng Việt giữ nguyên (`text`, `internet`)
- Gõ tắt, nhập / xuất file của UniKey / OpenKey
- Chuyển Việt / Anh bằng ⌃⇧, nhớ theo từng ứng dụng; danh sách ứng dụng luôn gõ tiếng Anh
- Không gạch chân khi gõ; terminal tự dùng gạch chân
- TeamViewer, AnyDesk, máy ảo: tự chuyển sang bàn phím ABC; **Gõ nhanh** ⌃⌥V để gõ rồi dán vào
- Chuyển mã clipboard: Unicode, TCVN3, VNI-Windows, VIQR, bỏ dấu

## Cài đặt

1. Mở `vietKey.app` → bấm **Cài VIET**.
2. **System Settings → Keyboard → Input Sources → Edit… → + → Vietnamese → VIET**.
3. Chọn **VIET** trên thanh menu (nhãn **V**) và gõ. Cài đặt nằm trong menu của nhãn này.

## Xử lý sự cố

| Hiện tượng | Cách xử lý |
|---|---|
| Gõ ra chữ thừa, mất dấu trong một ứng dụng | Cài đặt → Ứng dụng → chọn *Gạch chân khi đang gõ* cho ứng dụng đó |
| Gõ không ra chữ | `open -g ~/Library/Input\ Methods/vietKey.app` |
| Thanh menu hiện tên / icon cũ | Xoá rồi thêm lại VIET trong Input Sources |

## Phát triển

```sh
cd Packages/VietKeyCore && swift test                                                    # test engine
xcodebuild test -project vietKey.xcodeproj -scheme vietKey -destination 'platform=macOS' # test app
CONFIGURATION=Release Scripts/install-dev.sh                                              # build và cài
```

Không chạy bộ gõ bằng nút Run của Xcode (trùng bundle ID, gõ không ra chữ): cài bằng script rồi chuyển
nguồn nhập ABC → VIET. Thiết kế: [`Docs/PLAN.md`](Docs/PLAN.md).

## Giấy phép

[MIT](LICENSE-MIT) hoặc [Apache 2.0](LICENSE-APACHE), tuỳ bạn chọn.
