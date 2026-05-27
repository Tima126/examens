@echo off
chcp 65001 > nul
echo.
echo ============================================
echo  Запуск PostgreSQL в Docker (Server_05)
echo ============================================

:: ШАГ 1. Запускаем контейнер
echo.
echo [1/3] Запуск контейнера...
docker compose up -d

:: ШАГ 2. Ждём пока PostgreSQL полностью стартует
echo.
echo [2/3] Ожидание готовности PostgreSQL...
:WAIT
docker exec Server_05 pg_isready -U postgres > nul 2>&1
if errorlevel 1 (
    timeout /t 2 /nobreak > nul
    goto WAIT
)
echo  PostgreSQL готов!

:: ШАГ 3. Запускаем скрипт настройки баз данных
echo.
echo [3/3] Настройка баз данных, пользователей и прав...
docker exec -i Server_05 bash < setup_databases.sh

echo.
echo ============================================
echo  Всё готово! Открывайте pgAdmin и подключайтесь:
echo  Host     : localhost
echo  Port     : 5432
echo  Username : sa
echo  Password : De_05
echo ============================================
pause
