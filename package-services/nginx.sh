# 1. Update package index and install Nginx
sudo apt update
sudo apt install nginx -y

# 2. Overwrite the default index.html with your message
# On Ubuntu, the default web root is /var/www/html
echo "<html><body><h1>hello from devops team</h1></body></html>" | sudo tee /var/www/html/index.html

# 3. Ensure Nginx is started and enabled to run on boot
sudo systemctl start nginx
sudo systemctl enable nginx

# 4. (Optional) Adjust firewall to allow HTTP traffic
sudo ufw allow 'Nginx HTTP'

# 5. Final message
echo "------------------------------------------------"
echo "Nginx setup complete!"
echo "Open your browser and visit: http://localhost"
echo "Or use your server IP: http://$(hostname -I | awk '{print $1}')"
echo "------------------------------------------------"
