# TES3MP Container Install Script
An install script to play multiplayer Morrowind ([TES3MP](https://github.com/TES3MP/TES3MP)) painlessly on the Steam Deck and other immutable distros.

TES3MP is a project that brings a multiplayer co-op experience for Morrowind. Simply download the tes3mp-container-install.sh file and double-click to run it. Recommended to have Morrowind installed first prior to running the script so that Morrowind.esm can be selected in the TES3MP Setup Wizard.

# Features
- Downloads and installs TES3MP, along with rootless [Distrobox+Podman](https://github.com/89luca89/distrobox) to run TES3MP through it. **Note** that you may need root permission to get two system files (`/etc/subuid` and `/etc/subgid`) created for Distrobox if they do not exist already.
- Generates three .desktop launch files made of shell scripts, easy for adding as non-Steam games:
  - ***TES3MP Client*** - Runs the multiplayer game of Morrowind on the specific server name
  - ***TES3MP Client Config*** - Runs a specially-made script to easily change the IP address/url for the server before running the *TES3MP Client*
  - ***TES3MP Server*** - Starts running a multiplayer server in the background. (Yes, you can run both the server in the background and the client together in Game Mode!)
- Prompts the TES3MP Setup Wizard after installation to select your Morrowind.esm file.
- Can also be rerun multiple times to upgrade your Distrobox software as well as your container's packages.

# Why write an install script?
*tl;dr* it is a pain to set up and get running in SteamOS's Game Mode, and would take too long manually doing it for a friend. Making a Flatpak/AppImage distribution of the software would also be ideal, but that would take even more effort to get working, probably especially with the server integration.

Essentially, TES3MP is distributed as a portable zip/tar.gz, and in order to run the server and client, it requires some software libraries that SteamOS doesn't come bundled with. I've seen other people create guides for getting TES3MP set up on the Steam Deck, but they rely on having to unlock the read-only file system on the OS to install these libraries through Arch Linux's package manager called 'pacman', which gets wiped on the next SteamOS update. Annoying, and not clean nor in the spirit of "immutable distro" philosophy. Additionally, it can be tricky trying to run both the TES3MP server and the client in SteamOS's Game Mode.

What my install script does is it creates a semi-isolated OS "environment" called a container that resides entirely within your user folder (`/home/deck/`), and it installs these missing system libraries inside of it to run both the TES3MP client and server. This is all done through the magic of **Distrobox**, a software tool that my install script will download that allows you to create these containers that integrate with the host system much closer and more lightweight than a virtual machine would. And it'll persist through SteamOS updates. Additionally, it also creates three little launcher files (.desktop) that you can search up and open on your start menu and also easily add as non-Steam games to Steam. These launchers boot up the TES3MP programs within the container and disable certain environmental flags from Steam that interfere with running them.

The only requirement prior to running this install script is that you might need to have a root password made, so that way it can create two system files in /etc that will reside permanently on your system and that are needed for Distrobox/podman to run. If you don't know how to set up your root password, you can open up a terminal and run the command `passwd` which will prompt for the creation of a root password. (Write it down! Do not forget it otherwise you'll have go through the pain of [setting up a recovery image to reset it](https://www.youtube.com/watch?v=BSj44Iovxq8&list=LL&index=1&pp=gAQBiAQB)!) And ideally, have Morrowind installed first because the script prompts the TES3MP Setup wizard at the end to find the Morrowind.esm file.

# Known issues
Feel free to contribute by submitting any bug reports/improvements for other distro compatibilty. I'm not looking at moment to expand this functionality into a Gtk/Qt wizard because eventually TES3MP will become deprecated when it merges with the [OpenMW](https://openmw.org/en/) project.

<h4>Issues found:</h4>

- You may encounter one or two yes/no prompts in the terminal. Please let me know in the comments or GitHub where it happens again because I can't replicate it anymore.
- It may prompt for a TUI language/timezone setup in the terminal when installing needed packages for the container. I'm not sure where it's coming from, I can't replicate it anymore, and I don't know if I can automate this.
- Sometimes, running the TES3MP Client in Game Mode will crash the first time around, but it almost always works the second time around.
