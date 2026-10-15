# ============================================================
# Dockerfile - Multi-stage Build cho Spring Boot Gradle
# ============================================================
# Stage 1: BUILD — Dùng Gradle để biên dịch và đóng gói JAR
# Stage 2: RUNTIME — Chỉ copy JAR vào image JRE nhỏ gọn
# ============================================================

# ---- Stage 1: Builder ----
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /workspace

# Copy Gradle wrapper và file cấu hình trước (tận dụng Docker layer cache)
COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY settings.gradle .

# Cấp quyền thực thi cho Gradle Wrapper
RUN chmod +x gradlew

# Download dependencies trước (cache riêng layer này)
RUN ./gradlew dependencies --no-daemon || true

# Copy toàn bộ source code
COPY src src

# Build JAR (bỏ qua test vì CI đã chạy riêng)
RUN ./gradlew bootJar --no-daemon -x test

# ---- Stage 2: Runtime ----
FROM eclipse-temurin:21-jre-alpine AS runtime

# Metadata labels (sẽ được docker/metadata-action ghi đè tự động)
LABEL org.opencontainers.image.title="CI Matrix Demo App"
LABEL org.opencontainers.image.description="Spring Boot demo app for CI/CD Matrix Strategy"
LABEL org.opencontainers.image.vendor="DevOps Course"

# Tạo user non-root để tăng bảo mật
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy JAR từ stage builder
COPY --from=builder /workspace/build/libs/*.jar app.jar

# Chuyển sang user non-root
USER appuser

EXPOSE 8080

# Chạy ứng dụng với profile production
ENTRYPOINT ["java", "-jar", "app.jar"]
