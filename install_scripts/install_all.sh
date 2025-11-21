#!/bin/bash
# Consolidated installation script for HAMMA Pi
# This script can install all software components or individual pieces

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SENSOR_NUM=""
INSTALL_PACKAGES=false
INSTALL_BROKKR=false
INSTALL_SINDRI=false
INSTALL_PYLTG=false
INSTALL_HAMMA=false
INSTALL_HAMMA_KEY=false
INSTALL_ALL=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "${GREEN}===================================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}===================================================${NC}"
}

print_info() {
    echo -e "${YELLOW}INFO: $1${NC}"
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

print_success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Consolidated installation script for HAMMA Pi software components.

OPTIONS:
    -h, --help              Show this help message
    -n, --sensor-num NUM    Sensor number (required for sindri)

    --all                   Install all components in correct order
    --packages              Install system packages only
    --brokkr                Install Brokkr only
    --sindri                Install Sindri only (requires -n)
    --pyltg                 Install PyLTG only
    --hamma                 Install HAMMA package only
    --hamma-key             Generate SSH key for HAMMA repo (first time only)

EXAMPLES:
    # Install everything
    $0 --all -n 15

    # Install just system packages
    sudo $0 --packages

    # Install just Brokkr
    $0 --brokkr

    # Install Sindri for sensor 15
    $0 --sindri -n 15

    # First time HAMMA install (generate SSH key)
    $0 --hamma-key

    # Install HAMMA package (after Bitzer adds your key to GitHub)
    $0 --hamma

INSTALLATION ORDER (when using --all):
    1. System packages (install_packages.sh)
    2. Brokkr (install_brokkr.sh)
    3. Sindri (install_sindri.sh)
    4. PyLTG (install_pyltg.sh)
    5. HAMMA setup key (install_hamma.sh -k)

    NOTE: After running --all, you must contact Bitzer to add your
    SSH key to GitHub, then run: $0 --hamma

EOF
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -n|--sensor-num)
            SENSOR_NUM="$2"
            shift 2
            ;;
        --all)
            INSTALL_ALL=true
            shift
            ;;
        --packages)
            INSTALL_PACKAGES=true
            shift
            ;;
        --brokkr)
            INSTALL_BROKKR=true
            shift
            ;;
        --sindri)
            INSTALL_SINDRI=true
            shift
            ;;
        --pyltg)
            INSTALL_PYLTG=true
            shift
            ;;
        --hamma)
            INSTALL_HAMMA=true
            shift
            ;;
        --hamma-key)
            INSTALL_HAMMA_KEY=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            ;;
    esac
done

# If --all is specified, set all flags
if $INSTALL_ALL; then
    INSTALL_PACKAGES=true
    INSTALL_BROKKR=true
    INSTALL_SINDRI=true
    INSTALL_PYLTG=true
    INSTALL_HAMMA_KEY=true
fi

# Check if at least one install option is selected
if ! $INSTALL_PACKAGES && ! $INSTALL_BROKKR && ! $INSTALL_SINDRI && \
   ! $INSTALL_PYLTG && ! $INSTALL_HAMMA && ! $INSTALL_HAMMA_KEY; then
    print_error "No installation option specified"
    usage
fi

# Validate sensor number if needed
if $INSTALL_SINDRI && [[ -z "$SENSOR_NUM" ]]; then
    print_error "Sensor number (-n) is required for Sindri installation"
    exit 1
fi

# Check if running from USB or local install
if [[ "$SCRIPT_DIR" == "/mnt/usb"* ]]; then
    LOCATION="USB"
else
    LOCATION="LOCAL"
fi

print_info "Installation location: $LOCATION"
print_info "Script directory: $SCRIPT_DIR"

# Main installation flow
if $INSTALL_PACKAGES; then
    print_header "Installing System Packages"
    if [[ $EUID -ne 0 ]]; then
        print_error "System package installation requires sudo privileges"
        print_info "Run: sudo $0 --packages"
        exit 1
    fi
    cd "$SCRIPT_DIR"
    chmod +x install_packages.sh
    ./install_packages.sh
    print_success "System packages installed"
fi

if $INSTALL_BROKKR; then
    print_header "Installing Brokkr"
    if [[ $EUID -eq 0 ]]; then
        print_error "Brokkr installation should NOT be run with sudo"
        exit 1
    fi
    cd "$SCRIPT_DIR"
    chmod +x install_brokkr.sh
    ./install_brokkr.sh
    print_success "Brokkr installed"

    if [[ "$LOCATION" == "USB" ]]; then
        print_info "mjolnir-hamma has been cloned to /home/pi/dev/mjolnir-hamma"
        print_info "You can now unmount the USB drive"
    fi
fi

if $INSTALL_SINDRI; then
    print_header "Installing Sindri for sensor $SENSOR_NUM"
    if [[ $EUID -eq 0 ]]; then
        print_error "Sindri installation should NOT be run with sudo"
        exit 1
    fi
    cd "$SCRIPT_DIR"
    chmod +x install_sindri.sh
    print_info "This may take a while..."
    ./install_sindri.sh "$SENSOR_NUM"
    print_success "Sindri installed"
fi

if $INSTALL_PYLTG; then
    print_header "Installing PyLTG"
    if [[ $EUID -eq 0 ]]; then
        print_error "PyLTG installation should NOT be run with sudo"
        exit 1
    fi
    cd "$SCRIPT_DIR"
    chmod +x install_pyltg.sh
    print_info "Installing system dependencies and PyLTG..."
    ./install_pyltg.sh
    print_success "PyLTG installed"
fi

if $INSTALL_HAMMA_KEY; then
    print_header "Setting up SSH key for HAMMA repository"
    if [[ $EUID -eq 0 ]]; then
        print_error "HAMMA key setup should NOT be run with sudo"
        exit 1
    fi
    cd "$SCRIPT_DIR"
    chmod +x install_hamma.sh
    ./install_hamma.sh -k
    print_success "SSH key generated"
    echo ""
    print_info "IMPORTANT: Contact Bitzer and provide your SSH public key:"
    echo ""
    cat /home/pi/.ssh/id_ed25519.pub
    echo ""
    print_info "After Bitzer adds your key to GitHub, run:"
    print_info "  $0 --hamma"
fi

if $INSTALL_HAMMA; then
    print_header "Installing HAMMA package"
    if [[ $EUID -eq 0 ]]; then
        print_error "HAMMA installation should NOT be run with sudo"
        exit 1
    fi

    if [[ ! -f /home/pi/.ssh/id_ed25519 ]]; then
        print_error "SSH key not found. Run with --hamma-key first"
        exit 1
    fi

    cd "$SCRIPT_DIR"
    chmod +x install_hamma.sh
    print_info "You may need to accept RSA fingerprinting..."
    ./install_hamma.sh
    print_success "HAMMA package installed"
fi

# Final summary
print_header "Installation Summary"
$INSTALL_PACKAGES && echo -e "${GREEN}✓${NC} System packages"
$INSTALL_BROKKR && echo -e "${GREEN}✓${NC} Brokkr"
$INSTALL_SINDRI && echo -e "${GREEN}✓${NC} Sindri"
$INSTALL_PYLTG && echo -e "${GREEN}✓${NC} PyLTG"
$INSTALL_HAMMA_KEY && echo -e "${GREEN}✓${NC} HAMMA SSH key"
$INSTALL_HAMMA && echo -e "${GREEN}✓${NC} HAMMA package"

if $INSTALL_ALL; then
    echo ""
    print_info "Next steps:"
    echo "  1. Send your SSH public key to Bitzer (displayed above)"
    echo "  2. After Bitzer confirms, run: $0 --hamma"
    echo "  3. Run setup scripts as needed (setup_brokkr.sh, etc.)"
fi

print_success "Installation complete!"
