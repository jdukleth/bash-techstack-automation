# Prerequisites

 * YUM installed on an IBM i (https://tinyurl.com/r847v6r)
 * BASH terminal (don't use PASE)
 * SSH in on user with appropriate privileges

# Getting Started

Git clone repo OR download and unzip folder onto target server

```git clone https://github.com/jdukleth/ibmi-www-install-script-files.git```

Run these commands from BASH (not PASE)

```
chmod +x www-install.sh
./www-install.sh
```

If you want to overwrite .nginx/.php/.www-menu folders from prior runs add the --nuke-files flag

```./www-install.sh --nuke-files```

# What next?

* after this script runs, type `WWW` on a 5250 session to control PHP-FPM & Nginx
* replace username and password in /QOpenSys/etc/odbc.ini
* DB2 extension doesn't exist yet; modify code for ODBC (or wait)
* Imagick ext doesn't exist yet; modify code for Zebra_Image (or wait)
* Modify code to work with the latest PHP-FPM version on YUM

# Opinionated

Here's a few things this script does that you may want to fork & modify to your liking

* runs a `yum update`
* installs all available PHP extensions (disable-at-will)
* Nginx and PHP-FPM are run as the QTMHHTTP user
* .nginx and .php are stored in /www
* The WWW menu creates a library called WWWMENU on your system
* A few php.ini default settings are changed (see script)
* PHP-FPM upstream port is changed to :9090 (from :9000) to avoid conflict with ZendServer
* odbc.ini database points to your system serial number
