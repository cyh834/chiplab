#!/bin/bash

# Set the CHIPLAB_HOME variable to the current directory
CHIPLAB_HOME=$(pwd)

# Add the new path to the .bashrc file
echo "export PATH=${CHIPLAB_HOME}/toolchains/loongarch32r-linux-gnusf-v2.0/bin/:\$PATH" >> ~/.bashrc

# Source the .bashrc file to apply the changes
source ~/.bashrc
