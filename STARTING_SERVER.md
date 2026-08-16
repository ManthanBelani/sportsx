# How to Start the SportX Backend Server locally

This guide explains how to start the Laravel backend server on your Windows machine using your XAMPP environment and the custom PHP 8.4 setup we configured.

## 1. Start XAMPP MySQL
First, ensure that your database is running.
1. Open the **XAMPP Control Panel**.
2. Click the **Start** button next to the **MySQL** module. (You do not need to start Apache because we use Laravel's built-in server).

## 2. Open a Terminal
Open your preferred terminal:
- You can use the terminal inside VS Code.
- Or, open Command Prompt / PowerShell.

## 3. Navigate to the Project Folder
Make sure your terminal is in the backend directory. If it isn't, run:
```bash
cd "d:\SportX Project\sportx-api"
```

## 4. Run the Server
Since your main XAMPP installation uses an older version of PHP, we downloaded PHP 8.4 directly to `D:\php84`. 

To start the server, you must use this specific PHP executable. Run the following command:
```bash
D:\php84\php.exe artisan serve
```

> **Note**: Do not just run `php artisan serve`, as that will use your system's older PHP version and result in an error.

## 5. Access the API
Once the server starts, it will run continuously in the background. You can access your API locally at:
**http://127.0.0.1:8000**

---

### Troubleshooting
- **Database Connection Error**: If you see a database error, make sure you started **MySQL** in the XAMPP control panel.
- **Port In Use**: If it says port 8000 is already in use, you can run `D:\php84\php.exe artisan serve --port=8001` to use a different port.
