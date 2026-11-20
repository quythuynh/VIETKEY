# Quy tắc đặt dấu thanh

Cài đặt trong `Packages/VietKeyCore/Sources/VietEngine/Phonology/TonePlacer.swift`,
kiểm thử trong `Tests/VietKeyCoreTests/Engine/TonePlacerTests.swift`.

Dấu thanh lưu ở cấp từ và được đặt lại sau mỗi phím, nên gõ dấu ở đâu cũng được (`gifa` → già).

1. `qu`, `gi` đứng trước nguyên âm khác → `u` / `i` thuộc phụ âm đầu (quà, giữa).
2. Có nguyên âm mang dấu phụ (â ê ô ơ ư ă) → đặt lên nguyên âm mang dấu phụ cuối cùng; `ươ` → `ơ` (người, rượu).
3. Một nguyên âm → đặt lên nó.
4. Ba nguyên âm → nguyên âm giữa (khoái, ngoẹo).
5. Hai nguyên âm:
   - có phụ âm cuối → nguyên âm thứ hai (toán, hoàng);
   - không có phụ âm cuối:
     - `oa`, `oe`, `uy`: kiểu mới → thứ hai (hoà, thuỷ), kiểu cũ → thứ nhất (hòa, thủy);
     - còn lại → thứ nhất (múa, kìa, tái).

## Quy tắc Telex liên quan

- `aa ee oo` chỉ thêm dấu mũ cho **nguyên âm cuối** của cụm (`ngoeo` không thành `ngôe`).
- `w` với `uo`: nếu `uo` đứng cuối từ thì chỉ `o` → `ơ` (thuở, huơ); gõ thêm chữ phía sau thì tự thành `ươ` (thương, rượu).
- `w` với `oa` → `oă` (hoặc); với `ua` → `ưa` (mưa); không có nguyên âm → chèn `ư`.
- Gõ lặp phím để huỷ (`aaa` → aa, `ss` → s, `ww` → w); sau khi huỷ, phần còn lại của từ được gõ nguyên văn.
