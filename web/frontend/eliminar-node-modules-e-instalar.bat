@echo off
chcp 65001 >nul
echo ============================================
echo   Eliminar node_modules y reinstalar
echo ============================================
echo.
echo IMPORTANTE: Cierra Cursor/VS Code y PAUSA Dropbox
echo antes de continuar. Luego pulsa una tecla.
pause >nul

echo Cerrando procesos Node...
taskkill /F /IM node.exe 2>nul
timeout /t 2 /nobreak >nul

echo Eliminando node_modules...
rd /s /q node_modules 2>nul
if exist node_modules (
  echo No se pudo borrar node_modules. Prueba:
  echo 1. Cerrar Cursor por completo
  echo 2. Pausar sincronizacion de Dropbox
  echo 3. Ejecutar este .bat de nuevo
  pause
  exit /b 1
)

echo Eliminando .next...
rd /s /q .next 2>nul

echo Eliminando package-lock.json (opcional, para instalacion limpia)...
del /q package-lock.json 2>nul

echo.
echo Instalando dependencias con --legacy-peer-deps...
call npm install --legacy-peer-deps

echo.
echo Listo.
pause
