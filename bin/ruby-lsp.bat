@echo off
setlocal
cd /d "%~dp0\.."
call bundle exec ruby-lsp %*