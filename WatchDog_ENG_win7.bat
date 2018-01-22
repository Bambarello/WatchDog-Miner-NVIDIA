@echo off
chcp 1251 >nul

REM ================ Set Timers. Default for startup 35 sec. Detection refresh - 60 sec and Issue resolution waiting - 30 sec. =========
SET StartupTimer=40
SET RefreshTimer=30
REM ================ Nubmer or GPU issues before +1 Rig issue detected - 6 (10 sec detection). Number of Rig issues before reboot - 2. =
SET IssueTimer=10
SET GPUIssueCountMax=5
SET RigIssueCountMax=2
SET RigIssueCount=0
REM ================ Reboot on or off. 0 - working as monitor without reboot. 1 - working with reboot ==================================
SET Reboot_On=1
SET RebootTimer=15
REM ================ Additional issues detection: 0 - off; Value - will reboot if detected (clocks, fan and power - below selection; temperature - above selection)
SET clocks_reboot=0
SET temperature_reboot=0
SET fan_reboot=0
SET power_reboot=0
REM ================ Temperature limit detection: 0 - off; Value - will send message if detected (temperature - above or equal to selected)
SET temperature_inform=85
SET tempIssueCountMax=10
SET tempIssueCount=0
REM ================ Set number of GPUs to monitor: 0 - all GPUs will be monitored; Value - will monitor average for selected # of GPUs
SET NumberGPUsToMonitor=0
REM ====================================================================================================================================
SETLOCAL ENABLEDELAYEDEXPANSION
IF NOT EXIST "Logs" MD Logs && ECHO Folder Logs created.
set log_file=Logs\%date:~6,4%%date:~3,2%%date:~0,2%.WatchDog.log
for /f "tokens=*" %%A in ('type "Config\cfg.ini"') do set %%A
title=WatchDog %computername%
echo Please wait...
timeout 1 > nul
PATH=%PATH%;"%PROGRAMFILES%\NVIDIA Corporation\NVSMI\"
for /f %%a in ('nvidia-smi --query-gpu^=count --format^=csv,noheader') do @set /a mygpu=%%a
for /F %%p in ('nvidia-smi --query-gpu^=driver_version --format^=csv^,noheader^,nounits') do set driver_version=%%p
set /a lines=14+%mygpu%
mode con:cols=41 lines=%lines%
cls
echo Please wait...
SET /a gpu=%NumberGPUsToMonitor%-1
IF %NumberGPUsToMonitor% EQU 0 SET /a gpu=%mygpu%-1
SET /a delta=105*%gpu%/%mygpu%
IF %mygpu% EQU 1 set /a delta=80
SET t0=%date%  %time:~-11,8%
For /F "Tokens=1 Delims=." %%i In ('WMIC OS Get LocalDateTime^|Find "."') Do Set Time=%%i
Set M0=1%Time:~4,2%
Set D0=1%Time:~6,2%
Set H0=1%Time:~8,2%
Set MN=1%Time:~10,2%
Set /a nM0=%M0%-100
Set /a nD0=%D0%-100
Set /a nH0=%H0%-100
Set /a nMN0=%MN%-100

:begin
cls  
echo.
ECHO             Detected %mygpu% GPUs.
echo.
ECHO    Waiting for miner program start...
ECHO.
timeout /t %StartupTimer%

SET text=*%computername%:* Detected *%mygpu% GPUs*. WatchDog started.
powershell.exe -ExecutionPolicy Bypass -File tm.ps1 -Verb RunAs
ECHO [%date%][%time:~-6,2%:%time:~-4,2%:%time:~-2,2%] %text% >> %log_file%

:start
SET GPUIssueCount=0
For /F "Tokens=1 Delims=." %%i In ('WMIC OS Get LocalDateTime^|Find "."') Do Set Time=%%i
Set M1=1%Time:~4,2%
Set D1=1%Time:~6,2%
Set H1=1%Time:~8,2%
Set MN1=1%Time:~10,2%
Set /a nM1=%M1%-100
Set /a nD1=%D1%-100
Set /a nH1=%H1%-100
Set /a nMN1=%MN1%-100
set /a DiffTime=%nMN1%+(%nH1%*60)+(%nD1%*1440)+(%nM1%43200)-(%nM0%43200)-(%nD0%*1440)-(%nH0%*60)-%nMN0%
set /a DiffTimeDay=%DiffTime%/1440
set /a DiffTimeHour=(%DiffTime%-%DiffTimeDay%*1440)/60
set /a DiffTimeMin=%DiffTime%-%DiffTimeHour%*60-%DiffTimeDay%*1440

call :for
set /a power_kpd=%power_total%*108/100+90
set /a power_pay=((%power_kpd%*%pay_day%/24*16)+(%power_kpd%*%pay_night%/24*8))*720/1000000*10

cls
echo.
ECHO    WatchDog Start: %t0%
ECHO.
ECHO             Mining is working
ECHO         %DiffTimeDay% days %DiffTimeHour% hours %DiffTimeMin% minutes
IF %RigIssueCount% EQU 0 (
    ECHO             Rig issues %RigIssueCount% of %RigIssueCountMax%
    ) ELSE (
    ECHO             Rig issues %RigIssueCount% of %RigIssueCountMax%
)
ECHO.
ECHO        Driver: %driver_version%  Limit: %delta%%%
ECHO      Average loading of %mygpu% GPUs: %gpu_average%%%

IF %Reboot_On% EQU 1 (
	IF %gpu_average% LSS %delta% goto :starterror
)

call :rebootcheck

echo.
echo     GPU:   MHz:   Temp   Fan:   Power
FOR /L %%B IN (0,1,%gpu%) DO (
    if !temperature.gpu%%B! LEQ 69 set /a colortemp=92
    if !temperature.gpu%%B! GTR 69 set /a colortemp=93
    if !temperature.gpu%%B! GEQ 75 set /a colortemp=95
	IF !temperature.gpu%%B! GEQ %temperature_inform% (
	    SET /a colortemp=101
	    SET /a tempIssueCount=%tempIssueCount%+1
    	IF %tempIssueCount% GEQ %tempIssueCountMax% (
    		SET text=*%computername%:* *GPU%%B* temperature *!temperature.gpu%%B!* C
	    	powershell.exe -ExecutionPolicy Bypass -File tm.ps1 -Verb RunAs
		    IF %tempIssueCount% GEQ %tempIssueCountMax% set /a tempIssueCount=0
	    )
    )
    echo     GPU%%B   !clocks.gr%%B!   !temperature.gpu%%B! C   !fan.speed%%B! %%   !power_draw%%B! W  
)   
echo.
ECHO       Power consumption GPUs: %power_total% W 
ECHO      Power consumption total: %power_kpd% W 
 
timeout /t %RefreshTimer% >nul
goto :start

:starterror
set ping_time=-1
FOR /F "skip=8 tokens=10" %%G in ('ping -n 3 google.com') DO set ping_time=%%G
if %ping_time% LSS 0 (
    cls
    echo.
    ECHO      Internet is down... Waiting...
    echo.
    ECHO               Ping %ping_time% ms.
    timeout /t 15 >nul
    goto :starterror
)

cls
echo.
echo               Ping %ping_time% ms.
timeout /t 5 >nul 

call :for		
set /a GpuMax=0
FOR /L %%Q IN (0,1,%gpu%) DO if !gpu.usage%%Q! GEQ 75 set /a GpuMax+=1
if %gpu_average% GEQ %delta% (
    if %GpuMax% EQU %mygpu% goto :start)

:recheck
FOR /L %%A IN (%IssueTimer%,-1,0) DO (
    CLS
    ECHO.
    ECHO                 ATTENTION                
    ECHO            Mining program fault          
    ECHO.
    ECHO         Waiting for mining resume
    ECHO               Round %GPUIssueCount% of %GPUIssueCountMax%
    ECHO.          Remaining %%A seconds.   
    timeout /t 1 >nul
)

call :for		
set /a GpuMax=0
FOR /L %%q IN (0,1,%gpu%) DO if !gpu.usage%%q! GEQ 75 set /a GpuMax+=1
if %gpu_average% GEQ %delta% (
    if %GpuMax% EQU %mygpu% goto :start
)
timeout /t 1 >nul 

SET /a GPUIssueCount=%GPUIssueCount%+1
IF %GPUIssueCount% LEQ %GPUIssueCountMax% GOTO :recheck

SET /a RigIssueCount=%RigIssueCount%+1
IF %RigIssueCount% LEQ %RigIssueCountMax% (
    SET text=*%computername%:* Rig issue *%RigIssueCount%/%RigIssueCountMax%*.
    powershell.exe -ExecutionPolicy Bypass -File tm.ps1 -Verb RunAs
	ECHO [%date%][%time:~-6,2%:%time:~-4,2%:%time:~-2,2%] %computername%: Rig issue %RigIssueCount%/%RigIssueCountMax%>> %log_file%
	GOTO :start
	)

call :for
set text=Not working: 
set /a GpuMax=0
FOR /L %%q IN (0,1,%gpu%) DO (
    if !gpu.usage%%q! GEQ 75 set /a GpuMax+=1
    if !gpu.usage%%q! LSS 20 set text=!text!*GPU%%q*, 
)
if %gpu_average% GEQ %delta% (
    if %GpuMax% EQU %mygpu% goto :start
)

set text=%text%Average loading of *%mygpu%* GPUs: *%gpu_average%%%*

:rigerror
echo.
ECHO      Average loading of %mygpu% GPUs: %gpu_average%%%

echo.
ECHO            Our ping %ping_time% ms - OK.
echo      It seems NO Internet problems.
timeout /t 5 >nul

:endif
echo [%date%][%time:~-6,2%:%time:~-4,2%:%time:~-2,2%] %computername%: %text%,  restart activated... >> %log_file%
set text=*%computername%:* %text%, restart activated...
powershell.exe -ExecutionPolicy Bypass -File tm.ps1 -Verb RunAs

:reboot
EndLOCAL
set log_file=Logs\%date:~6,4%%date:~3,2%%date:~0,2%.WatchDog.log
REM echo ------------------------------------------------------------------ >> %log_file%
echo [%date%][%time:~-11,8%] NVIDIA Status: >> %log_file%
"C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi" --query-gpu=index,timestamp,clocks.gr,clocks.mem,memory.used,power.limit,power.draw,temperature.gpu,utilization.gpu --format=csv,noheader>> %log_file%
echo [%date%][%time:~-11,8%] Mining issue. %computername% restarted. >> %log_file%
echo ------------------------------------------------------------------ >> %log_file%

:screenshot
IF NOT EXIST "Screenshots" MD Screenshots && ECHO     Folder Screenshots created.
powershell.exe -command "Add-Type -AssemblyName System.Windows.Forms; Add-type -AssemblyName System.Drawing; $Screen = [System.Windows.Forms.SystemInformation]::VirtualScreen; $bitmap = New-Object System.Drawing.Bitmap $Screen.Width, $Screen.Height; $graphic = [System.Drawing.Graphics]::FromImage($bitmap); $graphic.CopyFromScreen($Screen.Left, $Screen.Top, 0, 0, $bitmap.Size); $bitmap.Save('Screenshots\%date:~6,4%%date:~3,2%%date:~0,2%-%time::=-%.WatchDog.Screenshot.jpg');" 2>NUL 1>&2

FOR /L %%A IN (%RebootTimer%,-1,0) DO (
    cls
    echo.
    ECHO     Unfortunately, miner not working.    
    echo.
    ECHO       System reboot in %%A seconds.
    timeout /t 1 >nul  
)
shutdown.exe /r /t 00

GOTO :end
   
:for
set /a power_total=0
set /a total=0
FOR /L %%B IN (0,1,%gpu%) DO (  
    for /F %%p in ('nvidia-smi --id^=%%B --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu.usage%%B=%%p
    for /F %%p in ('nvidia-smi --id^=%%B --query-gpu^=power.draw --format^=csv^,noheader^,nounits') do set power.draw%%B=%%p
    for /F %%p in ('nvidia-smi --id^=%%B --query-gpu^=temperature.gpu --format^=csv^,noheader^,nounits') do set temperature.gpu%%B=%%p
    for /F %%p in ('nvidia-smi --id^=%%B --query-gpu^=clocks.gr --format^=csv^,noheader^,nounits') do set clocks.gr%%B=%%p
    for /F %%p in ('nvidia-smi --id^=%%B --query-gpu^=fan.speed --format^=csv^,noheader^,nounits') do set fan.speed%%B=%%p
)
FOR /L %%B IN (0,1,%gpu%) DO (
    set /a power_draw%%B=power.draw%%B
    set /a power_total+=power_draw%%B
    set /a total+=gpu.usage%%B
)
set /a gpu_average=%total%/%mygpu%
EXIT /B

:rebootcheck
FOR /L %%B IN (0,1,%gpu%) DO (
    IF %clocks_reboot% GTR 0 ( 
        IF !clocks.gr%%B! LEQ %clocks_reboot% ( 
            set text=Abnormal frequency *GPU%%B*
            goto :endif 
        )
    )	
    IF %temperature_reboot% GTR 0 (
        IF !temperature.gpu%%B! GEQ %temperature_reboot% (
            set text=Abnormal temperature *GPU%%B*
            goto :endif 
        )
    )
	IF %fan_reboot% GTR 0 (
        IF !fan.speed%%B! LEQ %fan_reboot% (
            set text=Abnormal fan speed *GPU%%B*
            goto :endif 
        )
    )	
    IF %power_reboot% GTR 0 (
        IF !power_draw%%B! LEQ %power_reboot% (
            set text=Abnormal power draw *GPU%%B*
            goto :endif
        )
    )	
)	
EXIT /B

:end
