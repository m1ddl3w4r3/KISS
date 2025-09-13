# KISS - Kali Initialization & Setup Script

This script is designed to quickly setup Kali Linux enviroments to fit your needs. Based off the military standard KISS (Keep It Simple Stupid) philosophy. It uses bash and aims to teach operators how to develop there own infrastructure scripts for pentesting.

## Keep It Simple Stupid

KISS provides automated installation and configuration of the following without the pimpilishious stuff:
- Base system tools (most required to run follow-ons)
- GitHub security tools not in kali already
- Radio frequency (RF) security tools for RF engagements 
- Custom tool configurations (open to you to add your own stuff)
- WSL environment setup (installs kex in wsl kali and default tools)
- Debian to Kali conversion (Converter for cloud vms)
- Advanced OPSEC hardening (again up to you to add these)

## Requirements

- Debian-based Linux system (Ubuntu, Debian, or Kali)
- Root or sudo privileges
- Internet connection for package downloads

## Installation

### Remote Installation
```bash
curl -fsSL https://github.com/m1ddl3w4r3/KISS.git | sh
```
WARNING: you may wanna atleasat read it first to see what its going to install on your machine...

### Local Installation
```bash
git clone https://github.com/m1ddl3w4r3/KISS.git
chmod +x KISS_Github.sh
sudo ./KISS_Github.sh
```

## Configuration Variables

Edit the following variables in the script before execution:

```bash
VARHOST='Desktop-1337'                    # System hostname
SHAREFOLDER='VMShare'                     # Shared folder name
GHUSER='<YOUR GITHUB USERNAME>'           # GitHub username for SSH keys
GOLANG_VERSION='1.23.0'                  # Go version to install 1.23+ req
```

## License

This script is provided as-is for educational and professional security testing purposes. Use responsibly and in accordance with applicable laws and regulations.