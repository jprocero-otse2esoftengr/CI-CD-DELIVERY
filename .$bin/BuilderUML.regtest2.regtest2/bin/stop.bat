@echo off

setlocal

rem set environment

set BRIDGESERVER_BIN=C:\Program Files\MagicDraw\plugins\ch.e2e.builder.plugin.magicdraw\bin\runtime\win\bin
set INSTANCES_HOME=C:\Users\jproc\Desktop\appendarrayexercise\appendarrayexercise\.$bin
set INSTANCE_HOME=C:\Users\jproc\Desktop\appendarrayexercise\appendarrayexercise\.$bin\BuilderUML.regtest2.regtest2
set CONSOLE_HOME=C:\Program Files\MagicDraw\plugins\ch.e2e.builder.plugin.magicdraw\bin\runtime\win\bin
set PATH=%PATH%;C:\Program Files\MagicDraw\jre\bin;C:\Program Files\MagicDraw\jre\bin\dtplugin;C:\Program Files\MagicDraw\jre\bin\plugin2;C:\Program Files\MagicDraw\jre\bin\server

cd /D "%INSTANCE_HOME%"
rem debug
echo ========================================================================
cd
echo.
echo PATH             = %PATH%
echo.
echo BRIDGESERVER_BIN = %BRIDGESERVER_BIN%
echo INSTANCES_HOME   = %INSTANCES_HOME%
echo INSTANCE_HOME    = %INSTANCE_HOME%
echo ========================================================================

rem stop server
"%BRIDGESERVER_BIN%\bridgeserver.exe" control shutdown repository "%INSTANCE_HOME%\repository\tabfiles"

endlocal
