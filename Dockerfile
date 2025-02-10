# Stage 1: Build application using Gradle
FROM eclipse-temurin:21-jdk-alpine AS build

# Set working directory for build
WORKDIR /app

# Copy Gradle wrapper and settings
COPY gradle gradle
COPY gradlew build.gradle settings.gradle gradle.properties ./

# Pre-download dependencies (cache dependencies for faster builds)
RUN ./gradlew dependencies --no-daemon

# Copy source code
COPY src ./src

# Build the application without running tests
RUN ./gradlew build -x test --no-daemon

# Stage 2: Run application with JRE 21
FROM eclipse-temurin:21-jre-alpine

# Set working directory for runtime
WORKDIR /app

# Copy the built JAR from the build stage
COPY --from=build /app/build/libs/*.jar app.jar

# Create a non-root user for better security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Configure JVM options and entry point
ENTRYPOINT ["java", "-jar", \
    "-XX:+UseContainerSupport", \
    "-XX:MaxRAMPercentage=75.0", \
    "-XX:+UseG1GC", \
    "-Djava.security.egd=file:/dev/./urandom", \
    "/app/app.jar"]
