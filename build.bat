@echo off
rem dist\phevy_dpi.exe                  : konsol surumu (tek dosya, tek basina kullanim)
rem dist\phevy_engine\phevy_engine.exe  : penceresiz motor klasoru (uygulama --ipc ile baslatir)
cd /d "%~dp0"
if not exist third_party\WinDivert.dll (
    echo third_party\WinDivert.dll yok. README'deki adimlari izleyin.
    exit /b 1
)
set BINS=--add-binary "third_party\WinDivert.dll;." --add-binary "third_party\WinDivert64.sys;."
python -m PyInstaller --noconfirm --onefile %BINS% --uac-admin --name phevy_dpi phevy_dpi.py || exit /b 1
rem Motor klasor (onedir) olarak derlenir: her acilista gecici klasore acilmaz, daha hizli baslar
rem ve antivirusler tek dosya paketlerden daha az suphelenir.
python -m PyInstaller --noconfirm --onedir %BINS% --noconsole --name phevy_engine phevy_dpi.py || exit /b 1
