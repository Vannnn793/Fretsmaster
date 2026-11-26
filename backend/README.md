# FretMaster REST API Backend (Laravel Framework)

Backend REST API untuk autentikasi dan manajemen pengguna aplikasi mobile **FretMaster (AI Chord Gitar)** menggunakan **Laravel 12** dan **Laravel Sanctum**.

---

## 🚀 Fitur REST API

- **Registrasi Akun Musisi** (`POST /api/register`):
  - Validasi: `name` (required), `email` (unique, email valid), `password` (min 6 karakter, confirmed).
  - Return: data profil pengguna baru & Sanctum Bearer token.
- **Login Akun Musisi** (`POST /api/login`):
  - Validasi kredensial email & password menggunakan `Hash::check`.
  - Return: data profil pengguna & Sanctum Bearer token.
- **Profil Pengguna Aktif** (`GET /api/user`):
  - Terproteksi middleware `auth:sanctum`.
  - Mengembalikan data pengguna terautentikasi berdasarkan Bearer token.
- **Logout / Hapus Sesi** (`POST /api/logout`):
  - Terproteksi middleware `auth:sanctum`.
  - Menghapus personal access token aktif di server.

---

## 🛠️ Persyaratan Sistem

- PHP >= 8.2 (dengan extension `pdo_sqlite` atau `pdo_mysql`, `openssl`, `mbstring`)
- Composer >= 2.0
- SQLite (default) atau MySQL / MariaDB (Laragon/XAMPP)

---

## ⚡ Cara Menjalankan Backend Laravel

### 1. Buka Terminal ke Folder Backend
```bash
cd backend
```

### 2. Jalankan Migrasi Database (Jika belum)
```bash
php artisan migrate
```
*Database SQLite sudah dikonfigurasi otomatis di `database/database.sqlite`.*

### 3. Jalankan Server Development Laravel
```bash
php artisan serve --host=0.0.0.0 --port=8000
```
> **Catatan Host:** Menggunakan `--host=0.0.0.0` memungkinkan server dapat diakses baik oleh:
> - Android Emulator: `http://10.0.2.2:8000/api`
> - Windows Desktop / Web: `http://127.0.0.1:8000/api`
> - HP Fisik Android (Wi-Fi yang sama): `http://<IP_KOMPUTER_ANDA>:8000/api`

---

## 🧪 Menguji REST API

Anda dapat menguji semua endpoint secara otomatis menggunakan script uji:
```bash
php test_api.php
```

Output:
```
=== 1. Test Register === -> Status 201 (Created + Token)
=== 2. Test Login ===    -> Status 200 (Success + Token)
=== 3. Test Invalid ===  -> Status 401 (Unauthorized)
=== 4. Test Profile ===  -> Status 200 (Profile data)
=== 5. Test Logout ===   -> Status 200 (Success)
ALL LARAVEL API TESTS PASSED SUCCESSFULLY!
```

---

## 📋 Contoh Endpoint & Request / Response

### 1. Register Pengguna
**Endpoint:** `POST /api/register`  
**Headers:** `Accept: application/json`, `Content-Type: application/json`

**Request Body:**
```json
{
  "name": "Jimi Hendrix",
  "email": "jimi@fretmaster.com",
  "password": "secretpassword",
  "password_confirmation": "secretpassword"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Registrasi berhasil!",
  "data": {
    "user": {
      "id": 1,
      "name": "Jimi Hendrix",
      "email": "jimi@fretmaster.com",
      "created_at": "2026-11-18T04:36:18.000000Z"
    },
    "token": "1|gxSwGyq8NL2RFeeSA0iNKfH23SE1mhc9wAsfIOU658a7b3af"
  }
}
```

### 2. Login Pengguna
**Endpoint:** `POST /api/login`  
**Request Body:**
```json
{
  "email": "jimi@fretmaster.com",
  "password": "secretpassword"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Login berhasil!",
  "data": {
    "user": {
      "id": 1,
      "name": "Jimi Hendrix",
      "email": "jimi@fretmaster.com",
      "created_at": "2026-11-18T04:36:18.000000Z"
    },
    "token": "2|462EutE37YVaMeEZpB7KgMga4bZ4AhvUQpXp8smH85685c03"
  }
}
```

### 3. Profil Pengguna (Authenticated)
**Endpoint:** `GET /api/user`  
**Headers:** `Authorization: Bearer <TOKEN>`

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Data profil berhasil diambil.",
  "data": {
    "user": {
      "id": 1,
      "name": "Jimi Hendrix",
      "email": "jimi@fretmaster.com"
    }
  }
}
```

### 4. Logout (Authenticated)
**Endpoint:** `POST /api/logout`  
**Headers:** `Authorization: Bearer <TOKEN>`

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Logout berhasil.",
  "data": null
}
```
