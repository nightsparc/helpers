#!/bin/bash

# @brief Script to automatically add a DEB repository to /etc/apt/sources.list.d
# @author nightsparc

# @function Show the usage of the script
showUsage() {
    echo ""
    echo -e "Usage: $0 [REPOSITORY] [COMPONENT] [ID] (KEYSERVER) (KEY)"
    echo ""
	echo -e "Add a debian repository to /etc/apt/sources.list.d."
    echo ""
    echo "PARAMETERS"
    echo -e "  REPOSITORY: the repository to add the package sources."
    echo -e "  COMPONENT: the repository component to which the repo should be added, e.g. main, restricted, universe, multiverse"
    echo -e "  ID: A unique ID to identify the created sources list file."
    echo ""
    echo "OPTIONS"
    echo -e "  KEYSERVER: the keyserver to check the given key"
    echo -e "  KEY: the PGP key to check"
    echo "" 
    echo "EXAMPLES"
    echo "Adding QGIS (latest release):"
    echo -e "  $0 http://qgis.org/ubuntugis qgis keyserver.ubuntu.com CAEB3DC3BDF7FB45"
	echo -e "  $0 http://qgis.org/ubuntugis-ltr keyserver.ubuntu.com CAEB3DC3BDF7FB45"
}

# @function Echo to stderr
echoerr() { 
    echo -e "\e[31mERROR: $@ \e[0m" 1>&2; 
}

#############################################################################
#### START of script execution

# If not enough parameters are given, show help too
if [ "$#" -lt "3" ]; then
    echoerr "Not enough arguments given..."
	showUsage
	exit 1
fi

# create a bunch of internal variables
export debianRepository=$1
export repositoryComponent=$2
id=$3
keyserver=$4
key=$5
distributor=$(lsb_release -si)
distroLower=${distributor,,}
export codename=$(lsb_release -sc)
export distroVersion=$(lsb_release -sr)
export aptListFilename=$id-$distroLower-$codename.list

# \e[32m - use green color
# \e[0m - back to default text color
echo -e "\e[32m Adding repository $debianRepository to $repositoryComponent for Ubuntu $distroVersion (codename: $codename)\e[0m"

# execute echo using sudo
# note: used variables must be exported
# see: https://stackoverflow.com/a/37004408
#
# -E    --> preserve environment
# sh -c --> use comand from commandstring instead of stdin
# > --> replace file contents
# >> --> append contents to file
sudo -E sh -c 'echo "deb $debianRepository $codename $repositoryComponent" > /etc/apt/sources.list.d/$aptListFilename'
sudo -E sh -c 'echo "deb-src $debianRepository $codename $repositoryComponent" >> /etc/apt/sources.list.d/$aptListFilename'

echo -e "\e[32m Repository $debianRepository added to $repositoryComponent repositories (file: $aptListFilename).\e[0m"

# Add GPG key if available
if [ -n "$keyserver" ] && [ -n "$key" ] 
then
	# \e[32m - use green color
	# \e[0m - back to default text color
	echo -e "\e[32m Adding key $key for $debianRepository (keyserver: $keyserver)\e[0m"
	apt-key adv --keyserver $keyserver --recv-key $key
else
	echo -e "\e[33m No valid combination of key and keyserver to add for $debianRepository! Key must be added manually!\e[0m"
fi
