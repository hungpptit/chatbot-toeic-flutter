FROM node:18-bullseye

# Cài đặt các công cụ hệ thống và Python
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    build-essential \
    python3 \
    python3-pip \
    python3-dev \
    unixodbc-dev \
    && rm -rf /var/lib/apt/lists/*

# Tạo symlink python -> python3 để backend gọi được
RUN ln -sf /usr/bin/python3 /usr/bin/python

# Cài đặt Microsoft ODBC Driver 17 cho SQL Server (Cần thiết cho pyodbc kết nối DB từ Linux)
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql17 mssql-tools \
    && echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc \
    && rm -rf /var/lib/apt/lists/*

# Thiết lập thư mục làm việc
WORKDIR /app

# Sao chép và cài đặt các thư viện Python cho ML
# (Đặt trước Node.js copy để tận dụng Docker cache)
COPY ml/requirements.txt* ./ml/
RUN if [ -f ./ml/requirements.txt ]; then \
        pip3 install --no-cache-dir -r ./ml/requirements.txt; \
    else \
        pip3 install --no-cache-dir scikit-learn pandas pyodbc python-dotenv flask joblib; \
    fi

# Cài đặt các package của Node.js
COPY package*.json ./
RUN npm install

# Sao chép toàn bộ mã nguồn (bao gồm cả thư mục ml/ và mô hình AI đã train)
COPY . .

# Expose ports (Node.js & Python ML service)
EXPOSE 8080
EXPOSE 5000

# Chạy server Node.js
CMD ["npm", "start"]
