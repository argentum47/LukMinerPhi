# Execute this script with sudo privilege to ensure proper operation.
# This will automatically enable large-page support within the O/S.

# Usage: make sure to configure the URL, PORT, and USER values for your miner.

# Configure your pool URL
URL="pool.supportxmr.com"

# Configure your pool listening port
PORT=3333

# Configure your user name at this pool
USER="username"

# Configure your account password at this pool, if required. Note most pools will actually
# interpret that as a worker name, so do NOT put your real password here!
PASS="password"

# If you want to force a given number of threads, use this value '-1'
# which means 'all that make sense' given this CPU, cache size, etc.
MAX_THREADS=-1

# Watchdog value, in seconds. If no share gets found within this many
# seconds, the miner assumes a non-replying pool, and exits, thus
# allowing an automatic, clean restart. Set to '0' to disable watchdog. 
# Set to '300' for 5 minute watchdog.
WATCHDOG=300

# Executable to run
# Set to 'luk-xmr-phi' if this is a x200-series Xeon Phi
# Set to 'luk-xmr-ocl' if this is a for one or more OpenCL-capable GPUs
# (note that even in GPU mode it will still use the CPU cores, too)
MINER="./luk-xmr-cpu"

# =======================================================
# End configuration section - now the actual script
# =======================================================

# Enable huge-page support for the O/S. This requires sudo privilege.
# If you called this script without 'sudo', this will emit an error.
# Script will still work - just a bit slower than if you had used sudo.
echo "Enabling huge-page support..."
if ! echo 10000 > /proc/sys/vm/nr_hugepages; then
    echo "Failed to enable huge-page support. Proceeding without huge pages."
fi

# Function to start the miner
start_miner() {
    while true; do
        echo "----------- Re-starting miner -----------"
        $MINER --url $URL --port $PORT --user $USER --pass $PASS -wd $WATCHDOG -t $MAX_THREADS
        sleep 1
    done
}

# Call the miner in an infinite loop
start_miner
