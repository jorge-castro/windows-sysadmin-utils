cd /d %~dp0
rem Scan Windows for component store corruption, perform repairs and write logs to logs\
DISM.exe /Online /LogPath:logs\%computername%-dism.log /Cleanup-image /Restorehealth
rem Scan system files and replace those that are corrupt
sfc /scannow
rem Write condensed sfc logs to logs\
findstr /c:"[SR]" %windir%\Logs\CBS\CBS.log > "logs\%computername%-sfcdetails.log"