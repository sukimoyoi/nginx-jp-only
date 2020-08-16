#!/bin/bash

# apache用の.htaccessをnginx用に書き換える
# deny allは最後に持っていかないと、せっかくallow書いても全部deny扱いになるので注意

cidr_buff=$(curl -sS -X POST http://www.cgis.biz/tools/access/ -d "submit_download=.htaccessダウンロード" | \
            sed -e "s/from //g" | \
            sed -e "s/order deny,allow//g" | \
            sed -e "s/deny all//g" | \
            sed -e "/^$/d" | \
            sed "$ a deny all" | \
            sed -e "s/$/\;/g" | \
            sed -e "s/^/        /g" )


cat << EOF > default.conf
server {
    server_name  fuga.com;
    
    proxy_set_header    Host    \$host;
    proxy_set_header    X-Real-IP    \$remote_addr;
    proxy_set_header    X-Forwarded-Host       \$host;
    proxy_set_header    X-Forwarded-Server    \$host;
    proxy_set_header    X-Forwarded-For    \$proxy_add_x_forwarded_for;

    location / {
$(echo "$cidr_buff")

        proxy_pass    http://hoge.com:8080;
    }
}
EOF

docker run -d --name nginx -p 80:80 \
       -v $(pwd)/default.conf:/etc/nginx/conf.d/default.conf nginx