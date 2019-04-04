@ECHO OFF
SET SOLR_PATH=%1
SET SOLR_PORT=%2
SET INSTALL_PATH=%3
SET DATA_PATH=%4
SET HAS_DATA="false"

ECHO SOLR_PATH=%SOLR_PATH%
ECHO SOLR_PORT=%SOLR_PORT%
ECHO INSTALL_PATH=%INSTALL_PATH%
ECHO DATA_PATH=%DATA_PATH%

FOR /D %%d IN ("%DATA_PATH%\*") DO (
	IF EXIST "%%d\core.properties" (
		SET HAS_DATA="true"
	)
)

IF %HAS_DATA%=="false" (
    ECHO "### No Sitecore Solr cores found in '%DATA_PATH%', seeding clean cores from '%INSTALL_PATH%'..."
    XCOPY %INSTALL_PATH% %DATA_PATH% /E
) ELSE (
    ECHO "### Existing Sitecore solr cores found in '%DATA_PATH%'..."
)

ECHO "### Preparing Solr cores..."

PUSHD %DATA_PATH%
DEL /S "write.lock"
POPD

ECHO "### Starting Solr..."

%SOLR_PATH%\bin\solr.cmd start -port %SOLR_PORT% -f
