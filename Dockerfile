# syntax=docker/dockerfile:1
# =============================================================================
#  Dockerfile - FILE KHUNG (multi-stage build cho Spring Boot 4 / Java 21 / Gradle)
#  Sinh viên hoàn chỉnh các ô ______ theo yêu cầu Phần 2 của đề thi.
# =============================================================================

# ---------- Stage 1: build - biên dịch & đóng gói bằng Gradle + JDK 21 ----------
# Spring Boot 4 yêu cầu Gradle >= 8.14
FROM gradle:9.0.0-jdk-alpine AS builder
WORKDIR /workspace


COPY build.gradle settings.gradle ./
RUN ./gradlew build -x test || true

# Cho phép chạy lệnh để build file JAR, bỏ qua test (nếu có lỗi test thì vẫn build được) bằng cách chạy lệnh

COPY src ./src
RUN chmod +x ./gradlew && ./gradlew clean bootJar --no-daemon -x test




# ---------- Stage 2: runtime - chỉ chứa JRE 21 + file JAR ----------
FROM eclipse-temurin:21-jre-alpine AS runtime

# Phiên bản ứng dụng truyền vào lúc build (docker compose: build-arg APP_VERSION)
ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION} \
    JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75"

WORKDIR /app

# Chạy ứng dụng bằng user thường, không dùng root
RUN addgroup -S spring && adduser -S spring -G spring
# Chỉ lấy file JAR từ stage build
COPY --from=builder /workspace/build/libs/*.jar /app/app.jar
USER spring:spring

EXPOSE 8087

# ENTRYPOINT dạng exec (mảng JSON)
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
