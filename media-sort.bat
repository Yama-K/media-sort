@echo off
REM ============================================================
REM  media-sort.bat  —  Sort (or copy) files into type folders
REM ------------------------------------------------------------
REM  USAGE:
REM     media-sort.bat [options] [targetPath]
REM
REM  OPTIONS (case‑insensitive)
REM     -c  --copy       Copy files instead of moving them
REM     -d  --date       Also sort by file date (YYYY-MM sub‑folder)
REM     -r  --rename     Rename file to YYYYMMDD_HHMMSS_original.ext
REM
REM  NOTES:
REM  • If targetPath is omitted, the current directory (where the
REM    terminal is open) is used.
REM  • Existing destination folders are re‑used; new ones are made
REM    only as needed.
REM  • Works fine to re‑run repeatedly—only new files are processed.
REM ============================================================

setlocal EnableDelayedExpansion

:: ---------- defaults ----------
set "MODE=move"           & rem (copy|move)
set "DATEFOLDERS=0"       & rem 0 = off, 1 = on   (-d)
set "RENAME=0"            & rem 0 = off, 1 = on   (-r)
set "TARGETPATH="          & rem where to work

:: ---------- parse args ----------
:parseArgs
if "%~1"=="" goto endParse
if /I "%~1"=="-c"        ( set "MODE=copy"    & shift & goto parseArgs )
if /I "%~1"=="--copy"    ( set "MODE=copy"    & shift & goto parseArgs )
if /I "%~1"=="-d"        ( set "DATEFOLDERS=1"& shift & goto parseArgs )
if /I "%~1"=="--date"    ( set "DATEFOLDERS=1"& shift & goto parseArgs )
if /I "%~1"=="-r"        ( set "RENAME=1"     & shift & goto parseArgs )
if /I "%~1"=="--rename"  ( set "RENAME=1"     & shift & goto parseArgs )
if not defined TARGETPATH set "TARGETPATH=%~1"  & shift & goto parseArgs
shift
goto parseArgs

:endParse
if not defined TARGETPATH set "TARGETPATH=%cd%"

pushd "%TARGETPATH%" 2>nul || ( echo(  Cannot access "%TARGETPATH%" & goto :eof )
echo(
echo  === Sorting in "%TARGETPATH%"  ===
echo(

:: ---------- main loop ----------
for %%F in (*.*) do (
    if not "%%~aF"=="d" (
        rem  ext without dot; if empty = unknown
        set "EXT=%%~xF"
        set "EXT=!EXT:~1!"
        if "!EXT!"=="" set "EXT=unknown"

        rem  base destination folder = extension
        set "DESTFOLDER=!EXT!"

        rem  optional date sub‑folder YYYY-MM (file mod date)
        if "!DATEFOLDERS!"=="1" (
            for %%t in ("%%~tF") do set "FILEDATE=%%~tF"
            rem tokenise FILEDATE respecting locale (dd/mm/yyyy hh:mm)
            for /f "tokens=1-3 delims=/-. " %%a in ("!FILEDATE!") do (
                set "MM=%%a"
                set "DD=%%b"
                set "YY=%%c"
            )
            if "!YY!"=="" set "YY=!FILEDATE:~-4!"
            if "!MM!"=="" set "MM=!FILEDATE:~0,2!"
            set "DESTFOLDER=!DESTFOLDER!\!YY!-!MM!"
        )

        if not exist "!DESTFOLDER!" md "!DESTFOLDER!" >nul 2>&1

        rem  final file name
        set "DESTNAME=%%~nxF"
        if "!RENAME!"=="1" (
            for /f "tokens=1-5 delims=/-. :" %%a in ("%%~tF") do (
                set "NMM=%%a" & set "NDD=%%b" & set "NYY=%%c" & set "NHH=%%d" & set "NNN=%%e"
            )
            if "!NYY!"=="" set "NYY=!FILEDATE:~-4!"
            if "!NMM!"=="" set "NMM=!FILEDATE:~0,2!"
            set "DESTNAME=!NYY!!NMM!!NDD!_!NHH!!NNN!_%%~nF%%~xF"
        )

        if /I "!MODE!"=="copy" (
            echo  Copying "%%~nxF"  →  "!DESTFOLDER!\!DESTNAME!"
            copy "%%F" "!DESTFOLDER!\!DESTNAME!" >nul
        ) else (
            echo  Moving  "%%~nxF"  →  "!DESTFOLDER!\!DESTNAME!"
            move "%%F" "!DESTFOLDER!\!DESTNAME!" >nul
        )
    )
)

echo(
echo  === Done ===
popd
endlocal
