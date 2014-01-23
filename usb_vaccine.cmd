@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

REM ---------------------------------------------------------------------------
REM Copyright (C) 2013-2014 Kang-Che Sung <explorer09 @ gmail.com>

REM This program is free software; you can redistribute it and/or
REM modify it under the terms of the GNU Lesser General Public
REM License as published by the Free Software Foundation; either
REM version 2.1 of the License, or (at your option) any later version.

REM This program is distributed in the hope that it will be useful,
REM but WITHOUT ANY WARRANTY; without even the implied warranty of
REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
REM Lesser General Public License for more details.

REM You should have received a copy of the GNU Lesser General Public
REM License along with this program. If not, see
REM <http://www.gnu.org/licenses/>.
REM ---------------------------------------------------------------------------

SET AUTORUN_REG_KEY="HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\IniFileMapping\autorun.inf"
SET has_reg_entry=true
reg query %AUTORUN_REG_KEY% /ve 2>nul | find "@SYS:" /I >nul
IF ERRORLEVEL 1 (
    SET has_reg_entry=false
    ECHO.
    ECHO *** DANGER: Your computer is vulnerable to the AutoRun malware! ***
    ECHO.
)
ECHO This program can help you disable AutoRun and clean the autorun.inf file on 
ECHO your disk, but it DOES NOT remove the malware.
ECHO I recommend you to install anti-virus software to protect your computer.
PAUSE
ECHO.
REM Credit to Nick Brown for the solution to disable AutoRun. See also:
REM http://nickbrown-france.blogspot.tw/2007/10/memory-stick-worms.html
REM http://blogs.computerworld.com/the_best_way_to_disable_autorun_to_be_protected_from_infected_usb_flash_drives
REM Works with Windows 7 too, and I believe it's safer to disable ALL AutoRuns
REM in Windows 7, rather than let go some devices.
IF "!has_reg_entry!"=="false" (
    reg add %AUTORUN_REG_KEY% /ve /t REG_SZ /d "@SYS:DoesNotExist" >nul 2>nul
    IF ERRORLEVEL 1 (
        ECHO *** ERROR: Cannot write registry value ^(IniFileMapping\autorun.inf^).
        ECHO ***        You need to run this script with administrator privileges.
        PAUSE
    ) ELSE (
        ECHO AutoRun disabled.
        ECHO.
    )
)
FOR %%d IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO (
    IF EXIST %%d:\ (
        ECHO.
        ECHO Drive %%d:
        %%d:
        CD \
        CALL :unhideAllFiles
        CALL :deleteShortcuts
        FOR %%f IN (autorun.inf) DO (
            ECHO --^> %%f
            CALL :fileToDirectory %%f
        )
    )
)
ECHO.
ECHO All autorun.inf files are removed (when possible).
PAUSE
ENDLOCAL
GOTO :EOF

REM ---------------------------------------------------------------------------

REM /**
REM  * Clear hidden and system attributes of all files in current directory.
REM  * Note that this function will have problems with files with newlines
REM  * ('\n') in its filename.
REM  */
:unhideAllFiles
    REM Files to keep hidden - these are REAL system files and it's best to
    REM keep these untouched.
    SET KEEP_HS_ATTRIB_FILES=
    SET KEEP_H_ATTRIB_FILES=
    SET KEEP_S_ATTRIB_FILES=
    FOR %%i IN (
        "System Volume Information"

        "AUTOEXEC.BAT"
        "CONFIG.SYS"
        "IO.SYS"
        "MSDOS.SYS"

        "BOOT.BAK"
        "boot.ini"
        "bootfont.bin"
        "NTDETECT.COM"
        "ntldr"

        "RECYCLER"
        "$Recycle.Bin"

        "Boot"
        "bootmgr"
        "BOOTSECT.BAK"

        "hiberfil.sys"
        "pagefile.sys"

        "cmdcons"
        "cmldr"

        "Recovery"
    ) DO (
        SET KEEP_HS_ATTRIB_FILES=!KEEP_HS_ATTRIB_FILES! %%i
    )
    FOR %%i IN (
        "ProgramData"
        "MSOCache"
    ) DO (
        SET KEEP_H_ATTRIB_FILES=!KEEP_H_ATTRIB_FILES! %%i
    )
    FOR %%i IN (
    ) DO (
        SET KEEP_S_ATTRIB_FILES=!KEEP_S_ATTRIB_FILES! %%i
    )

    REM -----------------------------------------------------------------------
    REM The "2^>nul" is to suppress the "File not found" output by dir command.

    ECHO --^> Clearing hidden and/or system file attributes...

    FOR /F "usebackq delims=" %%f IN (`DIR /A:HS /B /O:N 2^>nul`) DO (
        SET keep_hidden=false
        FOR %%i IN (%KEEP_HS_ATTRIB_FILES%) DO (
            IF /I X"%%f"==X"%%~i" (
                SET keep_hidden=true
            )
        )
        IF "!keep_hidden!"=="true" (
            ECHO     File "%%f" ^(attribute HS^) skipped for safety.
        ) ELSE (
            ECHO     attrib -H -S "%%f"
            attrib -H -S "%%f"
        )
    )
    FOR /F "usebackq delims=" %%f IN (`DIR /A:H-S /B /O:N 2^>nul`) DO (
        SET keep_hidden=false
        FOR %%i IN (%KEEP_H_ATTRIB_FILES%) DO (
            IF /I X"%%f"==X"%%~i" (
                SET keep_hidden=true
            )
        )
        IF "!keep_hidden!"=="true" (
            ECHO     File "%%f" ^(attribute H^) skipped for safety.
        ) ELSE (
            ECHO     attrib -H "%%f"
            attrib -H "%%f"
        )
    )
    FOR /F "usebackq delims=" %%f IN (`DIR /A:S-H /B /O:N 2^>nul`) DO (
        SET keep_hidden=false
        FOR %%i IN (%KEEP_S_ATTRIB_FILES%) DO (
            IF /I X"%%f"==X"%%~i" (
                SET keep_hidden=true
            )
        )
        IF "!keep_hidden!"=="true" (
            ECHO     File "%%f" ^(attribute S^) skipped for safety.
        ) ELSE (
            ECHO     attrib -S "%%f"
            attrib -S "%%f"
        )
    )
GOTO :EOF

REM /**
REM  * Delete .lnk and .pif shortcut files.
REM  * Note that :unhideAllFiles must be called first before calling this
REM  * function. Otherwise some files won't be deleted due to their file
REM  * attributes.
REM  */
:deleteShortcuts
    REM The .url shortcuts are harmless here. I won't delete them.
    ECHO --^> Deleting .lnk and .pif shortcuts...
    DEL /F *.lnk
    DEL /F *.pif
GOTO :EOF

REM /**
REM  * Force delete the file and create a directory of the same name.
REM  * @param %1 File name to be converted into a directory.
REM  */
:fileToDirectory
    IF EXIST %1 (
        IF EXIST %1\* (
            REM If file exists and is a directory, keep it.
            attrib +R +H +S %1
        ) ELSE (
            REM Else, delete the file and make it into a directory.
            attrib -R -H -S %1
            DEL /F %1
            CALL :makeDirectory %1
        )
    ) ELSE (
        CALL :makeDirectory %1
    )
GOTO :EOF

REM /**
REM  * Creates a directory named %1 and writes a file named DO_NOT_DELETE.txt
REM  * inside it.
REM  * @param %1 Directory name
REM  */
:makeDirectory
    MKDIR %1
    IF ERRORLEVEL 1 (
        ECHO     Error creating directory "%~1".
    ) ELSE (
        (
            ECHO This folder, "%~1", is to protect your disk from injecting a
            ECHO malicious %1 file.
            ECHO Your disk may still carry the autorun malware, but it will NOT be executed
            ECHO anymore.
            ECHO Please do not delete this folder. If you do, you'll lose the protection.
        ) >%1\DO_NOT_DELETE.txt
        attrib +R +H +S %1
    )
GOTO :EOF
