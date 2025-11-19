@echo off
REM FEMSQ Windows Authentication Startup Script
REM This script adds native-libs to PATH for DLL loading

set PATH=%~dp0native-libs;%PATH%
java -jar femsq-web-0.1.0.1-SNAPSHOT.jar
