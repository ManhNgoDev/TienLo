# TienLo Monorepo (`tienlo-be-fe`)

Monorepo chứa toàn bộ mã nguồn của dự án **TienLo**, bao gồm Backend xây dựng trên **NestJS** và Frontend phát triển bằng **Flutter**.

---

## 📁 Cấu trúc thư mục (Project Structure)

```text
tienlo-be-fe/
├── apps/
│   ├── backend/             # NestJS API Backend (Node.js + TypeScript)
│   │   ├── src/
│   │   │   ├── app.controller.ts
│   │   │   ├── app.module.ts
│   │   │   ├── app.service.ts
│   │   │   └── main.ts
│   │   ├── test/
│   │   ├── package.json
│   │   └── tsconfig.json
│   │
│   └── frontend/            # Flutter Frontend (Dart - Cross-Platform)
│       ├── lib/
│       │   └── main.dart    # Giao diện chính & kết nối API Backend
│       ├── test/
│       │   └── widget_test.dart
│       ├── pubspec.yaml
│       └── ...
│
├── package.json             # Root package script điều phối dự án
├── .gitignore               # Bộ lọc Git chuẩn cho cả NestJS và Flutter
└── README.md                # Tài liệu hướng dẫn sử dụng
```

---

## 🛠️ Yêu cầu môi trường (Prerequisites)

- **Node.js**: Phiên bản 18+ (khuyên dùng Node 20 hoặc 24 LTS)
- **NPM**: Phiên bản 9+
- **Flutter SDK**: Phiên bản 3.x+ (kênh stable)
- Trình duyệt Chrome hoặc thiết bị Android/iOS giả lập / Windows desktop runner.

---

## 🚀 Hướng dẫn khởi chạy nhanh (Quick Start)

Bạn có thể chạy các lệnh điều phối trực tiếp từ thư mục gốc của monorepo:

### 1. Khởi chạy Backend (NestJS)

```bash
# Chế độ phát triển (watch mode - tự động reload khi sửa code)
npm run dev:be

# Hoặc di chuyển vào thư mục backend
cd apps/backend
npm run start:dev
```
- Máy chủ backend sẽ lắng nghe tại: `http://localhost:3000/api`
- Kiểm tra trạng thái máy chủ (Health Check): `http://localhost:3000/api/health`

### 2. Khởi chạy Frontend (Flutter)

```bash
# Chạy trên trình duyệt Chrome (Web)
npm run dev:fe:chrome

# Hoặc chạy trên Windows Desktop
npm run dev:fe:windows

# Hoặc tự chọn thiết bị khả dụng
npm run dev:fe
```

---

## 📋 Danh sách lệnh hữu ích (Available Scripts)

| Lệnh | Ý nghĩa |
| :--- | :--- |
| `npm run dev:be` | Chạy NestJS backend ở chế độ watch mode |
| `npm run build:be` | Biên dịch backend NestJS sang thư mục `dist/` |
| `npm run test:be` | Chạy unit tests cho backend với Vitest |
| `npm run lint:be` | Kiểm tra cú pháp và code quality backend |
| `npm run dev:fe` | Chạy ứng dụng Flutter |
| `npm run dev:fe:chrome` | Chạy Flutter trên Google Chrome |
| `npm run dev:fe:windows`| Chạy Flutter dưới dạng ứng dụng Windows native |
| `npm run analyze:fe` | Kiểm tra phân tích tĩnh (static analysis) Flutter |
| `npm run test:fe` | Chạy unit tests cho Flutter |
| `npm run build:fe:web` | Build ứng dụng Flutter cho Web |
| `npm run build:fe:apk` | Build file cài đặt Android APK |

---

## 🔌 Tích hợp API giữa Backend & Frontend

- Backend NestJS đã được cấu hình sẵn **CORS** và đặt tiền tố toàn cục là `/api`.
- Endpoint kiểm tra:
  - `GET /api` - Thông điệp chào mừng
  - `GET /api/health` - Trả về trạng thái hoạt động JSON của hệ thống:
    ```json
    {
      "status": "ok",
      "message": "TienLo NestJS Backend is up and running!",
      "service": "tienlo-backend",
      "timestamp": "2026-10-24T..."
    }
    ```
- Frontend Flutter đã tích hợp sẵn thư viện `http` và giao diện trực quan cho phép kiểm tra gửi Ping trực tiếp đến Backend.
