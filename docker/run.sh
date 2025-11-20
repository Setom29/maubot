#!/bin/sh

fixperms() {
    chown -R "$UID:$GID" /var/log /data
}

fixdefault() {
    _value=$(yq e "$1" /data/config.yaml 2>/dev/null)
    if [ "$_value" = "$2" ]; then
        yq e -i "$1 = \"$3\"" /data/config.yaml
    fi
}

fixconfig() {
    fixdefault '.database' 'sqlite:maubot.db' 'sqlite:/data/maubot.db'
    fixdefault '.plugin_directories.upload' './plugins' '/data/plugins'
    fixdefault '.plugin_directories.load[0]' './plugins' '/data/plugins'
    fixdefault '.plugin_directories.trash' './trash' '/data/trash'
    fixdefault '.plugin_databases.sqlite' './plugins' '/data/dbs'
    fixdefault '.plugin_databases.sqlite' './dbs' '/data/dbs'
    fixdefault '.logging.handlers.file.filename' './maubot.log' '/var/log/maubot.log'
    yq e -i '.server.override_resource_path = "/opt/maubot/frontend"' /data/config.yaml
}

cd /opt/maubot || exit 1

mkdir -p /var/log/maubot /data/plugins /data/trash /data/dbs

if [ ! -f /data/config.yaml ]; then
    cp example-config.yaml /data/config.yaml
    echo "Config file not found. Example config copied to /data/config.yaml"
    echo "Please modify the config file to your liking and restart the container."
    fixperms
    fixconfig
    exit 0
fi

fixperms
fixconfig

if ls /data/plugins/*.db >/dev/null 2>&1; then
    mv -n /data/plugins/*.db /data/dbs/
fi

exec gosu "$UID:$GID" python3 -m maubot -c /data/config.yaml
