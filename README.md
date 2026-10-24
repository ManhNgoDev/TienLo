# TienLo Monorepo (`tienlo-be-fe`)

Monorepo chứa toàn bộ mã nguồn của dự án **TienLo** - Ứng dụng phát triển bản thân, theo dõi thói quen & nhật ký hằng ngày:
- **Backend**: NestJS (TypeScript, Module Architecture, Firebase Admin Auth Guard, Supabase Service)
- **Frontend**: Flutter (Feature-First Clean Architecture, Google Sign-In, Material 3)

---

## 📁 Cấu trúc thư mục chuẩn (Enterprise Architecture)

```text
tienlo-be-fe/
├── apps/
│   ├── backend/                         # NestJS API Backend (TypeScript)
│   │   ├── src/
│   │   │   ├── common/                  # Dùng chung toàn hệ thống
│   │   │   │   ├── decorators/          # @CurrentUser()
│   │   │   │   ├── guards/              # FirebaseAuthGuard (Bearer token)
│   │   │   │   └── interfaces/          # IAuthUser
│   │   │   ├── config/                  # Quản lý cấu hình
│   │   │   │   └── firebase.config.ts   # Firebase Admin SDK initialization
│   │   │   ├── modules/                 # Các module nghiệp vụ tách biệt
│   │   │   │   ├── auth/                # POST /api/auth/sync, GET /api/auth/me
│   │   │   │   ├── users/               # GET /api/users/profile
│   │   │   │   └── database/            # SupabaseService (PostgreSQL client)
│   │   │   ├── app.module.ts
│   │   │   └── main.ts                  # Prefix /api, CORS, ValidationPipe
│   │   ├── .env.example
│   │   └── package.json
│   │
│   └── frontend/                        # Flutter App (Feature-First Structure)
│       ├── lib/
│       │   ├── core/                    # Core dùng chung
│       │   │   ├── constants/           # ApiConstants
│       │   │   ├── network/             # ApiClient (gắn token tự động)
│       │   │   └── theme/               # AppColors, AppTheme
│       │   ├── features/                # Chia theo tính năng (Feature-driven)
│       │   │   ├── auth/                # Tính năng xác thực
│       │   │   │   ├── data/            # AuthService (Google), AuthRepository
│       │   │   │   ├── domain/          # UserModel
│       │   │   │   └── presentation/    # LoginScreen, GoogleSignInButton
│       │   │   └── dashboard/           # Màn hình chính sau đăng nhập
│       │   │       └── presentation/    # HomeScreen
│       │   └── main.dart                # Điểm khởi chạy & định tuyến Auth
│       ├── test/                        # Unit & Widget tests
│       └── pubspec.yaml
│
├── package.json                         # Root NPM Scripts điều phối
├── .gitignore                           # Đã cấu hình lọc rác Git
└── README.md
```

---

## 🛠️ Luồng Đăng nhập & Xác thực (Auth Flow)

```text
[Flutter Client]
       │  Bấm "Đăng nhập Google"
       ▼
[Google / Firebase Auth]
       │  Trả về ID Token (JWT)
       ▼
[NestJS Backend API] ──(Header: Bearer <ID_Token>)──> [FirebaseAuthGuard]
       │                                                         │ Xác thực hợp lệ
       ▼                                                         ▼
[Supabase Database] <──(Upsert User: firebase_uid, email)───────┘
```

> **Chế độ Dev Demo**: Hệ thống hỗ trợ chế độ "Đăng nhập Thử nghiệm (Dev Demo)" cho phép bạn chạy thử ngay toàn bộ luồng kết nối Flutter → NestJS → Supabase trước khi cần cấu hình Google Cloud OAuth và Firebase Service Account.

---

## 🚀 Hướng dẫn khởi chạy nhanh

### 1. Khởi chạy Backend (NestJS)
```bash
npm run dev:be
```
- Server chạy tại: `http://localhost:3000/api`
- Health check: `http://localhost:3000/api/health`

### 2. Khởi chạy Frontend Mobile (Flutter)
```bash
# Chạy trực tiếp trên thiết bị Android Emulator (Pixel) hoặc điện thoại thật
npm run dev:fe

# Hoặc chỉ định rõ thiết bị
flutter run -d emulator-5554
```


---

## ⚙️ Cấu hình Môi trường (.env) cho Backend

Sao chép file mẫu:
```bash
cp apps/backend/.env.example apps/backend/.env
```
Điền các giá trị:
- `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` (Lấy từ Firebase Console).
- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` (Lấy từ Supabase Dashboard).
