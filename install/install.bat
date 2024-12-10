@echo off

REM Map drive Z: to \\host.lan\Data
echo Mapping drive Z: to \\host.lan\Data...
net use Z: \\host.lan\Data /persistent:yes

REM Set the execution policy
echo Setting Execution Policy...
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force"

REM Disable Hibernation
echo Disabling Hibernation...
powercfg /hibernate off

REM Configure Registry Settings
echo Configuring Registry Settings...
reg add HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v HideFileExt /t REG_DWORD /d 0 /f
reg add HKCU\Console /v QuickEdit /t REG_DWORD /d 1 /f
reg add HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v Start_ShowRun /t REG_DWORD /d 1 /f
reg add HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v StartMenuAdminTools /t REG_DWORD /d 1 /f
reg add HKLM\SYSTEM\CurrentControlSet\Control\Power /v HibernateFileSizePercent /t REG_DWORD /d 0 /f
reg add HKLM\SYSTEM\CurrentControlSet\Control\Power /v HibernateEnabled /t REG_DWORD /d 0 /f

REM Disable WinRM
echo Disabling WinRM...
powershell -ExecutionPolicy Bypass -Command "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -File Z:\disable-winrm.ps1"

REM Install Chocolatey
echo Installing Chocolatey...
@powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

REM Verify Chocolatey Installation
choco -v
if %errorlevel% neq 0 (
    echo Chocolatey installation failed. Exiting...
    exit /b 1
)

REM Install Python
echo Installing Python...
choco install python -y
if %errorlevel% neq 0 (
    echo Python installation failed. Exiting...
    exit /b 1
)

REM Reload environment variables
echo Reloading environment variables...
powershell -Command "[System.Environment]::SetEnvironmentVariable('Path', $env:Path + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'Machine'), 'Process')"


REM Verify Python Installation
python --version
if %errorlevel% neq 0 (
    echo Python is not installed correctly. Exiting...
    exit /b 1
)

REM Install Windows Updates
echo Installing Windows Updates...
powershell -ExecutionPolicy Bypass -Command "Invoke-Expression -Command 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -File z:\win-updates.ps1'"

@echo off
:: Check if OpenSSH is already installed
powershell -ExecutionPolicy Bypass -Command "Get-WindowsCapability -Online | Where-Object {$_.Name -like '*OpenSSH*' -and $_.State -eq 'Installed'}" >nul 2>&1

:: Install OpenSSH Client
echo Installing OpenSSH Client...
powershell -ExecutionPolicy Bypass -Command "Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0"

:: Install OpenSSH Server (optional, remove if not needed)
echo Installing OpenSSH Server...
powershell -ExecutionPolicy Bypass -Command "Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0"

:: Start and configure the OpenSSH Server service
echo Configuring OpenSSH Server...
powershell -ExecutionPolicy Bypass -Command "Start-Service sshd"
powershell -ExecutionPolicy Bypass -Command "Set-Service -Name sshd -StartupType 'Automatic'"

:: Confirm installation
echo OpenSSH installation completed. Verifying installation...
powershell -ExecutionPolicy Bypass -Command "Get-WindowsCapability -Online | Where-Object {$_.Name -like '*OpenSSH*'}"

set "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

REM Install required packages via Chocolatey
for %%P in (7zip.portable adobereader curl firefox microsoft-office-deployment msys2) do (
    choco install %%P -y
)

choco install googlechrome -y --ignore-checksums


REM Check currently installed Python modules
for /f "tokens=*" %%L in ('c:\Python312\Scripts\pip.exe list --format=freeze') do (
    echo %%L >> current_modules.txt
)

REM Define required Python modules
set reqpythonmods=xonsh glances windows-curses magic-wormhole gdown

REM Install missing Python modules
for %%M in (%reqpythonmods%) do (
    findstr /i "%%M" current_modules.txt >nul || (
        echo Installing %%M
        c:\Python312\python.exe -m pip install %%M
    )
)

REM Clean up temporary file
del current_modules.txt

REM Set environment variables
@powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "[Environment]::SetEnvironmentVariable('PATH', '%PATH%;c:\Python312;c:\Python312\Scripts;c:\tools\msys64\usr\bin', 'Machine');"


REM Download a file using gdown
c:\Python312\Scripts\gdown.exe --id 1NTXgpYtAN6iat597RXBn9R4SoPMaP_6s

REM Download an instruction HTML file
curl https://www.prajwaldesai.com/system-administrator-has-set-policies-to-prevent-installation/ -o system-administrator-has-set-policies-to-prevent-installation.html

REM Install PowerShell module
@powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force"
@powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Install-Module -Name pscx -Force -Scope AllUsers;"

REM Configure SSH service
sc config sshd start= auto
net start sshd

REM Install MSYS2 tools using bash
c:\tools\msys64\usr\bin\bash.exe --login -c "pacman -Sy --noconfirm --needed dos2unix p7zip pv python3-pip unzip"

REM Download Mesa drivers
curl -L -o C:\mesa3d-24.3.0-release-msvc.7z ^
    https://github.com/pal1000/mesa-dist-win/releases/download/24.3.0/mesa3d-24.3.0-release-msvc.7z

REM Unzip Mesa drivers
"C:\ProgramData\chocolatey\bin\7z.exe" x C:\mesa3d-24.3.0-release-msvc.7z -oC:\mesa\ -y

REM Install Mesa drivers
c:\tools\msys64\usr\bin\echo.exe -e -n 19\n | ^
c:\tools\msys64\usr\bin\pv.exe -q -L 1 | ^
c:\tools\msys64\usr\bin\timeout.exe 5s c:\mesa\systemwidedeploy.cmd

@echo off
set "INSTALL_DIR=%USERPROFILE%\bin"
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

powershell -ExecutionPolicy Bypass -Command ^
"$url = 'https://github.com/quackduck/uniclip/releases/download/v2.3.6/uniclip_2.3.6_Windows_x86_64.zip'; ^
$destination = '%INSTALL_DIR%\uniclip.zip'; ^
Invoke-WebRequest -Uri $url -OutFile $destination; ^
Expand-Archive -Path $destination -DestinationPath '%INSTALL_DIR%' -Force; ^
Remove-Item $destination; ^
$path = [Environment]::GetEnvironmentVariable('Path', 'User'); ^
if ($path -notlike '*%INSTALL_DIR%*') { ^
    [Environment]::SetEnvironmentVariable('Path', $path + ';%INSTALL_DIR%', 'User') ^
}"

echo Installation complete. Please restart your terminal to use uniclip from anywhere.
pause

