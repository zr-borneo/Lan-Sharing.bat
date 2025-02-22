@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
cls
color F0
title Share Manager - LAN Sharing

:: Cek apakah skrip dijalankan sebagai administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Skrip harus dijalankan sebagai Administrator.
    pause
    exit /B 1
)

:: Setup Logging
set "LOG_FILE=%TEMP%\ShareManager.log"
echo [%DATE% %TIME%] Skrip dijalankan. >> "!LOG_FILE!"
echo [%DATE% %TIME%] Script by ZR_Borneo >> "!LOG_FILE!"

:: Splash Screen
:SPLASH
cls
echo.
echo ███████╗██████╗         ██████╗  ██████╗ ██████╗ ███╗   ██╗███████╗ ██████╗ 
echo ╚══███╔╝██╔══██╗        ██╔══██╗██╔═══██╗██╔══██╗████╗  ██║██╔════╝██╔═══██╗
echo   ███╔╝ ██████╔╝        ██████╔╝██║   ██║██████╔╝██╔██╗ ██║█████╗  ██║   ██║
echo  ███╔╝  ██╔══██╗        ██╔══██╗██║   ██║██╔══██╗██║╚██╗██║██╔══╝  ██║   ██║
echo ███████╗██║  ██║███████╗██████╔╝╚██████╔╝██║  ██║██║ ╚████║███████╗╚██████╔╝
echo ╚══════╝╚═╝  ╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝ ╚═════╝                                                                            
echo     -----------------------------------
echo         SHARE MANAGER - LAN SHARING
echo     -----------------------------------
echo.
echo        Script by ZR_Borneo
echo        [ Press any key to continue... ]
pause >nul

:: Ambil path tempat script dijalankan
set "CURRENT_PATH=%CD%"
set "DRIVE_LETTER=%CURRENT_PATH:~0,2%"

:: Cek apakah script dijalankan di root drive atau dalam folder
if "%CURRENT_PATH:~3,1%"=="" (
    set "SHARE_NAME=%COMPUTERNAME%-Share-%DRIVE_LETTER:~0,1%"
) else (
    for %%F in ("%CURRENT_PATH%") do (
        set "FOLDER_NAME=%%~nxF"
    )
    set "SHARE_NAME=%COMPUTERNAME%-Share-!FOLDER_NAME!"
)

:: Menu Utama
:Start
cls
echo.
echo     ====================================
echo         SHARE MANAGER - LAN SHARING    
echo     ====================================

net share | findstr /I /C:"!SHARE_NAME!" >nul
if %errorlevel%==0 (
    echo =====================================
    echo  Folder/Drive sudah dibagikan sebagai "!SHARE_NAME!".
    echo =====================================
    net share "!SHARE_NAME!"
    echo =====================================
    echo  [1] Ubah Izin Sharing
    echo  [2] Ubah Nama Share
    echo  [3] Tampilkan Daftar Share
    echo  [4] Nonaktifkan Sharing
    echo  [0] Kembali
    echo  [X] Keluar
    echo =====================================
    choice /C 12340X /N /M "Pilih opsi (1/2/3/4/0/X): "
    if errorlevel 6 goto Exit
    if errorlevel 5 goto Start
    if errorlevel 4 goto NonaktifkanSharing
    if errorlevel 3 goto TampilkanDaftarShare
    if errorlevel 2 goto UbahNamaShare
    if errorlevel 1 goto UbahIzin
) else (
    echo  Folder/Drive saat ini belum dibagikan.
    echo =====================================
    echo  [1] Tambah Sharing Folder/Drive ini
    echo  [0] Kembali
    echo  [X] Keluar
    echo =====================================
    choice /C 10X /N /M "Pilih opsi (1/0/X): "
    if errorlevel 3 goto Exit
    if errorlevel 2 goto Start
    if errorlevel 1 goto ShareFolder
)

:: Bagikan Folder
:ShareFolder
cls
echo Pilih user yang boleh mengakses:
echo [1] Everyone (Semua orang di jaringan)
echo [2] User tertentu
echo [0] Kembali
echo [X] Keluar
choice /C 120X /N /M "Pilih opsi (1/2/0/X): "
if errorlevel 4 goto Exit
if errorlevel 3 goto Start
if errorlevel 2 set /P "USER=Masukkan nama user: " & goto SelectAccess
set "USER=Everyone"

:SelectAccess
cls
echo Pilih jenis akses sharing:
echo [1] Full Control (Bisa baca/tulis)
echo [2] Read-Only (Hanya bisa membaca)
echo [0] Kembali
echo [X] Keluar
choice /C 120X /N /M "Pilih opsi (1/2/0/X): "
if errorlevel 4 goto Exit
if errorlevel 3 goto ShareFolder
if errorlevel 2 set "ACCESS=READ" & goto ApplySharing
set "ACCESS=FULL"

:ApplySharing
cls
net share "!SHARE_NAME!" /delete >nul 2>&1
if "!ACCESS!"=="READ" (
    echo Membagikan "!CURRENT_PATH!" sebagai "!SHARE_NAME!" dengan akses Read-Only...
    net share "!SHARE_NAME!"="!CURRENT_PATH!" /GRANT:"!USER!",READ
) else (
    echo Membagikan "!CURRENT_PATH!" sebagai "!SHARE_NAME!" dengan akses Full Control...
    net share "!SHARE_NAME!"="!CURRENT_PATH!" /GRANT:"!USER!",FULL
)

echo.
echo =====================================
echo Berhasil membagikan !CURRENT_PATH!
echo Nama Share: !SHARE_NAME!
echo Akses di jaringan: \%COMPUTERNAME%!SHARE_NAME!
echo =====================================
echo [%DATE% %TIME%] Share "!SHARE_NAME!" dibuat. >> "!LOG_FILE!"
pause
goto Start

:: Ubah Izin Sharing
:UbahIzin
cls
echo Pilih jenis akses baru:
echo [1] Full Control (Bisa baca/tulis)
echo [2] Read-Only (Hanya bisa membaca)
echo [0] Kembali
echo [X] Keluar
choice /C 120X /N /M "Pilih opsi (1/2/0/X): "
if errorlevel 4 goto Exit
if errorlevel 3 goto Start
if errorlevel 2 set "NEW_ACCESS=READ" & goto ApplyNewAccess
set "NEW_ACCESS=FULL"

:ApplyNewAccess
cls
echo Mengubah izin akses untuk "!SHARE_NAME!"...

:: Hapus share yang ada
net share "!SHARE_NAME!" /delete >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Gagal menghapus share "!SHARE_NAME!".
    pause
    goto Start
)

:: Buat ulang share dengan izin baru
if "!NEW_ACCESS!"=="READ" (
    echo Membagikan ulang "!CURRENT_PATH!" sebagai "!SHARE_NAME!" dengan akses Read-Only...
    net share "!SHARE_NAME!"="!CURRENT_PATH!" /GRANT:"Everyone",READ
) else (
    echo Membagikan ulang "!CURRENT_PATH!" sebagai "!SHARE_NAME!" dengan akses Full Control...
    net share "!SHARE_NAME!"="!CURRENT_PATH!" /GRANT:"Everyone",FULL
)

:: Cek apakah perintah berhasil
if %errorlevel%==0 (
    echo Izin telah diperbarui.
    echo [%DATE% %TIME%] Izin share "!SHARE_NAME!" diubah menjadi !NEW_ACCESS!. >> "!LOG_FILE!"
) else (
    echo Gagal mengubah izin. Kode error: %errorlevel%
    echo Jalankan "NET HELPMSG %errorlevel%" untuk informasi lebih lanjut.
)

pause
goto Start

:: Ubah Nama Share
:UbahNamaShare
cls
set /P "NEW_SHARE_NAME=Masukkan nama share baru: "
net share "!SHARE_NAME!" /delete >nul 2>&1
net share "!NEW_SHARE_NAME!"="!CURRENT_PATH!" /GRANT:"Everyone",!NEW_ACCESS!
set "SHARE_NAME=!NEW_SHARE_NAME!"
echo Nama share telah diubah menjadi "!SHARE_NAME!".
echo [%DATE% %TIME%] Nama share diubah menjadi "!SHARE_NAME!". >> "!LOG_FILE!"
pause
goto Start

:: Tampilkan Daftar Share
:TampilkanDaftarShare
cls
echo Daftar Share yang Aktif:
net share
echo [%DATE% %TIME%] Daftar share ditampilkan. >> "!LOG_FILE!"
pause
goto Start

:: Nonaktifkan Sharing
:NonaktifkanSharing
cls
echo Apakah Anda yakin ingin menonaktifkan sharing "!SHARE_NAME!"?
choice /C YN /N /M "Pilih (Y/N): "
if errorlevel 2 goto Start
net share "!SHARE_NAME!" /delete >nul 2>&1
if %errorlevel%==0 (
    echo Sharing "!SHARE_NAME!" telah dinonaktifkan.
    echo [%DATE% %TIME%] Sharing "!SHARE_NAME!" dinonaktifkan. >> "!LOG_FILE!"
) else (
    echo Gagal menonaktifkan sharing. Mungkin tidak ditemukan.
)
pause
goto Start

:: Exit Program
:Exit
cls
echo Terima kasih telah menggunakan Share Manager.
echo Script by ZR_Borneo
echo [%DATE% %TIME%] Skrip dihentikan. >> "!LOG_FILE!"
pause
exit /B 0