#/usr/local/bin/gateway_monitor.sh
#sudo chmod +x /usr/local/bin/gateway_monitor.sh
#sudo systemctl enable --now gateway-monitor.service

# --- Konfigurační proměnné ---
# Použijeme DVA nezávislé hosty pro test (Google DNS a Cloudflare DNS).
# Pokud selže první, ověří se druhý, než se vyhlásí výpadek.
CHECK_HOST_1="1.1.1.1"
CHECK_HOST_2="8.8.8.8"

PRIMARY_GW="192.168.17.1"       # IP adresa primární brány
BACKUP_GW="192.168.8.1"         # IP adresa záložní brány
PRIMARY_IF="enp3s0f0"
BACKUP_IF="enp3s0f1"

PING_COUNT=2                    # Počet pingů na jeden pokus
PING_TIMEOUT=1                  # Timeout v sekundách pro jeden ping
CHECK_INTERVAL=15               # Interval kontroly v sekundách

# --- Pomocné funkce ---

add_primary_gw() {
    ip route add default via "$PRIMARY_GW" dev "$PRIMARY_IF" metric 100 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "$(date): INFO: Primary gateway $PRIMARY_GW added via $PRIMARY_IF."
        return 0
    else
        echo "$(date): ERROR: Failed to add primary gateway $PRIMARY_GW!"
        return 1
    fi
}

add_backup_gw() {
    ip route add default via "$BACKUP_GW" dev "$BACKUP_IF" metric 200 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "$(date): INFO: Backup gateway $BACKUP_GW added via $BACKUP_IF."
        return 0
    else
        echo "$(date): ERROR: Failed to add backup gateway $BACKUP_GW!"
        return 1
    fi
}

delete_all_default_routes() {
    if ip route show default &> /dev/null; then
        ip route del default
        echo "$(date): INFO: All previous default routes deleted."
    fi
}

test_link_ping() {
    local target_ip="$1"
    local if_name="$2"
    
    local local_ip
    local_ip=$(ip -4 addr show dev "$if_name" 2>/dev/null | grep -oP 'inet \K[\d.]+')

    if [ -z "$local_ip" ]; then
        return 1
    fi

    ping -I "$local_ip" -c "$PING_COUNT" -W "$PING_TIMEOUT" "$target_ip" &> /dev/null
    return $?
}

# --- Hlavní smyčka skriptu ---

echo "$(date): SCRIPT INITIAL START: Gateway Monitor with Fallback Protection started."

while true; do
    CURRENT_GW_INFO=$(ip route show default 2>/dev/null)

    # 1. Testujeme primární linku přes DVA různé cílce
    PRIMARY_ONLINE=0
    if test_link_ping "$CHECK_HOST_1" "$PRIMARY_IF" || test_link_ping "$CHECK_HOST_2" "$PRIMARY_IF"; then
        PRIMARY_ONLINE=1
    fi

    # 2. Reakce podle stavu
    if [ "$PRIMARY_ONLINE" -eq 1 ]; then
        # Primární linka Funguje
        if ! echo "$CURRENT_GW_INFO" | grep -q "$PRIMARY_GW"; then
            echo "$(date): ACTION: Primary link is UP. Restoring primary gateway $PRIMARY_GW..."
            delete_all_default_routes
            add_primary_gw
        fi
    else
        # Primární linka je DOWN
        echo "$(date): WARNING: Primary link ($PRIMARY_IF) ping failed on both check targets."

        if ! echo "$CURRENT_GW_INFO" | grep -q "$BACKUP_GW"; then
            echo "$(date): ACTION: Attempting switch to backup gateway $BACKUP_GW..."
            delete_all_default_routes
            
            # ZKUŠEBNOST: Zkusíme nahodit záložní bránu
            if ! add_backup_gw; then
                # FALLBACK POJISTKA: Záložní brána selhala! Vracíme zpět primární bránu,
                # abychom nenechali server zcela BEZ BRÁNY!
                echo "$(date): CRITICAL: Backup gateway could not be added! Activating FALLBACK back to primary gateway $PRIMARY_GW..."
                delete_all_default_routes
                add_primary_gw
            fi
        fi
    fi

    sleep "$CHECK_INTERVAL"
done
