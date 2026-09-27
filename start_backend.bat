@echo off
echo Starting XAMPP Apache and MySQL...
start "XAMPP Apache" "D:\xampp\apache\bin\httpd.exe"
start "XAMPP MySQL" "D:\xampp\mysql\bin\mysqld.exe"

echo Starting SportX API Server and ngrok tunnel...

cd /d "d:\SportX Project\sportx-api"

:: Start the Laravel backend server in a new window
start "SportX Backend Server" cmd /k "D:\php84\php.exe artisan serve"

:: Start ngrok on port 8000 in another new window
start "ngrok Tunnel" cmd /k "ngrok http 8000"

echo Both services have been started in new windows.
