@echo off
set "JAVA_HOME=C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot"
set "ANDROID_HOME=C:\Users\user\AppData\Local\Android\Sdk"
set "PATH=%JAVA_HOME%\bin;%ANDROID_HOME%\cmdline-tools\latest\bin;%PATH%"

echo ========================================================
echo Compiling Light Gate Church Android APK (Debug Build)
echo ========================================================
echo JAVA_HOME: %JAVA_HOME%
echo ANDROID_HOME: %ANDROID_HOME%
echo.

call flutter build apk --debug

echo.
echo ========================================================
echo Build Finished!
echo APK file is located at:
echo build\app\outputs\flutter-apk\app-debug.apk
echo ========================================================
