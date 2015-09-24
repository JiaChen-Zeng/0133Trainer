@echo off

:: 把 src\workers 里的所有 Worker 编译成 debug 版 swf 放到 bin\workers 里

cd /d %~dp0..

for /f %%G in ('dir /b src\workers\*.as') do (
	call amxmlc.bat -compiler.debug -source-path "src" -compiler.incremental -output "bin\workers\%%~nG.swf" "src\workers\%%G"
)