# System-wide Jupyter config (/etc/jupyter), independent of the user's $HOME.
c = get_config()  # noqa: F821

c.ServerApp.ip = "0.0.0.0"
c.ServerApp.open_browser = False
c.ServerApp.allow_root = True

# No login: the port is only published on 127.0.0.1 (see docker-compose.yml).
c.IdentityProvider.token = ""

# VS Code's Jupyter extension doesn't send XSRF tokens.
c.ServerApp.disable_check_xsrf = True

# Without a token, these two settings are what stop websites open in the
# student's browser from running code in this container:
# - no `allow_origin = "*"`: cross-origin requests are rejected
# - only accept Host: localhost / loopback IPs, which blocks DNS rebinding
#   (evil.example resolving to 127.0.0.1)
c.ServerApp.allow_origin = ""
c.ServerApp.allow_remote_access = False
c.ServerApp.local_hostnames = ["localhost"]
