#!/bin/bash

###################################################
# DISCLAIMER: Read this script before you run it
#    so you aren't surprised by anything it does
###################################################

###################################################
# PREREQUISITES
#    YUM installed on an IBM i (shorturl.at/duz02)
#    BASH terminal (don't use PASE)
###################################################

###################################################
# HOW TO RUN THIS SCRIPT
#  git clone (or unzip) folder onto target server
#  run these commands from BASH (not PASE)
#    `cd /path/to/folder`
#    `chmod +x www-install.sh`
#    `./www-install.sh`
#  if you want to overwrite .nginx/.php/.www-menu
#  folders from prior runs:
#    `./www-install.sh --nuke-files`
###################################################

###################################################
# WHAT NEXT?
#  after this script runs, type `WWW` on a 5250
#  session to control PHP-FPM & Nginx
#  website code:
#    DB2 ext doesn't exist yet (use ODBC for now)
#    Imagick ext doesn't exist yet (use Zebra_Image)
#    you may need to update code for latest PHP
###################################################

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

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
# Copy Files For Nginx/PHP-FPM/Menu Configuration
###################################################
cd $SCRIPT_DIR

# remove files from prior runs if user supplies flag
if [[ $* == *--nuke-files* ]]; then
  rm -rf /www/.nginx
  rm -rf /www/.php
  rm -rf /www/.www-menu
fi

cp -r .nginx /www/
cp -r .php /www/
cp -r .www-menu /www/

###################################################
# Install IBM i Access ODBC Driver via Yum
###################################################
cd /www/.php/pase-acs/ppc64
yum install ibm-iaccess-*

###################################################
# extract SAVF files for WWW menu
# Move WWW menu files to WWWTOOLS library
# Compile menu and setup menu commands
###################################################

# extract SAVF files to WWWTEMP
system 'DLTOBJ OBJ(QGPL/WWWSAVF) OBJTYPE(*FILE)'
system 'CRTSAVF FILE(QGPL/WWWSAVF)'
system "CPYFRMSTMF FROMSTMF('/www/.www-menu/WWWSAVF') TOMBR('/QSYS.LIB/QGPL.LIB/WWWSAVF.FILE') MBROPT(*REPLACE)"
system 'DLTLIB LIB(WWWTEMP)'
system 'RSTLIB SAVLIB(WWWTEMP) DEV(*SAVF) SAVF(QGPL/WWWSAVF)'

# copy files from WWWTEMP to WWWTOOLS
system "CRTLIB LIB(WWWTOOLS) TEXT('Program Tooling Library')"
system 'CPYF FROMFILE(WWWTEMP/QCLSRC) TOFILE(WWWTOOLS/QCLSRC) FROMMBR(WWW) TOMBR(WWW) MBROPT(*REPLACE) CRTFILE(*NO) FMTOPT(*MAP *DROP)'
system 'CPYF FROMFILE(WWWTEMP/QCMDSRC) TOFILE(WWWTOOLS/QCMDSRC) FROMMBR(WWW) TOMBR(WWW) MBROPT(*REPLACE) CRTFILE(*NO) FMTOPT(*MAP *DROP)'
system 'CPYF FROMFILE(WWWTEMP/QDDSSRC) TOFILE(WWWTOOLS/QDDSSRC) FROMMBR(WWWMNU1) TOMBR(WWWMNU1) MBROPT(*REPLACE) CRTFILE(*NO) FMTOPT(*MAP *DROP)'
system 'CPYF FROMFILE(WWWTEMP/QDDSSRC) TOFILE(WWWTOOLS/QDDSSRC) FROMMBR(WWWMNU1QQ) TOMBR(WWWMNU1QQ) MBROPT(*REPLACE) CRTFILE(*NO) FMTOPT(*MAP *DROP)'

# create files that Screen Design Assistant (SDA) would normally generate
system 'CRTDSPF FILE(WWWTOOLS/WWWMNU1) SRCFILE(WWWTOOLS/QDDSSRC)'
system 'DLTMSGF MSGF(WWWTOOLS/WWWMNU1)'
system 'CRTMSGF MSGF(WWWTOOLS/WWWMNU1)'
system 'CRTMNU MENU(WWWTOOLS/WWWMNU1) TYPE(*DSPF) DSPF(WWWTOOLS/*MENU) MSGF(WWWTOOLS/*MENU)'

# compile CL program to GO to menu
system 'CRTCLPGM PGM(WWWTOOLS/WWW) SRCFILE(WWWTOOLS/QCLSRC)'

# create 'WWW' system command
system 'CRTCMD PGM(WWWTOOLS/WWW) CMD(QGPL/WWW) SRCFILE(WWWTOOLS/QCMDSRC)'

# tie commands to menu options
system "ADDMSGD MSGID(USR0001) MSGF(WWWTOOLS/WWWMNU1) MSG('WRKACTJOB SBS(*ALL) JOB(QP0ZSPWP)')"
system "ADDMSGD MSGID(USR0003) MSGF(WWWTOOLS/WWWMNU1) MSG('SBMJOB CMD(QSH CMD(''/QOpenSys/pkgs/bin/nginx -s reload'')) USER(QTMHHTTP)')"
system "ADDMSGD MSGID(USR0004) MSGF(WWWTOOLS/WWWMNU1) MSG('SBMJOB CMD(QSH CMD(''/QOpenSys/pkgs/bin/nginx'')) USER(QTMHHTTP)')"
system "ADDMSGD MSGID(USR0005) MSGF(WWWTOOLS/WWWMNU1) MSG('SBMJOB CMD(QSH CMD(''/QOpenSys/pkgs/bin/nginx -s stop'')) USER(QTMHHTTP)')"
system "ADDMSGD MSGID(USR0006) MSGF(WWWTOOLS/WWWMNU1) MSG('wrklnk ''/www/.nginx/logs/error.log''')"
system "ADDMSGD MSGID(USR0007) MSGF(WWWTOOLS/WWWMNU1) MSG('wrklnk ''/www/.nginx/*''')"
system "ADDMSGD MSGID(USR0008) MSGF(WWWTOOLS/WWWMNU1) MSG('QSH CMD(''/QOpenSys/pkgs/bin/nginx -t'')')"
system "ADDMSGD MSGID(USR0010) MSGF(WWWTOOLS/WWWMNU1) MSG('SBMJOB CMD(QSH CMD(''/QOpenSys/pkgs/sbin/php-fpm'')) USER(QTMHHTTP)')"
system "ADDMSGD MSGID(USR0011) MSGF(WWWTOOLS/WWWMNU1) MSG('QSH CMD(''/QOpenSys/usr/bin/sh -c \"/www/.php/bin/stop-php.sh\"'')')"
system "ADDMSGD MSGID(USR0012) MSGF(WWWTOOLS/WWWMNU1) MSG('wrklnk ''/www/.php/logs/*''')"
system "ADDMSGD MSGID(USR0013) MSGF(WWWTOOLS/WWWMNU1) MSG('wrklnk ''/QOpenSys/etc/php/*''')"
system "ADDMSGD MSGID(USR0014) MSGF(WWWTOOLS/WWWMNU1) MSG('QSH CMD(''/QOpenSys/pkgs/sbin/php-fpm -t'')')"

###################################################
# Nginx: Configuration & Settings
###################################################

CONFFROM=/www/.nginx/nginx.conf
CONFTO=/QOpenSys/etc/nginx/nginx.conf
CONFBU=/QOpenSys/etc/nginx/nginx.conf-bu

# backup original conf if backup doesn't exist from prior runs
if [ -f "$CONFTO" ]; then
  if [ -f "$CONFBU" ]; then
    rm $CONFTO
  else
    mv $CONFTO $CONFBU
  fi
fi

# symlink our .conf file so that we can use `nginx` without -c flag
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

# change PHP-FPM upstream port to :9090 (default :9000 conflicts with ZendServer's PHP)
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

# TODO: prompt for ODBC DB username and password and overwrite in odbc.ini
# TODO: prompt other config options to make script more versatile
# TODO: prettify success/no-change output and keep error output raw
