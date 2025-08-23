@echo off
rem Log off all users with disconnected sessions
powershell.exe -ExecutionPolicy Bypass -Command "&{quser | Select-String "Disc" | ForEach{logoff ($_.tostring() -split ' +')[2]}}"