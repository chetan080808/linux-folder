#!/bin/bash
apt-get update -y
apt-get install python3-pip nginx supervisor mysql-client -y

# Install Flask FOR UBUNTU USER (fixes permission issue)
sudo -u ubuntu pip3 install flask flask-cors pymysql --user --break-system-packages

# CREATE DATABASE + TABLE FIRST (CRITICAL FIX)
mysql -h database-1.c8lia4qks1ei.us-east-1.rds.amazonaws.com -u admin -padmin1234 << 'EOF'
CREATE DATABASE IF NOT EXISTS demo_db;
USE demo_db;
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    number VARCHAR(20) NOT NULL,
    age INT NOT NULL,
    area VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

# Flask app with CORRECT DB NAME
cat > /home/ubuntu/app.py << 'EOF'
from flask import Flask, request, render_template_string
import pymysql
from datetime import datetime

app = Flask(__name__)

DB_CONFIG = {
    'host': 'database-1.c8lia4qks1ei.us-east-1.rds.amazonaws.com',
    'user': 'admin',
    'password': 'admin1234',
    'database': 'demo_db',  # ← FIXED: Real database name
    'port': 3306,
    'charset': 'utf8mb4',
    'autocommit': True
}

HTML_FORM = '''
<!DOCTYPE html>
<html>
<head>
    <title>🐍 Python Flask + RDS Demo</title>
    <style>
        body { font-family: -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto; max-width: 700px; margin: 50px auto; padding: 20px; }
        .container { background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
        h1 { color: #1a73e8; text-align: center; }
        form { background: #f8f9fa; padding: 25px; border-radius: 10px; margin: 20px 0; }
        input[type="text"], input[type="tel"], input[type="number"] { 
            width: 100%; padding: 12px; margin: 12px 0; border: 2px solid #e0e0e0; 
            border-radius: 8px; font-size: 16px; box-sizing: border-box; 
        }
        input[type="submit"] { 
            background: #1a73e8; color: white; padding: 15px 40px; border: none; 
            border-radius: 8px; cursor: pointer; font-size: 16px; font-weight: bold;
            width: 100%; 
        }
        input[type="submit"]:hover { background: #1557b0; }
        .success { background: #d4edda; color: #155724; padding: 15px; border-radius: 8px; border: 1px solid #c3e6cb; margin: 20px 0; }
        .error { background: #f8d7da; color: #721c24; padding: 15px; border-radius: 8px; border: 1px solid #f5c6cb; margin: 20px 0; }
        .records { margin-top: 30px; }
        .record { 
            background: white; padding: 20px; margin: 15px 0; border-radius: 10px; 
            box-shadow: 0 2px 10px rgba(0,0,0,0.08); border-left: 4px solid #1a73e8;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 RDS MySQL Form Demo</h1>
        <div style="text-align:center;padding:10px;background:#e3f2fd;border-radius:6px;">
            Connected to: database-1.c8lia4qks1ei.us-east-1.rds.amazonaws.com
        </div>
        
        <form method="POST">
            <h3>➕ Add New Record</h3>
            <input type="text" name="name" placeholder="Full Name *" required>
            <input type="tel" name="number" placeholder="Phone Number *" required>
            <input type="number" name="age" placeholder="Age *" min="1" max="120" required>
            <input type="text" name="area" placeholder="Area/Locality *" required>
            <input type="submit" value="💾 Save to RDS">
        </form>
        
        {{ message|safe }}
        
        <div class="records">
            <h3>📋 Latest 10 Records from RDS</h3>
            {{ records|safe }}
        </div>
    </div>
</body>
</html>
'''

@app.route('/', methods=['GET', 'POST'])
def home():
    message = ""
    records_html = '<div style="text-align:center;color:#666;padding:40px;">No records yet. Add some using the form!</div>'
    
    try:
        conn = pymysql.connect(**DB_CONFIG)
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        
        if request.method == 'POST':
            name = request.form['name']
            number = request.form['number']
            age = int(request.form['age'])
            area = request.form['area']
            
            cursor.execute("INSERT INTO users (name, number, age, area) VALUES (%s, %s, %s, %s)", 
                          (name, number, age, area))
            message = '<div class="success">✅ Record saved to RDS database!</div>'
        
        cursor.execute("SELECT * FROM users ORDER BY created_at DESC LIMIT 10")
        rows = cursor.fetchall()
        
        if rows:
            records_html = ""
            for row in rows:
                records_html += f'''
                    <div class="record">
                        <strong>{row["name"]}</strong><br>
                        📱 {row["number"]} | 👤 Age: {row["age"]} | 📍 {row["area"]}<br>
                        <small>Added: {row["created_at"]}</small>
                    </div>
                '''
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        message = f'<div class="error">❌ Error: {str(e)}</div>'
    
    return render_template_string(HTML_FORM, message=message, records=records_html)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF

# Fix permissions
chown -R ubuntu:ubuntu /home/ubuntu/

# Nginx config
cat > /etc/nginx/sites-available/flask-app << 'EOF'
server {
    listen 80 default_server;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/flask-app /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

# Supervisor
cat > /etc/supervisor/conf.d/flask-app.conf << 'EOF'
[program:flask-app]
command=/usr/bin/python3 /home/ubuntu/app.py
directory=/home/ubuntu
user=ubuntu
autostart=true
autorestart=true
stdout_logfile=/var/log/flask-app.stdout.log
stderr_logfile=/var/log/flask-app.stderr.log
EOF

supervisorctl reread
supervisorctl update
supervisorctl start flask-app

echo "🚀 READY: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4/)" > /home/ubuntu/READY.txt
EOF
