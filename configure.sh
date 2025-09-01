#!/bin/bash

# -- utils

log () {
    echo ''
    echo "## $1"
    echo ''
}

sume () {
    su guest -c "$1";
    echo "$1";
    sleep 1;
}

rboot () {

    echo -n "System will reboot in "
    for i in {10..1}; do
    	echo -n "$i "
    	sleep 1
    done

    reboot

}

# -- Update host system

log 'Updating the system'
apt update -y
apt upgrade -y

# -- Create guest user

log 'Adding user guest'
useradd guest --home /home/guest --create-home --shell /bin/bash

log 'Removing user password'
passwd -d guest

log 'Removing user bash history log'
ln -s /dev/null /home/guest/.bash_history

log 'Creating user Desktop'
mkdir -p /home/guest/Desktop

log 'Enabling auto-login for guest user'
cat /etc/gdm3/custom.conf \
| sed 's/#  AutomaticLoginEnable = true/  AutomaticLoginEnable = true/g' \
| sed 's/#  AutomaticLogin = user1/  AutomaticLogin = guest/g' > /tmp/custom.conf

cat /tmp/custom.conf > /etc/gdm3/custom.conf

# -- Install and disable tweaks

log 'Installing gnome tweaks as guest user'

sume "gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false"
sume "gsettings set org.gnome.shell enable-hot-corners false"
sume "gsettings set org.gnome.shell.extensions.dash-to-dock intellihide false"
sume "gsettings set org.gnome.shell.extensions.dash-to-dock autohide false"
sume "gsettings set org.gnome.shell.extensions.dash-to-dock hot-keys false"
sume "gsettings set org.gnome.mutter overlay-key ''"
sume "gsettings set org.gnome.nautilus.desktop trash-icon-visible false"
sume "gsettings set org.gnome.nautilus.desktop volumes-visible true"

# -- Disable folder creation fow new user

log 'Disabling unused folders creation'
cat /etc/xdg/user-dirs.conf \
| sed 's/enabled=True/enabled=False/g' > /tmp/user-dirs.conf

cat /tmp/user-dirs.conf > /etc/xdg/user-dirs.conf

echo 'DESKTOP=Desktop' > /etc/xdg/user-dirs.defaults

# -- Add smb fstab mounting point

log 'Adding fstab auto mounting point'
echo '' >> /etc/fstab
echo '# Samba video server' >> /etc/fstab
echo '//10.100.210.96/web  /media/video  cifs  vers=2.0,user=video,pass=weembirox,domain=WORKGROUP 0 0' >> /etc/fstab

# -- Remove all shortcuts for guest user

log 'Removing shortcuts'

sume "gsettings list-recursively org.gnome.desktop.wm.keybindings | sed 's/@as //g' | perl -pe 's/(.*)\s*(\[.*?\])\s*$/"'$1'"\t"'$2'"\n/' | while IFS=$'\t' read -r key val; do gsettings set "'$key'" ['']; done"

# -- Remove unused packages

log 'Managing packets'
apt remove -y firefox
apt install -y vlc

# -- Configure user rights

log 'Configuring guest user rights'

chown -R root:root /home/guest/Desktop

chmod 755 /home/guest
chmod 755 /home/guest/Desktop

# -- Configure desktop

log 'Configuring desktop environment'
echo "Skipping..."
# Might add symlink

# -- Hide top bar with user theme

log 'Hiding top bar with user theme'

cat << EOT >> /usr/share/gnome-shell/theme/ubuntu.css
/* Hide Activity in top bar */
#panelLeft .panel-button, #panelLeft .panel-button * {
    height: 0px !important; 
    width: 0px !important;
    color: rgba(0,0,0,0) !important;
    display: none !important;
    visibility: hidden !important; 
}
EOT

# -- Reboot

log 'Installation process is over.'

rboot
