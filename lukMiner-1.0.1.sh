#!/bin/bash
# =======================================================
# Dual-miner launch script for lukMiner (Phi cards) + xmrig (host CPU)
# lukMiner  → Xeon Phi x100 cards  → ZEPH (CryptoNight Haven)
# xmrig     → Host CPU cores        → XMR  (RandomX)
# Requires: sudo privilege for huge-page setup
# =======================================================

# --------------------------
# lukMiner configuration for mining to MiningOcean (Phi cards — ZEPH)
# --------------------------
LUK_URL="pool.zephyr.miningocean.org"
LUK_PORT=1123
LUK_USER="your_ZEPH_wallet_address"
LUK_PASS="your_worker_name"
LUK_WATCHDOG=300
LUK_THREADS=-1
# Use luk-xmr-phi for x100 Knights Corner PCIe cards such as 5110p and 7120p
LUK_MINER="./luk-xmr-phi"

# --------------------------
# xmrig configuration for mining to CudoPool (Host CPU — XMR)
# --------------------------
XMR_URL="stratum+tcp://stratum.cudopool.com"
XMR_PORT=30010
XMR_USER="your_XMR_wallet_address"
XMR_PASS="your_worker_name"
# Limit xmrig to physical host CPU cores only — leave headroom for MPSS stack
# On a dual E5-2600 v3/v4 system, 20-24 threads is a safe ceiling
XMR_THREADS=20
XMRIG_MINER="./xmrig"

# =======================================================
# End configuration — script body below
# =======================================================

# Root check
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo). Huge-page setup requires elevated privileges."
    exit 1
fi

LOGFILE="/var/log/dual-miner.log"
touch "$LOGFILE"
chmod 640 "$LOGFILE"

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

# --------------------------
# Huge page allocation
# lukMiner needs ~10000 pages for Phi cards
# xmrig RandomX needs ~2336 pages for dual-NUMA host (2x E5-2600)
# Total: 13000 pages with headroom
# --------------------------
log "Allocating huge pages for both miners..."
if ! echo 13000 > /proc/sys/vm/nr_hugepages; then
    log "WARNING: Failed to set huge pages. Both miners will run slower than optimal."
else
    log "Huge pages set to 13000 (10000 lukMiner + 3000 xmrig RandomX buffer)."
fi

# Also enable 1GB huge pages for xmrig RandomX — gives 1-3% hashrate boost
if ! echo 4 > /proc/sys/vm/nr_hugepages_1g 2>/dev/null; then
    log "INFO: 1GB huge pages unavailable on this kernel — skipping."
fi

# --------------------------
# Watchdog loop for lukMiner (Phi cards — background)
# --------------------------
start_luk_miner() {
    log "Starting lukMiner on Phi cards for ZEPH mining..."
    while true; do
        log "--- lukMiner (re)starting ---"
        $LUK_MINER \
            --url "$LUK_URL" \
            --port "$LUK_PORT" \
            --user "$LUK_USER" \
            --pass "$LUK_PASS" \
            -wd "$LUK_WATCHDOG" \
            -t "$LUK_THREADS"
        EXIT_CODE=$?
        log "lukMiner exited with code $EXIT_CODE. Restarting in 5 seconds..."
        sleep 5
    done
}

# --------------------------
# Watchdog loop for xmrig (Host CPU — background)
# --------------------------
start_xmrig() {
    log "Starting xmrig on host CPU for XMR mining (RandomX)..."
    while true; do
        log "--- xmrig (re)starting ---"
        $XMRIG_MINER \
            --url "stratum+tcp://${XMR_URL}:${XMR_PORT}" \
            --user "$XMR_USER" \
            --pass "$XMR_PASS" \
            --threads "$XMR_THREADS" \
            --huge-pages \
            --randomx-numa-nodes 2 \
            --log-file "$LOGFILE" \
            --no-color
        EXIT_CODE=$?
        log "xmrig exited with code $EXIT_CODE. Restarting in 5 seconds..."
        sleep 5
    done
}

# --------------------------
# Trap to cleanly kill both miners on script exit (Ctrl+C or kill)
# --------------------------
cleanup() {
    log "Shutdown signal received. Stopping both miners..."
    kill "$LUK_PID" "$XMR_PID" 2>/dev/null
    wait "$LUK_PID" "$XMR_PID" 2>/dev/null
    log "Both miners stopped. Exiting."
    exit 0
}
trap cleanup SIGINT SIGTERM

# --------------------------
# Launch both miners as background jobs, capture PIDs
# --------------------------
start_luk_miner &
LUK_PID=$!
log "lukMiner started — PID $LUK_PID"

start_xmrig &
XMR_PID=$!
log "xmrig started — PID $XMR_PID"

log "Both miners running. lukMiner PID=$LUK_PID | xmrig PID=$XMR_PID"
log "Press Ctrl+C or send SIGTERM to stop cleanly."

# Hold the script open — wait for both background jobs
wait "$LUK_PID" "$XMR_PID"