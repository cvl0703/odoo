#!/bin/bash
# Instalación automatizada de Odoo 19 en Ubuntu 22.04/24.04
# Autor: ChatGPT
# -----------------------------------------------------------

echo "=== Actualizando el sistema ==="
sudo apt update && sudo apt upgrade -y

echo "=== Instalando dependencias base ==="
sudo apt install -y git wget python3 python3-pip python3-venv python3-dev \
    build-essential libxml2-dev libxslt1-dev zlib1g-dev libjpeg-dev libpq-dev \
    libldap2-dev libsasl2-dev libtiff5-dev libopenjp2-7-dev libwebp-dev \
    libharfbuzz-dev libfribidi-dev libx11-dev libfreetype6-dev

echo "=== Instalando PostgreSQL ==="
sudo apt install -y postgresql
sudo systemctl enable postgresql
sudo systemctl start postgresql

echo "=== Creando usuario de sistema 'odoo' ==="
sudo adduser --system --quiet --shell=/bin/bash --home=/opt/odoo --gecos 'odoo' --group odoo

echo "=== Creando directorios ==="
sudo mkdir -p /etc/odoo
sudo mkdir -p /var/log/odoo
sudo chown odoo:odoo /var/log/odoo -R

echo "=== Descargando Odoo 19 ==="
sudo git clone --depth 1 --branch 19.0 https://github.com/odoo/odoo /opt/odoo/odoo
sudo chown odoo:odoo /opt/odoo -R

echo "=== Creando entorno virtual Python ==="
sudo -u odoo python3 -m venv /opt/odoo/env
source /opt/odoo/env/bin/activate

echo "=== Instalando dependencias Python ==="
pip install --upgrade pip wheel setuptools
pip install -r /opt/odoo/odoo/requirements.txt

deactivate

echo "=== Instalando wkhtmltopdf ==="
sudo apt install -y fontconfig xfonts-base xfonts-75dpi
cd /tmp
wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb
sudo dpkg -i wkhtmltox_0.12.6.1-2.jammy_amd64.deb || sudo apt -f install -y
sudo ln -sf /usr/local/bin/wkhtmltopdf /usr/bin/
sudo ln -sf /usr/local/bin/wkhtmltoimage /usr/bin/

echo "=== Creando usuario odoo en PostgreSQL ==="
sudo su - postgres -c "createuser -s odoo" || true

echo "=== Generando archivo de configuración de Odoo ==="
sudo su - odoo -c "/opt/odoo/env/bin/python3 /opt/odoo/odoo/odoo-bin -s --stop-after-init"

sudo mv /opt/odoo/.odoorc /etc/odoo/odoo.conf

sudo sed -i "s,^\(logfile = \).*,\1/var/log/odoo/odoo.log," /etc/odoo/odoo.conf
sudo sed -i "s,^\(addons_path = \).*,\1/opt/odoo/odoo/addons," /etc/odoo/odoo.conf
sudo sed -i "s,^\(db_user = \).*,\1odoo," /etc/odoo/odoo.conf
sudo sed -i "s,^\(admin_passwd = \).*,\1admin123," /etc/odoo/odoo.conf

echo "=== Creando servicio systemd ==="

sudo bash -c 'cat <<EOF >/etc/systemd/system/odoo.service
[Unit]
Description=Odoo 19 Service
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
User=odoo
Group=odoo
ExecStart=/opt/odoo/env/bin/python3 /opt/odoo/odoo/odoo-bin -c /etc/odoo/odoo.conf
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF'

echo "=== Activando servicio ==="
sudo systemctl daemon-reload
sudo systemctl enable odoo
sudo systemctl start odoo

echo "=== Instalación completada ==="
echo "Odoo está disponible en: http://TU_IP:8069"
echo "Usuario PostgreSQL: odoo"
echo "Administrador Odoo (admin_passwd): admin123"
