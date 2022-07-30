#!/bin/bash
#Kali Initialization & Setup Script
#@m1ddl3w4r3
#V 0.2
#Credit Shyft @earcmile for the idea and bits of code.
################################################################################
#Settings Section
#You should at miminum change the Hostname(VARHOST), Shared Folder Name(SHAREFOLDER), and Github Username(GHUSER). I install tools from my github for version control and custom addons. I recommend you do the same.
#Add aditional Settings here if needed.
#Hostname
VARHOST='Desktop-2672'
#Shared Folder Name.
SHAREFOLDER='VMShare'
#Username
GHUSER='m1ddl3w4r3'
#Locations of install Folders. (Change if needed)
mkdir $HOME/.KISS > /dev/null 2>&1
WD=''$HOME'/.KISS'
AWD=''$HOME'/Applications'
TWD=''$HOME'/Tools'
################################################################################
##CleanUp & Setup
#Change things you want to add or remove and add things to install that are built into Kali or needed for other packages.
CLEANUPSETUP(){
  clear
  echo -e "${GREEN}Updating Apt${NC}"
  sudo apt update -y > /dev/null 2>&1
  echo ""
  echo -e "${GREEN}Cleaning Up & Setting Up${NC}"
  echo -ne '>>>                       [20%]\r'
  #Cleanup
  cd $HOME
  rm -rf $HOME/Music $HOME/Public $HOME/Templates $HOME/Videos
  echo -ne '>>>>>>>>>>                [40%]\r'
  #Setup
  mkdir $TWD > /dev/null 2>&1
  mkdir $AWD > /dev/null 2>&1
  ##Updates
  echo -ne '>>>>>>>>>>>>>>            [60%]\r'
  sudo apt install -y libwacom-common libwacom9 > /dev/null 2>&1
  sudo apt install -y screen git curl wget mingw-w64 > /dev/null 2>&1
  echo -ne '>>>>>>>>>>>>>>>>>>>>      [80%]\r'
  sudo apt install -y zip gzip htop python3-pip > /dev/null 2>&1
  sudo apt install -y libpcap-dev build-essential > /dev/null 2>&1
  echo -ne '>>>>>>>>>>>>>>>>>>>>>>>>>>[100%]\r'
  echo -ne '\n'
  echo -e "${GREEN}Updates Complete.${NC}"
  #################################################################
}
################################################################################
#Base section
BASE(){
  BASECHECK=''$WD'/.BASE'
  if [ -f "$BASECHECK" ]; then
    echo -e "${GREEN}Base Exists Continuing Setup${NC}"
  else
    CLEANUPSETUP
    ##Install General Use Tools
    echo ""
    echo -e "${GREEN}Installing General Use tools.${NC}"
    echo -ne '>>>                       [20%]\r'
    #################################################################
    #Add your code here.
    #################################################################
    #Remove code below for personalization
    ##Install Firefox addons.
    cd $AWD
    firefox "https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/" & &>/dev/null
    firefox "https://addons.mozilla.org/en-US/firefox/addon/foxyproxy-standard/" &  &>/dev/null
    echo -ne '>>>>>>>>>>                [40%]\r'
    ##Install VSCode
    curl -OJL https://go.microsoft.com/fwlink/\?LinkID\=760868 > /dev/null 2>&1
    sudo dpkg -i code*.deb > /dev/null 2>&1
    echo -ne '>>>>>>>>>>>>>>            [60%]\r'
    code --install-extension ms-python.python > /dev/null 2>&1
    code --install-extension mechatroner.rainbow-csv > /dev/null 2>&1
    code --install-extension grapecity.gc-excelviewer > /dev/null 2>&1
    rm code*.deb > /dev/null 2>&1
    echo -ne '>>>>>>>>>>>>>>>>>>>>      [80%]\r'
    ##AppImage Launcher
    wget https://github.com/TheAssassin/AppImageLauncher/releases/download/v2.2.0/appimagelauncher_2.2.0-travis995.0f91801.bionic_amd64.deb > /dev/null 2>&1
    sudo dpkg -i ./appimagelauncher_2.2.0-travis995.0f91801.bionic_amd64.deb > /dev/null 2>&1
    echo -ne '>>>>>>>>>>>>>>>>>>>>>>>>>>[100%]\r'
    echo -ne '\n'
    echo -e "${GREEN}General Use Tools Installed.${NC}"
    #Install python Tools
    echo ""
    echo -e "${GREEN}Installing Python Tools.${NC}"
    echo -ne '>>>                       [20%]\r'
    pip3 install updog Cython python-libpcap > /dev/null 2>&1
    echo -ne '>>>>>>>>                  [40%]\r'
    cd $TWD
    echo -ne '>>>>>>>>>>>>>>            [60%]\r'
    git clone https://github.com/$GHUSER/Bloodhound.py.git > /dev/null 2>&1
    echo -ne '>>>>>>>>>>>>>>>>>>>>      [80%]\r'
    cd Bloodhound.py
    sudo python ./setup.py install > /dev/null 2>&1
    cd ../
    echo -ne '>>>>>>>>>>>>>>>>>>>>>>>>>>[100%]\r'
    echo -ne '\n'
    echo -e "${GREEN}Python Tools Installed.${NC}"
    #Install go
    echo -e ""
    echo -e "${GREEN}Installing GO Tools${NC}"
    echo -ne '>>>                       [20%]\r'
    sudo apt install gccgo-go -y > /dev/null 2>&1
    echo -ne '>>>>>>>>>>                [40%]\r'
    sudo apt install golang-go -y > /dev/null 2>&1
    echo -ne '>>>>>>>>>>>>>>            [60%]\r'
    #Install go-Lang updater
    git clone https://github.com/udhos/update-golang.git > /dev/null 2>&1
    cd update-golang/
    echo -ne '>>>>>>>>>>>>>>>>>>>>      [80%]\r'
    sudo ./update-golang.sh > /dev/null 2>&1
    cd ../
    echo -ne '>>>>>>>>>>>>>>>>>>>>>>>>>>[100%]\r'
    echo -ne '\n'
    echo -e "${GREEN}Go Tools Installed.${NC}"
    BASE_ALIAS
    touch $WD/.BASE
    echo -e ""
    echo -e "${GREEN}Basic setup complete${NC}"
  fi
  #################################################################
}
################################################################################
#Github Tools section
#Designed to install additional tools from github that dont come preinstalled on Kali.
#Default will install tools that i use on every engagement from my repo.
#I recommend you copy these to your own repo from the source if you want to use them incase i change my versions.
GITHUB_TOOLS(){
  GITCHECK=''$WD'/.GITHUB'
  if [ -f "$GITCHECK" ]; then
    echo ""
    echo -e "${GREEN}Github Tools Exists Continuing Setup${NC}"
  else
    ##Install Github Tools
    cd $TWD
    echo -e ""
    echo -e "${GREEN}Installing Github Tools.${NC}"
    echo -ne '>>>                       [20%]\r'
    #################################################################
    #Add your code here.
    echo -ne '>>>>>>>>>>                [40%]\r'
    #################################################################
    #Remove code below for personalization, DO NOT REMOVE the progress bars.
    git clone https://github.com/$GHUSER/Invoke-Obfuscation.git > /dev/null 2>&1
    git clone https://github.com/$GHUSER/Invoke-CradleCrafter.git > /dev/null 2>&1
    git clone https://github.com/$GHUSER/Linkedin2User.git > /dev/null 2>&1
    echo -ne '>>>>>>>>>>>>>>            [60%]\r'
    git clone https://github.com/$GHUSER/Gat.git > /dev/null 2>&1
    git clone https://github.com/$GHUSER/PEAS.git > /dev/null 2>&1
    git clone https://github.com/$GHUSER/Spray.git > /dev/null 2>&1
    echo -ne '>>>>>>>>>>>>>>>>>>>>      [80%]\r'
    sudo apt install rpcclient -y > /dev/null 2>&1
    git clone https://github.com/$GHUSER/NMapAutomater.git > /dev/null 2>&1
    git clone https://github.com/$GHUSER/SharpCollection.git > /dev/null 2>&1
    echo -ne '>>>>>>>>>>>>>>>>>>>>>>>>>>[100%]\r'
    echo -ne '\n'
    GIT_ALIAS
    touch $WD/.GITHUB
    echo -e "${GREEN}Github Tools Installed in $TWD${NC}"
  fi
  #################################################################
}
################################################################################
#Custom Tools Section
#Designed to run custom scripts from your VMWare shared folder to keep them local.
#Can be used to install further tools or make additional changes to the VM custom to you.
CUSTOM_TOOLS(){
  CUSTOMCHECK=''$WD'/.CUSTOM'
  if [ -f "$CUSTOMCHECK" ]; then
    echo ""
    echo -e "${GREEN}Custom Tools Exists Continuing Setup${NC}"
  else
    echo -e ""
    echo -e "${GREEN}Setup VMware shared folder (if enabled)${NC}"
    sudo mount-shared-folders
    #################################################################
    #Add your code here.
    #################################################################
    echo ""
    echo -e "${GREEN}Installing Custom Tools.${NC}"
    echo -ne '>>>                       [20%]\r'
    cd $TWD
    #Add custom scripts
    cp -R /mnt/hgfs/VMShare/KaliTools/*.zip ./
    sleep 1
    unzip Scripts.zip > /dev/null 2>&1
    rm -rf ./Scripts.zip
    chmod -R +x Scripts/*/*.sh
    echo -ne '>>>>>>>>>>                [40%]\r'
    #CobaltStrike Install from Shared Folder
    cd $TWD
    unzip CobaltStrikeInstaller.zip > /dev/null 2>&1
    rm -rf CobaltStrikeInstaller.zip > /dev/null 2>&1
    cd CobaltStrikeInstaller/
    chmod +x ./install.sh
    sudo apt install -y openjdk-11-jdk > /dev/null 2>&1
    echo -ne '>>>>>>>>>>>>>>            [60%]\r'
    #./install.sh > /dev/null 2>&1
    cd $TWD
    mv CobaltStrikeInstaller/cobaltstrike $TWD/
    rm -rf CobaltStrikeInstaller
    #Nextcloud Client
    cd $AWD
    wget https://download.nextcloud.com/desktop/releases/Linux/Nextcloud-3.4.2-x86_64.AppImage > /dev/null 2>&1
    chmod +x Nextcloud-3.4.2-x86_64.AppImage
    echo -ne '>>>>>>>>>>>>>>>>>>>>      [80%]\r'
    #Change Configs for truely custom setup.
    cd $TWD
    unzip Configs.zip > /dev/null 2>&1
    cd $TWD/Configs
    cp Test.txt $HOME/Desktop/ > /dev/null 2>&1
    rm -rf $TWD/Configs.zip
    cd $TWD
    rm -rf Configs
    echo -ne '>>>>>>>>>>>>>>>>>>>>>>>>>>[100%]\r'
    echo -ne '\n'
    CUSTOM_ALIAS
    touch $WD/.CUSTOM
    echo -e "${GREEN}Custom Tools Installed${NC}"
  fi
  #################################################################
}
################################################################################
#RF Section
#Will install Kali metapackages for 802.11, Bluetooth, RFID, and SDR.
#It will also setup some github tools specific to RF.
RF_TOOLS(){
  RFCHECK=''$WD'/.RF'
  if [ -f "$RFCHECK" ]; then
    echo ""
    echo -e "${GREEN}RF Tools Exists Continuing Setup${NC}"
  else
    cd $TWD
    echo ""
    echo -e "${GREEN}Installing RF Tools.(WiFi + Bluetooth + RFID/NFC + SDR)${NC}"
    mkdir $TWD/RF > /dev/null 2>&1
    echo -ne '>>>                       [20%]\r'
    sudo apt install kali-tools-802-11 > /dev/null 2>&1
    #ADD 802.11 Tools Here.
    echo -ne '>>>>>>>>>>                [40%]\r'
    sudo apt install kali-tools-bluetooth > /dev/null 2>&1
    #ADD Bluetooth Tools Here.
    echo -ne '>>>>>>>>>>>>>>            [60%]\r'
    sudo apt install kali-tools-rfid > /dev/null 2>&1
    #ADD RFID Tools Here.
    echo -ne '>>>>>>>>>>>>>>>>>>>>      [80%]\r'
    sudo apt install kali-tools-sdr > /dev/null 2>&1
    #ADD SDR Tools Here.
    echo -ne '>>>>>>>>>>>>>>>>>>>>>>>>>>[100%]\r'
    echo -ne '\n'
    RF_ALIAS
    touch $WD/.RF
    echo -e "${GREEN}RF Tools NOT BUILTIN Installed in $TWD/RF/${NC}"
  fi
  #################################################################
}
################################################################################
#OPSEC section
BASIC_OPSEC(){
  OPSECCHECK=''$WD'/.OPSEC'
  if [ -f "$OPSECCHECK" ]; then
    echo -e "${GREEN}OPSEC Exists Continuing Setup${NC}"
  else
    echo ""
    echo -e "${GREEN}Very basic OPSEC changes. (You should do more.)${NC}"
    #################################################################
    #Add your code here.
    #################################################################
    #Remove code below for personalization

    #Generate SSH key.
    echo -e "${GREEN}Generating new SSH Key"
    echo -e "${GREEN}Backup of original $HOME/.ssh/id_rsa.bak $HOME/.ssh/id_rsa.pub.bak)${NC}"
    ssh-keygen -t rsa -N "" -f $HOME/.ssh/id_rsa > /dev/null 2>&1
    ##Change Default passwd
    echo -e ""
    echo -e "${GREEN}Change your password!!!${NC}"
    passwd
    #Changing permissions on things we just installed.
    sudo chown -R $USER:$USER $TWD/
    sudo chown -R $USER:$USER $AWD/
    ##Change hostname
    echo -e "Changing Hostname."
    sudo sed -i 's/kali/'$VARHOST'/g' /etc/hostname
    sudo sed -i 's/kali/'$VARHOST'/g' /etc/hosts
    touch $WD/.OPSEC
  fi
  #################################################################
}

ADV_OPSEC(){
touch $WD/.ADV_OPSEC
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
  GIT_ALIAS
  CUSTOM_ALIAS
  RF_ALIASES
  BASIC_OPSEC
  #################################################################
}
################################################################################
#Alias section
BASE_ALIAS(){
  #################################################################
  #Add Aliases
  echo ""
  echo -e "${GREEN}Base Aliases Added${NC}"
  #################################################################
}
GIT_ALIAS(){
  #################################################################
  #Add Aliases
  echo ""
  echo -e "${GREEN}GIT Aliases Added${NC}"
  #################################################################
}
CUSTOM_ALIAS(){
  #################################################################
  #Add Aliases
  echo ""
  echo -e "${GREEN}Custom Aliases Added${NC}"
  #################################################################
}
RF_ALIAS(){
  #################################################################
  #Add Aliases
  echo ""
  echo -e "${GREEN}RF Aliases Added${NC}"
  #################################################################
}
RUN_SOURCE(){
  #################################################################
  #If running bash like a weirdo, Switch the comment below.
    #source $HOME/.bashrc
    source /home/$USER/.zshrc
}
################################################################################
#Banner Section
BANNER(){
cat << 'EOF'
   ____  __  ___   _________  _________
  |    |/  /|   | /   _____/ /   _____/
  |      <  |   | \_____  \  \_____  \
  |    |  \ |   | /        \ /        \
  |____|__ \|___|/_______  //_______  /
        \/             \/         \/
        Kali Initialization & Setup Script
EOF
}
ENDBANNER_REBOOT(){
cat << 'EOF'
   ____  __  ___   _________  _________
  |    |/  /|   | /   _____/ /   _____/
  |      <  |   | \_____  \  \_____  \
  |    |  \ |   | /        \ /        \
  |____|__ \|___|/_______  //_______  /
        \/             \/         \/
        Kali Initialization & Setup Script

Setup Complete Happy Hunting!!!

This computer will reboot in 15 seconds to apply OPSEC changes.
(Control + C to Cancel)
EOF
sleep 15
sudo reboot
}
################################################################################
#Color Section
RED='\e[0:31m'
GREEN='\e[0:32m'
NC='\e[0m'
# Color Functions
COLORGREEN(){
	echo -e $GREEN$1$NC
}
COLORRED(){
	echo -e $RED$1$NC
}
################################################################################
#Menu Section
READ_FROM_PIPE(){
  read "$@" <&0;
}
MENU(){
    BANNER
    echo -ne "
    Please select an option below to continue
    $(COLORRED '1)') Base Setup
    $(COLORRED '2)') Github Tools (Basic Setup + Additional Tools from Github)
    $(COLORRED '3)') Custom Setup (Basic + Github Tools + Custom Folder)
    $(COLORRED '4)') RF Setup (Basic + RF Tools)
    $(COLORRED '5)') Add Basic OPSEC ("Requires Reboot")
    $(COLORRED '6)') Install all the things (Installs Custom Setup + RF Tools + OPSEC)
    $(COLORRED '7)') Hardening Options
    $(COLORRED '0)') Exit

    $(COLORRED 'Choose an option OR press enter for the Base setup:') "
    READ_FROM_PIPE a;
    case $a in
        1) BASE; MENU ;;
        2) BASE; GITHUB_TOOLS; MENU ;;
        3) BASE; GITHUB_TOOLS; CUSTOM_TOOLS; MENU ;;
        4) BASE; RF_TOOLS; MENU;;
        5) BASIC_OPSEC; ENDBANNER_REBOOT ;;
        6) ALL_THE_THINGS; ENDBANNER_REBOOT;;
        #7) ADV_OPSEC;MENU;;
        0) exit 0;;
        *) BASE; MENU;;
    esac
}
MENU
