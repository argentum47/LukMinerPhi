# execute this script with sudo ("sudo ./mine.sh")
# this will automatically enable large-page support within the OS
!/bin/bash

# usage: make sure to configure the URL, PORT, and USER values for your miner

# configure your pool URL
URL=pool.supportxmr.com

# configure your pool listening port
PORT=3333

# configure your user name at this pool
USER=username

# configure your account password at this pool, if required. Note most pools will actually
# interpret that as a worker name, so do NOT put your real password here!
PASS=password

# if you want to force a given number of threads, use this value '-1'
# which means 'all that make sense' given this CPU, cache size, etc.
MAX_THREADS=-1

# watchdog value, in seconds. If no share gets found within this many
# seconds, the miner assumes a non-replying pool, and exits, thus
# allowing an automatic, clean restart. Set to '0' to disable watchdog.
WATCHDOG=300

# executable to run
# set to 'luk-xmr-phi' if this is a x200-series Xeon Phi
# set to 'luk-xmr-ocl' if this is a for one or more OpenCL-capable GPUs
# (note that even in GPU mode it will still use the CPU cores, too)
MINER=./luk-xmr-cpu

# =======================================================
# end configuration section - now the actual script
# =======================================================

# enable huge-page support for the OS. This requires sudo priviledges.
# If you called this script without 'sudo', this will emit an error.
# script will still work - just a bit slower than if you had used sudo.
echo 10000 > /proc/sys/vm/nr_hugepages

# call the miner, in an infinite loop
# if the miner locks up, for any reason, it will automatically restart.
while [ true ] ; do
    echo "----------- re-starting miner -----------"
    $MINER --url $URL --port $PORT --user $USER --pass $PASS -wd $WATCHDOG -t $MAX_THREADS
    sleep 1
done

# I'm not the original author. Credit goes out to whomever originally wrote this.
