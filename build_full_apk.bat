@echo off
set "JAVA_HOME=C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot"
set "ANDROID_HOME=C:\Users\user\AppData\Local\Android\Sdk"
set "PATH=%JAVA_HOME%\bin;%ANDROID_HOME%\cmdline-tools\latest\bin;%PATH%"

echo ========================================================
echo Step 1: Installing NDK 27.0.12077973 via sdkmanager
echo ========================================================
if exist "%ANDROID_HOME%\ndk\27.0.12077973\build\cmake\android.toolchain.cmake" (
    echo NDK toolchain already installed.
) else (
    echo Removing incomplete NDK directory...
    rmdir /s /q "%ANDROID_HOME%\ndk\27.0.12077973" 2>nul
    echo Downloading and extracting NDK via sdkmanager...
    call "%ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat" "ndk;27.0.12077973"
)

echo.
echo ========================================================
echo Step 2: Compiling Light Gate Church APK
echo ========================================================
call flutter build apk --debug

echo.
echo ========================================================
echo Build Complete!
dir /b "build\app\outputs\flutter-apk\app-debug.apk"
echo ========================================================
