/QOpenSys/pkgs/bin/bash -c "kill $(ps ax | grep php-fpm | awk '{print $1}')" > /dev/null 2>&1
