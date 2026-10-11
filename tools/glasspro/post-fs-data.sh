#!/system/bin/sh
# Early, blocking stage: only resetprop here (never setprop: it can deadlock this stage).
# The memory-tuning properties are set before lmkd starts; service.sh sets them again and restarts lmkd,
# so a failure here costs nothing.
resetprop ro.lmk.kill_heaviest_task false
resetprop ro.lmk.psi_partial_stall_ms 300
resetprop ro.lmk.thrashing_limit 200
resetprop ro.lmk.swap_free_low_percentage 3
