#!/bin/bash

###################################################################################
#
# # setSplunkEnv.sh
#
# Script to set common EL7 OS parameters for the Splunk environment best practices.
# - Disable Transparent Huge Pages (THP)
# - Number of Processes Allowed for splunk user:  16000
# - Number of Open File Descriptors Allowed for splunk user:  64000
#
###################################################################################
#
# Execution is as follows:
#  1) Disable the tuned service
#     a) This service usually affects both of the following settings.
#     b) Immediately stop service
#     c) Service will not restart at boot
#  2) Disable Transparent Huge Pages (THP)
#     a) Checks whether THP already disabled
#     b) Adds kernel parameter if not
#  3) Set ulimits for splunk user:
#     a) Number of Processes:  16000
#     b) Number of Open File Descriptors:  64000
#     c) New limits take effect at next boot
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
echo -e "\n\tStopping and Disabling the tuned service . . .\n\n\t"
systemctl stop tuned
systemctl disable tuned


# Check if THP is already set to "never" via kernel option
echo -e "\n\tChecking for THP status . . .\n"
if $(grep -qv "\[never\]" /sys/kernel/mm/transparent_hugepage/enabled)
then
    # If it is not, set it through grubby
    echo -e "\n\tAdding THP-disabling kernel parameter . . .\n\n"
    grubby --update-kernel=ALL --args="transparent_hugepage=never"
fi


# Create security limits file to allow the "splunk" user to exceed standard setting
echo -e "\n\tAdding ulmit exceptions for splunk user . . .\n"
echo -e "splunk\tsoft\tnproc\t16000\nsplunk\tsoft\tnofile\t64000" > /etc/security/limits.d/99-splunklimits.conf


echo -e "\n\n\t\t*** CHANGES ARE PERSISTENT, BUT YOU MUST REBOOT FOR CHANGES TO TAKE EFFECT!! ***\n\n"

### END OF MAIN EXECUTION ###
