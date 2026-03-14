# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.3+  | :white_check_mark: |
| < 0.1.3 | :x:                |

## Security Considerations

This Home Assistant add-on requires elevated privileges to manage USB devices, which has security implications:

### Required Privileges

- **Full Access**: The add-on needs full access to the host system to interact with USB devices
- **Kernel Modules**: Loads the `vhci-hcd` kernel module for USB/IP functionality
- **Host Network**: Uses the host's network stack for USB/IP protocol communication
- **Privileged Capabilities**: Requires `NET_ADMIN`, `SYS_ADMIN`, `SYS_RAWIO`, `SYS_TIME`, and `SYS_NICE`

### Security Best Practices

1. **Trusted Network Only**: Only use this add-on in a trusted network environment
2. **Restrict Configuration Access**: Limit who can modify the add-on configuration
3. **Regular Updates**: Keep the add-on updated with the latest security patches
4. **Monitor Logs**: Regularly review add-on logs for suspicious activity
5. **Validate Configuration**: Ensure IP addresses and bus IDs are correct before starting
6. **Enable AppArmor**: Consider enabling AppArmor if supported (currently disabled due to compatibility)

### Input Validation

Starting from version 0.1.3, the add-on includes:

- IP address format validation (IPv4 only)
- USB bus ID format validation (e.g., "1-1.1.3")
- Protection against command injection attacks
- Sanitized input in generated scripts

### Known Limitations

- AppArmor is currently disabled to ensure compatibility
- The add-on requires privileged access, which cannot be reduced without breaking functionality
- IPv6 addresses are not currently supported
- Hostname-based server addresses are not validated (only IPv4)

## Reporting a Vulnerability

If you discover a security vulnerability in this add-on:

1. **Do NOT** open a public issue
2. Email the maintainer directly at: crypted@me.com
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if available)

We aim to respond to security reports within 48 hours and will work with you to address the issue promptly.

### Disclosure Policy

- Security fixes will be released as soon as possible
- Credit will be given to the reporter (unless anonymity is requested)
- A security advisory will be published after the fix is released
- Users will be notified through GitHub releases and README updates

## Security Audit

A comprehensive security audit was performed on 2026-03-14. Key findings:

- ✅ **No backdoors or malware detected**
- ✅ **No hardcoded credentials**
- ✅ **No external code downloads**
- ✅ **Command injection vulnerability fixed** (v0.1.3+)
- ⚠️ **High privileges required** (inherent to functionality)

See [SECURITY_AUDIT.md](SECURITY_AUDIT.md) for the complete audit report.

## Security Changelog

### Version 0.1.3+
- ✅ Added input validation for IP addresses
- ✅ Added input validation for USB bus IDs
- ✅ Fixed command injection vulnerability (CVE pending)
- ✅ Improved variable quoting in shell scripts
- ✅ Added security-focused code comments
- ✅ Created comprehensive security documentation

### Version < 0.1.3
- ⚠️ Command injection vulnerability present (CRITICAL)
- ⚠️ No input validation

## Additional Resources

- [OWASP Command Injection](https://owasp.org/www-community/attacks/Command_Injection)
- [Linux Capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)
- [USB/IP Protocol](https://www.kernel.org/doc/html/latest/usb/usbip_protocol.html)
- [Home Assistant Add-on Security](https://developers.home-assistant.io/docs/add-ons/security)

## Contact

For security concerns, contact: crypted@me.com

For general issues, use [GitHub Issues](https://github.com/cryptedx/ha-usbip-client/issues)
