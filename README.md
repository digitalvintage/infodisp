# infodisp

infodisp is a little script to display various system-related info on customer information displays, working with Epson-style protocol.
Most of them are possible to display two strings twenty symbols long, and can be connected through RS-232 port - both native and emulated over USB.
The script can be run as daemon, it has installer that makes all the possible action to make it work. You just need to edit the config and start the service.

Run "install.sh" to install and "remove.sh" to completely uninstall infodisp. Warning! "remove.sh" also will remove all external modules and config files!

As example one external module, apcupsd.module, is included. It has its own dependencies and may be not so useable, but it needed as example how to create the modules :)
