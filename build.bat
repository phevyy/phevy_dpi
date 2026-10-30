@echo off
rem dist\phevy_dpi.exe    : konsol surumu (tek basina kullanim)
rem dist\phevy_engine.exe : penceresiz motor (uygulama --ipc ile baslatir)
cd /d "%~dp0"
if not exist third_party\WinDivert.dll (
    echo third_party\WinDivert.dll yok. README'deki adimlari izleyin.
    exit /b 1
)
set COMMON=--noconfirm --onefile --add-binary "third_party\WinDivert.dll;." --add-binary "third_party\WinDivert64.sys;."
python -m PyInstaller %COMMON% --uac-admin --name phevy_dpi phevy_dpi.py || exit /b 1
python -m PyInstaller %COMMON% --noconsole --name phevy_engine phevy_dpi.py || exit /b 1
