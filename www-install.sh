#!/bin/bash

###################################################
# HOW TO RUN THIS SCRIPT
#  copy this script to target server
#  run these commands from a bash terminal:
#    `cd /path/to/folder`
#    `chmod +x www-install.sh`
#    `./www-install.sh`
#  if you want to overwrite .nginx/.php folders:
#    `./www-install.sh --ftp-nuke`
###################################################

###################################################
# WHAT NEXT?
#  after this script runs type `WWW` on a 5250
#  session to control PHP-FPM & Nginx
#  website code:
#    DB2 ext doesn't exist yet (use ODBC for now)
#    Imagick ext doesn't exist yet (use Zebra_Image)
#    you may need to upgrade code for latest PHP
###################################################

###################################################
# Yum Repo/Package Installations
###################################################

# make yum-config-manager command available
yum -y install yum-utils

# add PHP-FPM repo
yum-config-manager --add-repo http://repos.zend.com/ibmiphp/

# update current repos & packages
yum clean all
yum -y update

# install all other requisite packages for PHP-FPM + Nginx
yum -y install php* nginx unixODBC unixODBC-devel lftp unzip findutils

# move errant php.ini location (remove after IBM releases fix)
PHPINIFROM=/QOpenSys/etc/php.ini
PHPINITO=/QOpenSys/etc/php/
if [ -f "$PHPINIFROM" ]; then
  mv $PHPINIFROM $PHPINITO
fi

###################################################
# FTP Files For Nginx/PHP-FPM/ODBC Configuration
###################################################
cd /www

# overwrite files if user supplies --replace-configs flag
if [[ $* == *--ftp-nuke* ]]; then
  lftp ftp://mail.softaltern.com:5100 -u lowang,400zilla << EOT
    cd nginx-php
    mirror .nginx
    mirror .php
    quit
EOT
# otherwise only copy missing files
else
  lftp ftp://mail.softaltern.com:5100 -u lowang,400zilla << EOT
    cd nginx-php
    mirror .nginx --only-missing
    mirror .php --only-missing
    quit
EOT
fi

###################################################
# Install IBM i Access ODBC Driver via Yum
###################################################
cd /www/.php/pase-acs/ppc64
yum install ibm-iaccess-*

###################################################
# Copy SAVF for WWW menu
###################################################
cd /ComEdge

lftp ftp://mail.softaltern.com:5100 -u lowang,400zilla << EOT
  cd nginx-php
  pget JDSAVF
  quit
EOT

###################################################
# extract SAVF files for WWW menu
# Move WWW menu files to SATOOLS library
# Compile menu and setup menu commands
###################################################

# extract SAVF files to SATOOLS4
system 'DLTOBJ OBJ(QGPL/JDSAVF) OBJTYPE(*FILE)'
system 'CRTSAVF FILE(QGPL/JDSAVF)'
system "CPYFRMSTMF FROMSTMF('/ComEdge/JDSAVF') TOMBR('/QSYS.LIB/QGPL.LIB/JDSAVF.FILE') MBROPT(*REPLACE)"
system 'DLTLIB LIB(SATOOLS4)'
system 'RSTLIB SAVLIB(SATOOLS4) DEV(*SAVF) SAVF(QGPL/JDSAVF)'

# copy files from SATOOLS4 to SATOOLS
system 'CPYF FROMFILE(SATOOLS4/QCLSRC) TOFILE(SATOOLS/QCLSRC) FROMMBR(WWW) TOMBR(WWW) MBROPT(*REPLACE) CRTFILE(*NO) FMTOPT(*MAP *DROP)'
system 'CPYF FROMFILE(SATOOLS4/QCMDSRC) TOFILE(SATOOLS/QCMDSRC) FROMMBR(WWW) TOMBR(WWW) MBROPT(*REPLACE) CRTFILE(*NO) FMTOPT(*MAP *DROP)'
system 'CPYF FROMFILE(SATOOLS4/QDDSSRC) TOFILE(SATOOLS/QDDSSRC) FROMMBR(WWWMNU1) TOMBR(WWWMNU1) MBROPT(*REPLACE) CRTFILE(*NO) FMTOPT(*MAP *DROP)'
system 'CPYF FROMFILE(SATOOLS4/QDDSSRC) TOFILE(SATOOLS/QDDSSRC) FROMMBR(WWWMNU1QQ) TOMBR(WWWMNU1QQ) MBROPT(*REPLACE) CRTFILE(*NO) FMTOPT(*MAP *DROP)'

# create files that Screen Design Assistant (SDA) would normally generate
system 'CRTDSPF FILE(SATOOLS/WWWMNU1) SRCFILE(SATOOLS/QDDSSRC)'
system 'DLTMSGF MSGF(SATOOLS/WWWMNU1)'
system 'CRTMSGF MSGF(SATOOLS/WWWMNU1)'
system 'CRTMNU MENU(SATOOLS/WWWMNU1) TYPE(*DSPF) DSPF(SATOOLS/*MENU) MSGF(SATOOLS/*MENU)'

# compile CL program to GO to menu
system 'CRTCLPGM PGM(SATOOLS/WWW) SRCFILE(SATOOLS/QCLSRC)'

# create 'WWW' system command
system 'CRTCMD PGM(SATOOLS/WWW) CMD(QGPL/WWW) SRCFILE(SATOOLS/QCMDSRC)'

# tie commands to menu options
system "ADDMSGD MSGID(USR0001) MSGF(SATOOLS/WWWMNU1) MSG('WRKACTJOB SBS(*ALL) JOB(QP0ZSPWP)')"
system "ADDMSGD MSGID(USR0003) MSGF(SATOOLS/WWWMNU1) MSG('SBMJOB CMD(QSH CMD(''/QOpenSys/pkgs/bin/nginx -s reload'')) USER(QTMHHTTP)')"
system "ADDMSGD MSGID(USR0004) MSGF(SATOOLS/WWWMNU1) MSG('SBMJOB CMD(QSH CMD(''/QOpenSys/pkgs/bin/nginx'')) USER(QTMHHTTP)')"
system "ADDMSGD MSGID(USR0005) MSGF(SATOOLS/WWWMNU1) MSG('SBMJOB CMD(QSH CMD(''/QOpenSys/pkgs/bin/nginx -s stop'')) USER(QTMHHTTP)')"
system "ADDMSGD MSGID(USR0006) MSGF(SATOOLS/WWWMNU1) MSG('wrklnk ''/www/.nginx/logs/error.log''')"
system "ADDMSGD MSGID(USR0007) MSGF(SATOOLS/WWWMNU1) MSG('wrklnk ''/www/.nginx/*''')"
system "ADDMSGD MSGID(USR0008) MSGF(SATOOLS/WWWMNU1) MSG('QSH CMD(''/QOpenSys/pkgs/bin/nginx -t'')')"
system "ADDMSGD MSGID(USR0010) MSGF(SATOOLS/WWWMNU1) MSG('SBMJOB CMD(QSH CMD(''/QOpenSys/pkgs/sbin/php-fpm'')) USER(QTMHHTTP)')"
system "ADDMSGD MSGID(USR0011) MSGF(SATOOLS/WWWMNU1) MSG('QSH CMD(''/QOpenSys/usr/bin/sh -c \"/www/.php/bin/stop-php.sh\"'')')"
system "ADDMSGD MSGID(USR0012) MSGF(SATOOLS/WWWMNU1) MSG('wrklnk ''/www/.php/logs/*''')"
system "ADDMSGD MSGID(USR0013) MSGF(SATOOLS/WWWMNU1) MSG('wrklnk ''/QOpenSys/etc/php/*''')"
system "ADDMSGD MSGID(USR0014) MSGF(SATOOLS/WWWMNU1) MSG('QSH CMD(''/QOpenSys/pkgs/sbin/php-fpm -t'')')"

###################################################
# Nginx: Configuration & Settings
###################################################

# symlink our .conf file so that we can use `nginx` without -c flag
CONFFROM=/www/.nginx/nginx.conf
CONFTO=/QOpenSys/etc/nginx/nginx.conf
if [ -f "$CONFTO" ]; then
  rm $CONFTO
fi

ln -s $CONFFROM $CONFTO

###################################################
# PHP: Configuration & Settings
###################################################

# php.ini settings
sed -i 's/max_execution_time = 30/max_execution_time = 120/g' /QOpenSys/etc/php/php.ini
sed -i 's/memory_limit = 128M/memory_limit = 2048M/g' /QOpenSys/etc/php/php.ini
sed -i 's/;error_log = php_errors.log/error_log = \/www\/.php\/logs\/php.log/g' /QOpenSys/etc/php/php.ini
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=1/g' /QOpenSys/etc/php/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 8M/g' /QOpenSys/etc/php/php.ini
sed -i 's/;date.timezone =/date.timezone = America\/Chicago/g' /QOpenSys/etc/php/php.ini
sed -i 's/;curl.cainfo =/curl.cainfo = \/www\/.php\/ssl\/cacert.pem/g' /QOpenSys/etc/php/php.ini
sed -i 's/;openssl.cafile=/openssl.cafile=\/www\/.php\/ssl\/cacert.pem/g' /QOpenSys/etc/php/php.ini
sed -i 's/;openssl.capath=/openssl.capath=\/www\/.php\/ssl\//g' /QOpenSys/etc/php/php.ini

# change PHP-FPM port to :9090 (default :9000 conflicts with ZendServer's PHP)
sed -i 's/127.0.0.1:9000/127.0.0.1:9090/g' /QOpenSys/etc/php/php-fpm.d/www.conf

# move fastcgi script into place
rm -rf /QOpenSys/etc/nginx/snippets
mv /www/.nginx/snippets /QOpenSys/etc/nginx/

###################################################
# ODBC: Configuration & Settings
###################################################

# overwrite ODBC config file
rm /QOpenSys/etc/odbc.ini
mv /www/.php/odbc.ini /QOpenSys/etc/

SRLNBR=$(system 'wrksysval qsrlnbr' | grep QSRLNBR | awk '{print $2}')
HOSTNAME=$(hostname)
sed -i "s/HOSTNAME_HERE/$HOSTNAME/g" /QOpenSys/etc/odbc.ini
sed -i "s/QSRLNBR_HERE/S$SRLNBR/g" /QOpenSys/etc/odbc.ini
