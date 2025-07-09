## cs-caddy
### caddy docker image with crowdsec
Based on [caddy-crowdsec-bouncer](https://github.com/hslatman/caddy-crowdsec-bouncer)

Download caddy.Dockerfile and run:

`docker build -t yourusername/custom-caddy:latest -f caddy.Dockerfile .`

or pull the image - auto-updates from new [caddy releses](https://github.com/caddyserver/caddy/releases) and also on new update to [caddy-crowdsec-bouncer](https://github.com/hslatman/caddy-crowdsec-bouncer)

`docker pull ghcr.io/buildplan/cs-caddy:latest`

When Caddy is built with this module enabled, a new `caddy crowdsec` command will be enabled. Its subcommands allow you to interact with your CrowdSec integration at runtime using [Caddy's Admin API](https://caddyserver.com/docs/api). This is useful to verify the status of your integration, and check if it's configured and working properly. The command requires the Admin API to be reachable from the system it is run from.

```
$ caddy crowdsec

Commands related to the CrowdSec integration (experimental)

Usage:
  caddy crowdsec [command]

Available Commands:
  check       Checks an IP to be banned or not
  health      Checks CrowdSec integration health
  info        Shows CrowdSec runtime information
  ping        Pings the CrowdSec LAPI endpoint

Flags:
  -a, --adapter string   Name of config adapter to apply (when --config is used)
      --address string   The address to use to reach the admin API endpoint, if not the default
  -c, --config string    Configuration file to use to parse the admin address, if --address is not used
  -h, --help             help for crowdsec
  -v, --version          version for crowdsec

Use "caddy crowdsec [command] --help" for more information about a command.

Full documentation is available at:
https://caddyserver.com/docs/command-line
```
