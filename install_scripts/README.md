# HAMMA Pi Installation Scripts

This directory contains scripts for installing and configuring HAMMA Pi sensors.

## Quick Start

### Option 1: Automated Installation (Recommended)

Use the consolidated installation script for a streamlined experience:

```bash
# Install everything (from USB during initial setup)
cd /mnt/usb/mjolnir-hamma/install_scripts/
sudo ./install_all.sh --all -n <sensor_number>

# After Bitzer adds your SSH key to GitHub
./install_all.sh --hamma
```

### Option 2: Manual Installation

Follow the individual scripts in order as described below.

## Installation Scripts

These scripts install software components. They should be run in this order:

### 1. install_packages.sh
**Purpose:** Install system packages via apt
**Run as:** `sudo`
**Usage:**
```bash
sudo ./install_packages.sh
```

Installs:
- imagemagick (for Sindri)
- eject, udisks2 (for automounting drives)
- python3-venv, git, build tools
- networkd-dispatcher, modemmanager

---

### 2. install_brokkr.sh
**Purpose:** Install Brokkr and dependencies
**Run as:** `pi` user (NOT sudo)
**Usage:**
```bash
./install_brokkr.sh
```

Creates:
- `/home/pi/ltgenv` - Virtual environment for Brokkr, PyLTG, and HAMMA
- `/home/pi/dev/brokkr` - Brokkr installation
- `/home/pi/dev/mjolnir-hamma` - HAMMA system configuration
- `/home/pi/dev/serviceinstaller` - Service installer
- `/home/pi/dev/notifiers` - Notification tools

Installs:
- Brokkr (editable mode)
- serviceinstaller (editable mode)
- notifiers (editable mode)
- gpiozero, RPi.GPIO

**Note:** After this script, you can unmount the USB drive as mjolnir-hamma has been cloned to `/home/pi/dev/`

---

### 3. install_sindri.sh
**Purpose:** Install Sindri website generator
**Run as:** `pi` user (NOT sudo)
**Usage:**
```bash
./install_sindri.sh <sensor_number>
```

Creates:
- `/home/pi/sindrienv` - Separate virtual environment for Sindri
- `/home/pi/dev/sindri` - Sindri installation

**Warning:** This can take a long time. If running via SSH, consider backgrounding the process.

---

### 4. install_pyltg.sh
**Purpose:** Install PyLTG (Python Lightning Toolkit)
**Run as:** `pi` user (NOT sudo)
**Usage:**
```bash
./install_pyltg.sh
```

Uses the existing `ltgenv` virtual environment created by install_brokkr.sh.

Installs system dependencies:
- libhdf5-dev, libnetcdf-dev
- proj-bin, libproj-dev, libgeos-dev
- cartopy==0.19.0.post1 (specific version for Raspberry Pi OS compatibility)

---

### 5. install_hamma.sh
**Purpose:** Install HAMMA package (private repo)
**Run as:** `pi` user (NOT sudo)
**Usage:**

**First time (generate SSH key):**
```bash
./install_hamma.sh -k
```

This generates an SSH key at `/home/pi/.ssh/id_ed25519` and creates SSH config for GitHub access.

**After Bitzer adds your key to GitHub:**
```bash
./install_hamma.sh
```

This clones and installs the private HAMMA repository.

---

## Setup Scripts

These scripts configure the system after software installation:

### setup_brokkr.sh
**Purpose:** Configure Brokkr for specific sensor
**Usage:**
```bash
./setup_brokkr.sh <sensor_number>
```

Runs:
- `brokkr configure-system hamma /home/pi/dev/mjolnir-hamma`
- `brokkr configure-unit <sensor_number>`
- `brokkr install-dependencies`
- `brokkr install-all` (as sudo)

**Ignore these messages:**
- "Failed to disable unit: Unit file chronyd.service does not exist"
- "Failed to disable unit: Unit file ntpd.service does not exist"

---

### setup_uah_wireless.sh
**Purpose:** Configure UAH wireless network
**Usage:**
```bash
./setup_uah_wireless.sh <sensor_number>
```

**Prerequisites:**
- Request certificate from https://it.nsstc.uah.edu/netreg
- Place certificate on USB drive: `NSSTC-UAH-WIRELESS-mjolnir<NN>.p12`
- You'll need the MAC address of the wifi antenna

Configures:
- WPA supplicant for UAH wireless
- Network settings
- Hostname and identity
- Generates SSH key

**Note:** Don't forget to update the private key password in `/etc/wpa_supplicant/wpa_supplicant-wlan0.conf`

---

### setup_wwan.sh
**Purpose:** Configure cellular modem (WWAN)
**Run as:** `sudo`
**Usage:**
```bash
sudo ./setup_wwan.sh
```

Installs:
- udhcpc, libqmi-utils

Configures:
- `/etc/networkd-dispatcher/degraded.d/50_bring_wwan0_up.py`
- `/etc/systemd/network/20-wwan0.network`

**For Panama deployments:**
```bash
sudo sed -i -e "s/--simple-connect=apn=h2g2/--simple-connect=apn=apn01.cwpanama.com.pa/" \
    /etc/networkd-dispatcher/degraded.d/50_bring_wwan0_up.py
```

**For some modems, you may need to modify the profile:**
```bash
sudo systemctl stop ModemManager
sudo qmicli -d /dev/cdc-wdm0 -p --wds-get-profile-list=3gpp
# If no null APN entry exists:
sudo qmicli -d /dev/cdc-wdm0 --wds-create-profile=3gpp,apn=,pdp-type=IP
# Note the index and set as default:
sudo qmicli -d /dev/cdc-wdm0 --wds-set-default-profile-num=3gpp,<idx>
```

---

### setup_sensor_connect.sh
**Purpose:** Configure connection from Pi to sensor
**Run as:** `sudo`
**Usage:**
```bash
sudo ./setup_sensor_connect.sh
```

Copies:
- SSH config to `/home/pi/.ssh/config`
- Ethernet network config files to `/etc/systemd/network/`

**Test after setup:**
```bash
ssh hamma
```

---

## Utility Scripts

### update_host.sh
**Purpose:** Update hostname for the Pi
**Usage:**
```bash
./update_host.sh <sensor_number>
```

Sets hostname to `mjolnir<NN>` (e.g., `mjolnir15`)

**Note:** Requires reboot to take effect

---

### disable_wifi_radio.sh
**Purpose:** Disable internal WiFi radio
**Run as:** `sudo`
**Usage:**
```bash
sudo ./disable_wifi_radio.sh
```

Adds `dtoverlay=disable-wifi` to `/boot/config.txt`

---

### enable_automount.sh
**Purpose:** Enable automatic mounting of drives
**Run as:** `sudo`
**Usage:**
```bash
sudo ./enable_automount.sh
```

Copies mount rules from `files/mount-udisks.pkla` to `/etc/polkit-1/localauthority/50-local.d/`

**Test after setup:**
```bash
udisksctl mount --no-user-interaction -b /dev/disk/by-label/DATA<num>
```

---

### format_drives.sh
**Purpose:** Format hard drives for HAMMA data storage
**Run as:** `sudo`
**Usage:**
```bash
sudo ./format_drives.sh -m <mount_point> -n <number>
```

Example:
```bash
sudo ./format_drives.sh -m /dev/sda -n 10
```

Creates two partitions:
- `DATA10` (first 50% of drive)
- `DATA11` (second 50% of drive)

**Warning:** This will erase all data on the drive!

---

## Complete Installation Workflow

### Initial Setup (From USB)

1. **Prepare the environment:**
```bash
passwd  # Change to HAMMA Pi password
sudo raspi-config  # Fix keyboard and timezone
sudo timedatectl set-timezone UTC
rfkill unblock wifi
sudo mount /dev/sda1 /mnt/usb
```

2. **Set hostname and disable WiFi:**
```bash
cd /mnt/usb/mjolnir-hamma/install_scripts/
sudo ./disable_wifi_radio.sh
./update_host.sh <n>
# Reboot
```

3. **Configure network (choose one):**

**For UAH wireless:**
```bash
sudo mount /dev/sda1 /mnt/usb
cd /mnt/usb/mjolnir-hamma/install_scripts/
./setup_uah_wireless.sh <n>
```

**For cellular:**
```bash
sudo mount /dev/sda1 /mnt/usb
cd /mnt/usb/mjolnir-hamma/install_scripts/
sudo ./setup_wwan.sh
```

4. **Install base software:**
```bash
cd /mnt/usb/mjolnir-hamma/install_scripts/
sudo ./install_packages.sh
./install_brokkr.sh
sudo umount /mnt/usb
```

5. **Setup Brokkr:**
```bash
cd /home/pi/dev/mjolnir-hamma/install_scripts/
chmod a+x *
./setup_brokkr.sh <n>
source /home/pi/ltgenv
brokkr status
sudo systemctl start brokkr-hamma-default.service
```

6. **Configure drives:**
```bash
cd /home/pi/dev/mjolnir-hamma/install_scripts/
sudo ./format_drives.sh -m /dev/sda -n <num>
sudo ./enable_automount.sh
```

7. **Connect to sensor (if ready):**
```bash
cd /home/pi/dev/mjolnir-hamma/install_scripts/
sudo ./setup_sensor_connect.sh
# Test: ssh hamma
```

8. **Install Sindri (after server access is configured):**
```bash
cd /home/pi/dev/mjolnir-hamma/install_scripts/
./install_sindri.sh <n>
```

9. **Install HAMMA software:**
```bash
cd /home/pi/dev/mjolnir-hamma/install_scripts/
./install_pyltg.sh
./install_hamma.sh -k  # Generate SSH key
# Contact Bitzer with your public key
# After Bitzer approves:
./install_hamma.sh
```

---

## Using install_all.sh

The consolidated script simplifies the installation process:

**Full installation:**
```bash
# From USB (initial setup)
cd /mnt/usb/mjolnir-hamma/install_scripts/
sudo ./install_all.sh --all -n <sensor_number>

# After Bitzer adds your SSH key
./install_all.sh --hamma
```

**Individual components:**
```bash
# Just system packages
sudo ./install_all.sh --packages

# Just Brokkr
./install_all.sh --brokkr

# Just Sindri
./install_all.sh --sindri -n 15

# Just PyLTG
./install_all.sh --pyltg

# Generate HAMMA SSH key
./install_all.sh --hamma-key

# Install HAMMA (after key approved)
./install_all.sh --hamma
```

**Get help:**
```bash
./install_all.sh --help
```

---

## Virtual Environments

The installation creates two virtual environments:

1. **ltgenv** (`/home/pi/ltgenv`)
   - Used by: Brokkr, PyLTG, HAMMA
   - Activate: `source /home/pi/ltgenv`

2. **sindrienv** (`/home/pi/sindrienv`)
   - Used by: Sindri
   - Activate: `source /home/pi/sindrienv`

---

## Troubleshooting

### Can't connect to WiFi
```bash
sudo ifconfig wlan0 up
ifconfig  # Check for wlan0 IP address
sudo apt-get update  # Test connectivity
```

### Brokkr can't connect to charge controller
If you see "Errno 13] could not open port /dev/ttyAMA0", this is expected if the charge controller is not physically connected. The sensor will still work for data collection.

### SSH connection times out during Sindri install
The Sindri installation can take a very long time. Consider running it in a screen/tmux session or using the background option.

### Hard drive not automounting
Check polkit rules:
```bash
ls -la /etc/polkit-1/localauthority/50-local.d/
cat /etc/polkit-1/localauthority/50-local.d/mount-udisks.pkla
```

Re-run enable_automount.sh if needed.

---

## Files Directory

The `files/` directory contains configuration files used by the setup scripts:

- `10-wlan0.network` - WiFi network configuration
- `20-wwan0.network` - Cellular network configuration
- `30-eth1.network`, `40-eth0.network` - Ethernet configurations
- `50_bring_wwan0_up.py` - Script to bring up cellular modem
- `config` - SSH config for sensor connection
- `mount-udisks.pkla` - Automount rules
- `override.conf` - WPA supplicant service override
- `wpa_supplicant-wlan0.conf` - WPA supplicant configuration

---

## Additional Resources

For more detailed information, see:
- Main README: `/home/pi/dev/mjolnir-hamma/README.md`
- Brokkr documentation: https://github.com/project-mjolnir/brokkr
- Sindri documentation: https://github.com/project-mjolnir/sindri

---

## Support

For issues or questions, contact Bitzer or Burchfield.
