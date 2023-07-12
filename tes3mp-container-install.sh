#!/usr/bin/bash

# ------------------------------------------------------------------------------
# MIT License
#
# Copyright (c) 2023 jefetienne
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# ------------------------------------------------------------------------------

# Get the desired destination path to run this script
tmpPath="/tmp/$(basename $0)"

# If this script isn't in /tmp/, then copy it to
# the /tmp folder and execute that copy under xterm
# Otherwise, execute this script directly
if [ $0 != $tmpPath ]; then
    # Prompt asking to install TES3MP first before creating xterm
    zenity --question --ellipsize --text 'Would you like to install TES3MP?'

    # Exit if user hit 'no'
    if [ "$?" == "1" ]; then
        exit 0
    fi

    # Create copy of this very script to /tmp/ and run it under xterm
    cp "$0" $tmpPath
    xterm -e bash -c "$tmpPath"
    exit 0
fi

# 1) Check to make sure the files /etc/subuid and /etc/subgid exist
# These are required for distrobox/podman to run, even in rootless mode
if [ ! -f /etc/subuid ] && [ ! -f /etc/subgid ]
then
    # Prompt asking to create /etc/subuid and /etc/subgid (requires root)
    zenity --question --text "The files /etc/subuid and /etc/subgid do not exist on your system, which is required to run Distrobox, the tool that will run TES3MP. Would you like to create them now? (note that this will require root permission)" --width 700

    # Exit if user hit 'no'
    if [ "$?" == "1" ]; then
        exit 0
    fi

    # Create /etc/subuid and /etc/subgid together in one sudo prompt
    # pkexec prompts the default graphical box to type in sudo password
    # Using double-quotes so we use the actual $USER, which would otherwise be set to 'root' instead
    # Add >/dev/null 2>&1 to silence the printf statement
    pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY sh -c "printf '$USER:100000:65536' | tee /etc/subuid >/dev/null 2>&1 && printf '$USER:100000:65536' | tee /etc/subgid >/dev/null 2>&1"
elif [ ! -f /etc/subuid ]
then
    # Prompt asking to create /etc/subuid (requires root)
    zenity --question --text "The file /etc/subuid does not exist on your system, which is required to run Distrobox, the tool that will run TES3MP. Would you like to create it now? (note that this will require root permission)" --width 700

    # Exit if user hit 'no'
    if [ "$?" == "1" ]; then
        exit 0
    fi

    # Create /etc/subuid
    pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY sh -c "printf '$USER:100000:65536' | tee /etc/subuid >/dev/null 2>&1"
elif [ ! -f /etc/subgid ]
then
    # Prompt asking to create /etc/subuid (requires root)
    zenity --question --text "The file /etc/subgid does not exist on your system, which is required to run Distrobox, the tool that will run TES3MP. Would you like to create it now? (note that this will require root permission)" --width 700

    # Exit if user hit 'no'
    if [ "$?" == "1" ]; then
        exit 0
    fi

    # Create /etc/subgid
    pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY sh -c "printf '$USER:100000:65536' | tee /etc/subgid >/dev/null 2>&1"
fi

installpath=$HOME/Games/tes3mp
installName="TES3MP Container Install"

# 2) Download tes3mp
if [ -d "$installpath" ]
then
    echo "TES3MP already installed at $installpath."
else
    echo "Downloading TES3MP..."
    notify-send -a "$installName" "Downloading TES3MP..."
    wget -O /tmp/tes3mp-client-linux.tar.gz https://github.com/TES3MP/TES3MP/releases/download/tes3mp-0.8.1/tes3mp-GNU+Linux-x86_64-release-0.8.1-68954091c5-6da3fdea59.tar.gz

    # 2) Extract + move to the install path
    tar -xzf /tmp/tes3mp-client-linux.tar.gz
    mkdir -p $installpath
    mv TES3MP $installpath
fi

# 3) export PATHs for further instructions
# Do this first so that we can detect if distrobox is installed in its default path
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/podman/bin:$PATH"

# 4) Install distrobox and podman
# If distrobox is not found as a command, or they would like to upgrade, then install
if ! command -v distrobox &> /dev/null || zenity --question --ellipsize --text "Distrobox is already installed. Would you like to upgrade it?'"
then
    # 3a) Install distrobox
    echo "-----"
    echo "Installing latest version of Distrobox..."
    notify-send -a "$installName" "Installing latest version of Distrobox..."
    wget -qO- https://raw.githubusercontent.com/89luca89/distrobox/main/install | sh -s -- --prefix ~/.local

    # 3b) Install podman
    echo "-----"
    echo "Installing latest version of Podman..."
    notify-send -a "$installName" "Installing latest version of Podman..."
    curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/extras/install-podman | sh -s -- --prefix ~/.local
fi

# 5) Create image
echo "-----"
echo "Setting up Distrobox container..."
notify-send -a "$installName" "Setting up Distrobox container..."
distrobox-create --image ubuntu:20.04 --name ubuntu-tes3mp

# 6) Setup image
distrobox-enter ubuntu-tes3mp -- 'sudo apt update'
distrobox-enter ubuntu-tes3mp -- 'sudo apt -y upgrade'
distrobox-enter ubuntu-tes3mp -- 'sudo apt -y install openmw libluajit-5.1-2 libxt6 net-tools libatomic1'

# 7) Make tes3mp-client script for steam
cat > $installpath/tes3mp-client.sh << EOF
#!/bin/bash

unset LD_PRELOAD
export PATH=\$HOME/.local/bin:\$HOME/.local/podman/bin:\$PATH
xhost +si:localuser:\$USER

xterm -e bash -c 'distrobox-enter ubuntu-tes3mp -- $installpath/TES3MP/tes3mp; exec bash;'
EOF

# 8) Make tes3mp-server script for steam
cat > $installpath/tes3mp-server.sh << EOF
#!/bin/bash

unset LD_PRELOAD
export PATH=\$HOME/.local/bin:\$HOME/.local/podman/bin:\$PATH
xhost +si:localuser:\$USER

ips=\$(ip addr show | grep -oE "\\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\b")

zenity --info --text "TES3MP server will be hosted on one of the IP addresses:\\n\$ips"

xterm -e bash -c 'ip addr show; distrobox-enter ubuntu-tes3mp -- $installpath/TES3MP/tes3mp-server; exec bash'

EOF

# 9) Make tes3mp-client-cfg script for steam
cat > $installpath/tes3mp-client-cfg.sh << EOF
#!/bin/bash

unset LD_PRELOAD

cfgPath="$installpath/TES3MP/tes3mp-client-default.cfg"

destAddr=\$(grep -oP '^destinationAddress =\\K[^\\n]*' \$cfgPath)

# Get trimmed destination address
destAddrTrim=\$(echo \$destAddr | sed -e 's/^[[:space:]]*//')

if [ -z \$destAddr ]; then
    zenity --error --ellipsize --text "Could not find destination address in \$cfgPath"
    return
fi

if zenity --question --ellipsize --text "TES3MP client destination IP address is currently \\"\$destAddrTrim\\". Would you like to configure this?"
then
    # Game mode is bugged from typing in zenity
    # Get user input for dest IP and trim it
    #res=\$(zenity --entry --title="Change destination IP" --text="IP Address" --entry-text "\$destAddrTrim" | sed -e 's/^[[:space:]]*//')

    # Add '^' first to make sure the line is uncommented
    # Use untrimmed destAddr in search to properly find it
    #sed -i "s/^destinationAddress\\ =\$destAddr/destinationAddress\ = \$res/gi" \$cfgPath

    # Export vars to use in xterm
    export destAddr
    export cfgPath

    # read: use -e to allow backspace
    # sed: Add '^' first to make sure the line is uncommented
    # and use untrimmed destAddr in search to properly find it
    xterm -e bash -c 'read -ep "Enter destination IP: " res;
    sed -i "s/^destinationAddress\\ =\$destAddr/destinationAddress\\ = \$res/gi" \$cfgPath
    zenity --info --ellipsize --text "Destination IP changed to \\"\$res\\""'
fi

EOF

# 10) Set scripts as executable
chmod +x $installpath/tes3mp-client.sh
chmod +x $installpath/tes3mp-server.sh
chmod +x $installpath/tes3mp-client-cfg.sh

# 11) Create TES3MP Client desktop shortcut
cat > ~/.local/share/applications/TES3MP\ Client.desktop << EOF
[Desktop Entry]
Comment[en_US]=
Comment=
Exec=$installpath/tes3mp-client.sh
GenericName[en_US]=
GenericName=
Icon=system-run
MimeType=
Name[en_US]=TES3MP Client
Name=TES3MP Client
Path=
StartupNotify=true
Terminal=true
TerminalOptions=\s--noclose
Type=Application
X-DBUS-ServiceName=
X-DBUS-StartupType=
X-KDE-SubstituteUID=false
X-KDE-Username=
Categories=Game;
EOF

# 12) Create TES3MP Server desktop shortcut
cat > ~/.local/share/applications/TES3MP\ Server.desktop << EOF
[Desktop Entry]
Comment[en_US]=
Comment=
Exec=$installpath/tes3mp-server.sh
GenericName[en_US]=
GenericName=
Icon=system-run
MimeType=
Name[en_US]=TES3MP Server
Name=TES3MP Server
Path=
StartupNotify=true
Terminal=true
TerminalOptions=\s--noclose
Type=Application
X-DBUS-ServiceName=
X-DBUS-StartupType=
X-KDE-SubstituteUID=false
X-KDE-Username=
Categories=Game;
EOF

# 13) Create TES3MP Client Config desktop shortcut
cat > ~/.local/share/applications/TES3MP\ Client\ Config.desktop << EOF
[Desktop Entry]
Comment[en_US]=
Comment=
Exec=$installpath/tes3mp-client-cfg.sh
GenericName[en_US]=
GenericName=
Icon=system-run
MimeType=
Name[en_US]=TES3MP Client Config
Name=TES3MP Client Config
Path=
StartupNotify=true
Terminal=false
TerminalOptions=\s--noclose
Type=Application
X-DBUS-ServiceName=
X-DBUS-StartupType=
X-KDE-SubstituteUID=false
X-KDE-Username=
Categories=Game;
EOF

# 14) Optionally run wizard
if zenity --question --ellipsize --text "Installation complete. Would you like to run the TES3MP Setup Wizard?"
then
    cd $installpath/TES3MP
    ./openmw-wizard
fi
