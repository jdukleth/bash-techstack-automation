# Prerequisites

 * YUM installed on an IBM i (https://tinyurl.com/r847v6r)
 * BASH terminal (don't use PASE)
 * SSH in on user with appropriate privileges

# Getting Started

Git clone repo OR download and unzip folder onto target server

```git clone https://github.com/jdukleth/ibmi-www-install-script-files.git```

Run these commands from BASH (not PASE) terminal on target server

```
cd ibmi-www-install-script-files
chmod +x www-install.sh
./www-install.sh
```

If you want to overwrite .nginx/.php/.www-menu folders from prior runs add the --nuke-files flag

```./www-install.sh --nuke-files```

# What next?

* after this script runs, type `WWW` on a 5250 session to control PHP-FPM & Nginx
* DB2 extension doesn't exist yet; modify code for ODBC if needed
* Imagick ext doesn't exist yet; modify code for Zebra_Image if needed
* Modify code to work with the latest PHP-FPM version on YUM

# Opinionated

Here's a few things this script does that you may want to fork & modify to your liking

* runs a `yum update`
* installs all available PHP extensions (disable-at-will)
* logs & configs are stored in /www/.nginx and /www/.php for convenience
* The WWW menu creates a library called WWWMENU on your system

# Useful Paths

* /QOpenSys/etc/odbc.ini          # ODBC config
* /QOpenSys/etc/nginx             # Nginx install directory
* /QOpenSys/etc/php               # PHP-FPM install directory
* /QOpenSys/pkgs/bin/nginx        # Nginx executable
* /QOpenSys/pkgs/sbin/php-fpm     # PHP-FPM executable
* /www/.php                       # Opinionated logs/storage location
* /www/.nginx                     # Opinionated logs/configs location
