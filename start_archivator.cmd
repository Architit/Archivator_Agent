@echo off
setlocal

REM === НАСТРОЙКА ПУТЕЙ (ПРОВЕРЬ И ПРИ НУЖДЕ ИЗМЕНИ) ===
set "SRC=C:\Users\lkise\OneDrive\LAM\SRC.CHAT.Δ.01\Chat-GPT_archive\Chats"
set "REPO=C:\Users\lkise\OneDrive\LAM\Trianiuma.DataBase"
set "LABEL=EmergencyRestore"

REM === ЗАПУСК POWERSHELL С ПАРАМЕТРАМИ ===
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Archivator_Agent.ps1" ^
    -Source "%SRC%" ^
    -Repo "%REPO%" ^
    -Label "%LABEL%" ^
    -ComputeHash ^
    -NoGit

endlocal
