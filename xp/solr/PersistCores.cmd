@ECHO off
SET HAS_DATA="false"

IF "%1"=="" (
    SET INSTALL_PATH="C:\\clean"
) ELSE (
    SET INSTALL_PATH=%1
)

IF "%2"=="" (
    SET DATA_PATH="C:\\data"
) ELSE (
    SET DATA_PATH=%2
)

ECHO INSTALL_PATH=%INSTALL_PATH%
ECHO DATA_PATH=%DATA_PATH%

IF EXIST "%DATA_PATH%\solr.xml" (
    ECHO "### Existing Sitecore solr cores found in '%DATA_PATH%'..."
    SET HAS_DATA="true"
)

IF %HAS_DATA%=="false" (
    ECHO "### Cannot persist cores. No Sitecore Solr cores found in '%DATA_PATH%'"    
) ELSE (
    ECHO "### Persisting cores from '%DATA_PATH%'" 
    XCOPY %DATA_PATH% %INSTALL_PATH% /E /Y
)

ECHO "### Removing lock files in %INSTALL_PATH%..."

PUSHD %INSTALL_PATH%
DEL /S "write.lock"
POPD
