bash <(curl -L -s https://raw.githubusercontent.com/Acclaim11/-8_ws-tls_bash_onekey/master/installx.sh)

bash <(curl -L -s https://raw.githubusercontent.com/Acclaim11/-8_ws-tls_bash_onekey/master/installxx.sh)

bash <(curl -L -s https://raw.githubusercontent.com/Acclaim11/-8_ws-tls_bash_onekey/master/install.sh)

bash <(curl -L -s https://raw.githubusercontent.com/Acclaim11/-8_ws-tls_bash_onekey/master/installxxx.sh)






wget --no-check-certificate -O install.sh https://raw.githubusercontent.com/Acclaim11/-8_ws-tls_bash_onekey/master/install.sh
&& chmod +x install.sh
&& ./install.sh

nano /etc/nginx/conf.d/v2ray.conf
nano /etc/nginx/nginx.conf

nano /var/log/nginx/error.log warn

systemctl start nginx 
systemctl stop nginx 

cd searx && screen -dmS searx python searx/webapp.py

