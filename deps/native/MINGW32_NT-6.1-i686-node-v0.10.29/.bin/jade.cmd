@IF EXIST "%~dp0\node.exe" (
  "%~dp0\node.exe"  "%~dp0\..\jade\bin\jade.js" %*
) ELSE (
  node  "%~dp0\..\jade\bin\jade.js" %*
)