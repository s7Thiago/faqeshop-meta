#!/bin/bash

echo "Warming up Gradle cache..."

# Se existe um build.gradle, fazer download das dependências
if [ -f "/workspace/build.gradle" ] || [ -f "/workspace/build.gradle.kts" ]; then
    cd /workspace
    
    # Download dependencies sem compilar
    ./gradlew dependencies --refresh-dependencies
    
    # Download sources e javadoc
    ./gradlew downloadSources downloadJavadoc 2>/dev/null || true
    
    # Preparar IDE files
    ./gradlew eclipse 2>/dev/null || true
    
    echo "Gradle cache warmed up!"
else
    echo "No Gradle build file found, skipping cache warm-up"
fi