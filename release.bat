@echo off
rem Tam surum: motor -> Flutter uygulamasi -> kurulum dosyasi (dist\installer\phevy_kurulum_X.exe)
cd /d "%~dp0"
call build.bat || exit /b 1
pushd flutter_app
call flutter build windows --release || (popd & exit /b 1)
popd
set ISCC=%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe
if not exist "%ISCC%" set ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe
"%ISCC%" /Q installer\phevy.iss || exit /b 1
echo Kurulum dosyasi: dist\installer
