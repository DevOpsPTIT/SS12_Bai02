# Bài 2 - Session 12: Auto-Release Docker Image on Git Tag

## Mô tả

Dự án minh họa luồng **CD tự động phát hành Docker Image** lên GitHub Container Registry (GHCR) khi có Git Tag có định dạng `v*.*.*`.

## Cấu trúc thư mục

```
SS12/Bai02/
├── .github/
│   └── workflows/
│       └── release.yml              ← ⭐ Workflow CD chính
├── src/
│   ├── main/java/com/example/releasedockerdemo/
│   │   ├── ReleaseDockerDemoApplication.java
│   │   └── ReleaseInfoController.java
│   ├── main/resources/
│   │   └── application.properties
│   └── test/java/com/example/releasedockerdemo/
│       └── ReleaseDockerDemoApplicationTests.java
├── Dockerfile                        ← Multi-stage build
├── build.gradle
├── settings.gradle
├── .gitignore
└── README.md
```

## Workflow CD - Git Tag Release

**File:** [`.github/workflows/release.yml`](.github/workflows/release.yml)

### Tính năng chính

| Tính năng | Chi tiết |
|-----------|----------|
| **Trigger** | Push Git Tag khớp `v*.*.*` |
| **Registry** | `ghcr.io` (GitHub Container Registry) |
| **Auth** | `GITHUB_TOKEN` tự động (không cần secret thủ công) |
| **Tag tự động** | `v1.0.0`, `v1.0`, `v1`, `latest` (qua `metadata-action`) |
| **Cache** | GitHub Actions Cache (`type=gha`) |
| **Dockerfile** | Multi-stage (builder JDK 21 → runtime JRE alpine) |

### Luồng thực thi

```
git tag v1.0.0 && git push origin v1.0.0
          │
          ▼
  ┌─────────────────────────────────────────────┐
  │        CD - Release Docker Image            │
  │                                             │
  │  1. actions/checkout@v4                     │
  │  2. docker/login-action@v3 → GHCR           │
  │  3. docker/metadata-action@v5               │
  │     └─ tags: v1.0.0 | v1.0 | v1 | latest   │
  │  4. docker/setup-buildx-action@v3           │
  │  5. docker/build-push-action@v5             │
  │     └─ push → ghcr.io/<owner>/<repo>:v1.0.0 │
  └─────────────────────────────────────────────┘
```

### Docker Tags được tạo tự động

Với `git tag v1.0.0`, các tag sau sẽ được push lên GHCR:

| Docker Tag | Ý nghĩa |
|---|---|
| `ghcr.io/<owner>/<repo>:v1.0.0` | Phiên bản chính xác |
| `ghcr.io/<owner>/<repo>:1.0` | Phiên bản minor |
| `ghcr.io/<owner>/<repo>:1` | Phiên bản major |
| `ghcr.io/<owner>/<repo>:latest` | Luôn trỏ đến bản mới nhất |

## Hướng dẫn kiểm tra

```bash
# Tạo tag và push lên GitHub để kích hoạt workflow
git tag v1.0.0
git push origin v1.0.0

# Sau khi workflow hoàn thành, pull image từ GHCR
docker pull ghcr.io/<your-github-username>/<repo-name>:v1.0.0

# Chạy container
docker run -p 8080:8080 ghcr.io/<your-github-username>/<repo-name>:v1.0.0

# Kiểm tra
curl http://localhost:8080/
curl http://localhost:8080/health
```

## Dockerfile - Multi-stage Build

| Stage | Base Image | Mục đích |
|---|---|---|
| `builder` | `eclipse-temurin:21-jdk-alpine` | Compile + đóng gói JAR |
| `runtime` | `eclipse-temurin:21-jre-alpine` | Chạy ứng dụng (image nhỏ gọn) |
