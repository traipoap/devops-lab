#!/bin/bash

# Server Statistics Script
# This script provides basic server performance statistics
# Including CPU, memory, disk usage, and top processes

# Color definitions for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Error handling
set -e
trap 'echo "Error occurred on line $LINENO. Exit code: $?"' ERR

# Function to print section headers
print_header() {
    echo -e "\n${YELLOW}=== $1 ===${NC}"
}

# Function to get OS information
get_os_info() {
    print_header "SYSTEM INFORMATION"
    echo "OS Version: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
}

# Function to get CPU usage
get_cpu_usage() {
    print_header "CPU USAGE"
    top -bn1 | grep "Cpu(s)" | awk '{print "User: " $2 "%\nSystem: " $4 "%\nIdle: " $8 "%"}'
}

# Function to get memory usage
get_memory_usage() {
    print_header "MEMORY USAGE"
    free -h | awk 'NR==2{printf "Total: %s\nUsed: %s\nFree: %s\nPercentage Used: %.2f%%\n", $2, $3, $4, $3/$2*100}'
}

# Function to get disk usage
get_disk_usage() {
    print_header "DISK USAGE"
    df -h / | awk 'NR==2{printf "Total: %s\nUsed: %s\nFree: %s\nPercentage Used: %s\n", $2, $3, $4, $5}'
}

# Function to get top processes by CPU
get_top_cpu_processes() {
    print_header "TOP 5 PROCESSES BY CPU USAGE"
    ps aux --sort=-%cpu | head -6 | awk 'NR>1{printf "%s\t%s%%\t%s\n", $11, $3, $2}'
}

# Function to get top processes by memory
get_top_memory_processes() {
    print_header "TOP 5 PROCESSES BY MEMORY USAGE"
    ps aux --sort=-%mem | head -6 | awk 'NR>1{printf "%s\t%s%%\t%s\n", $11, $4, $2}'
}

# Function to get security information
get_security_info() {
    print_header "SECURITY INFORMATION"
    echo "Currently Logged In Users:"
    who
    echo -e "\nRecent Failed Login Attempts:"
    last -f /var/log/btmp | head -n 5 2>/dev/null || echo "No failed login attempts or access denied"
}

# Main execution
echo -e "${GREEN}Server Statistics Report - $(date)${NC}"
echo -e "${GREEN}=======================================${NC}"

get_os_info
get_cpu_usage
get_memory_usage
get_disk_usage
get_top_cpu_processes
get_top_memory_processes
get_security_info

echo -e "\n${GREEN}Report Complete${NC}"
