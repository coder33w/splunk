#!/bin/bash

###################################################################################
#
# # setSplunkEnv.sh
#
# Latest Update:  30 August 2021
#
#
# Script to set common EL7 OS parameters for common Splunk environment best
#     practices.
# - Disable Transparent Huge Pages (THP)
# - Number of Processes Allowed for splunk user:  16000
# - Number of Open File Descriptors Allowed for splunk user:  64000
#
###################################################################################
#
# Execution is as follows:
#  1) Checks that script is executed with superuser privileges:
#     a) Issues warning and exits if not
#  2) Disable the tuned service:
#     NOTE) This service usually affects both settings (THP and ulimits)
#     a) Immediately stops service
#     b) Service will not restart at boot
#  3) Disable Transparent Huge Pages (THP):
#     a) Checks whether THP already disabled
#     b) Adds kernel parameter if not
#  4) Set ulimits for splunk user:
#     a) Number of Processes:  16000
#     b) Number of Open File Descriptors:  64000
#     c) Checks if ulimit command exists in "splunk" init.d script
#     d) Adds ulimit command if not
#     e) Executes prlimit command to enact limits immediately
#
#  ** MUST BE RUN AS ROOT!! **
#
###################################################################################



### MAIN EXECUTION ###

# Check if script is being executed as superuser
if [[ $(id -u) -ne 0 ]]
then
    echo -e "\n\n\t\t***** THIS SCRIPT MUST BE RUN USING SUPERUSER PRIVILEGES! *****\n\t\t  *** Please re-run using 'sudo' or as root. ***  \n\n"
    exit
fi


# Stop and disable "tuned" service
echo -e "\n\tStopping and Disabling the tuned service . . .\n"
systemctl -q stop tuned
systemctl -q disable tuned


# Check if THP is already set to "never" via kernel option
echo -e "\n\tChecking for THP status . . .\n"
if $(grep -qv "\[never\]" /sys/kernel/mm/transparent_hugepage/enabled)
then
    # If it is not, set it through grubby
    echo -e "\n\tAdding THP-disabling kernel parameter . . .\n\n"
    grubby --update-kernel=ALL --args="transparent_hugepage=never"
fi


# Create security limits file to allow the "splunk" user to exceed standard setting
echo -e "\n\tAdding ulimit exceptions for splunk user . . .\n"
echo -e "splunk\tsoft\tnproc\t16000\nsplunk\thard\tnproc\t16000\nsplunk\tsoft\tnofile\t64000\nsplunk\thard\tnofile\t64000\n" > /etc/security/limits.d/99-splunklimits.conf
# Change permissions of new file to be commensurate with the rest
chmod 644 /etc/security/limits.d/99-splunklimits.conf

# Add a ulimit adjustment to the Splunk startup script in /etc/init.d if not there already
# - This change allows the ulimit to take effect at startup of splunkd process
echo -e "\n\tChecking for ulimit command in splunk init script . . .\n"
if  $(grep -qv "ulimit" /etc/init.d/splunk)
then
    echo -e "\n\tAdding ulimit line in splunk init script . . .\n"
    # Backs up existing splunk init script to /etc/init.d/splunk.bak, too
    sed 's/echo Starting Splunk.../echo Starting Splunk...\n  ulimit -Hn 64000/' /etc/init.d/splunk -i.bak
fi

# Immediately enact limits changes
echo -e "\n\tExecuting prlimit to enact new ulimits . . .\n"
prlimit


echo -e "\n\n\t\t*** CHANGES ARE PERSISTENT, BUT YOU MUST REBOOT FOR SOME CHANGES TO TAKE EFFECT!! ***\n\n"

### END OF MAIN EXECUTION ###
