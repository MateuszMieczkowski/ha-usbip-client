#!/command/with-contenv bashio
# shellcheck disable=SC1008
bashio::config.require 'log_level'
bashio::log.level "$(bashio::config 'log_level')"

declare server_address
declare bus_id
declare script_directory="/usr/local/bin"
declare mount_script="/usr/local/bin/mount_devices"
declare discovery_server_address

# Security: Function to validate IP address format
validate_ip_address() {
    local ip="$1"
    if [[ ! "${ip}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 1
    fi
    # Additional validation: each octet should be 0-255
    local IFS='.'
    local -a octets=($ip)
    for octet in "${octets[@]}"; do
        if ((octet > 255)); then
            return 1
        fi
    done
    return 0
}

# Security: Function to validate bus_id format (e.g., "1-1.1.3" or "1-1")
validate_bus_id() {
    local bus_id="$1"
    if [[ ! "${bus_id}" =~ ^[0-9]+-[0-9]+(\.[0-9]+)*$ ]]; then
        return 1
    fi
    return 0
}

discovery_server_address=$(bashio::config 'discovery_server_address')

# Security: Validate discovery_server_address
if ! validate_ip_address "${discovery_server_address}"; then
    bashio::exit.nok "Invalid discovery_server_address format: ${discovery_server_address}. Must be a valid IPv4 address."
fi

bashio::log.info ""
bashio::log.info "-----------------------------------------------------------------------"
bashio::log.info "-------------------- Starting USB/IP Client Add-on --------------------"
bashio::log.info "-----------------------------------------------------------------------"
bashio::log.info ""

# Check if the script directory exists and log details
bashio::log.debug "Checking if script directory ${script_directory} exists."
if ! bashio::fs.directory_exists "${script_directory}"; then
    bashio::log.info "Creating script directory at ${script_directory}."
    mkdir -p "${script_directory}" || bashio::exit.nok "Could not create bin folder"
else
    bashio::log.debug "Script directory ${script_directory} already exists."
fi

# Create or clean the mount script
bashio::log.debug "Checking if mount script ${mount_script} exists."
if bashio::fs.file_exists "${mount_script}"; then
    bashio::log.info "Mount script already exists. Removing old script."
    rm "${mount_script}"
fi
bashio::log.info "Creating new mount script at ${mount_script}."
touch "${mount_script}" || bashio::exit.nok "Could not create mount script"
chmod +x "${mount_script}"

# Write initial content to the mount script
echo '#!/command/with-contenv bashio' >"${mount_script}"
echo 'mount -o remount -t sysfs sysfs /sys' >>"${mount_script}"
bashio::log.debug "Mount script initialization complete."

# Discover available devices
bashio::log.info "Discovering devices from server ${discovery_server_address}."
if available_devices=$(usbip list -r "${discovery_server_address}" 2>/dev/null); then
    if [ -z "$available_devices" ]; then
        bashio::log.warning "No devices found on server ${discovery_server_address}."
    else
        bashio::log.info "Available devices from ${discovery_server_address}:"
        echo "$available_devices" | while read -r line; do
            bashio::log.info "$line"
        done
    fi
else
    bashio::log.error "Failed to retrieve device list from server ${discovery_server_address}."
fi

# Loop through configured devices
bashio::log.info "Iterating over configured devices."
for device in $(bashio::config 'devices|keys'); do
    server_address=$(bashio::config "devices[${device}].server_address")
    bus_id=$(bashio::config "devices[${device}].bus_id")

    # Security: Validate server_address format
    if ! validate_ip_address "${server_address}"; then
        bashio::log.error "Invalid server_address format for device ${device}: ${server_address}. Skipping this device."
        continue
    fi

    # Security: Validate bus_id format
    if ! validate_bus_id "${bus_id}"; then
        bashio::log.error "Invalid bus_id format for device ${device}: ${bus_id}. Skipping this device."
        continue
    fi

    bashio::log.info "Adding device from server ${server_address} on bus ${bus_id}"

    # Security: Properly quote variables to prevent command injection
    # Detach any existing attachments
    bashio::log.debug "Detaching device ${bus_id} from server ${server_address} if already attached."
    printf '/usr/sbin/usbip detach -r %q -b %q >/dev/null 2>&1 || true\n' "${server_address}" "${bus_id}" >>"${mount_script}"

    # Attach the device
    bashio::log.debug "Attaching device ${bus_id} from server ${server_address}."
    printf '/usr/sbin/usbip attach --remote=%q --busid=%q\n' "${server_address}" "${bus_id}" >>"${mount_script}"
done

bashio::log.info "Device configuration complete. Ready to attach devices."
