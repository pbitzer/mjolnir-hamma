#!/bin/bash
# Install apt packages

# First, get a fresh state
apt-get update -y
apt-get dist-upgrade -y
apt-get autoremove -y

# Note: should we just apt all these for install?
apt-get install -y imagemagick  	# Needed for sindri (I think)
apt-get install -y eject        	# Automount drives
apt-get install -y udisks2			# Automount drives

# These should already be installed on the image...
apt-get install -y python3-venv
apt-get install -y git
apt-get install -y build-essential python3-dev gfortran
apt-get install -y networkd-dispatcher
apt-get install -y modemmanager




