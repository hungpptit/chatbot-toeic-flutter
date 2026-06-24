#!/bin/bash
# Wait for SQL Server to start
echo "Waiting for SQL Server to start..."
for i in {1..50}; do
    /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -Q "SELECT 1" &>/dev/null
    if [ $? -eq 0 ]; then
        echo "SQL Server is ready! Checking if init.sql exists..."
        if [ -f /usr/src/app/init.sql ]; then
            echo "Creating database ChatbotToeic..."
            /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -Q "CREATE DATABASE ChatbotToeic;"
            echo "Running init.sql..."
            /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -i /usr/src/app/init.sql
            echo "Database initialized successfully."
            
            if [ -f /usr/src/app/migrate-to-microservices.sql ]; then
                echo "Running migrate-to-microservices.sql to split database and copy data..."
                /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -i /usr/src/app/migrate-to-microservices.sql
                echo "Database migration completed."
            fi
        else
            echo "Warning: init.sql not found at /usr/src/app/init.sql. Skipping initialization."
        fi
        break
    else
        echo "SQL Server not ready yet. Waiting 2 seconds..."
        sleep 2
    fi
done
