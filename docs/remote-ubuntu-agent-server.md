# Remote Ubuntu agent server

The remote setup uses a supported Ubuntu `x86_64` host with two independent
non-root users. Keep provider-specific `installimage` values, addresses,
hostnames, passwords, tokens, and SSH key material outside this repository.

## System layer

Install as `root` or through `sudo`:

- Docker Engine, Compose, and Docker Sandboxes;
- GitHub CLI (`gh`);
- `mosh-server`;
- KVM support for Docker Sandboxes (`/dev/kvm` and the `kvm` group);
- common build and development packages.

Each development user belongs to `docker` and `kvm`, has `loginctl enable-linger`
enabled, and receives a separate user systemd environment. Do not put agent
credentials or user-specific tools in `/usr/local/bin`.

## Per-user layer

Repeat the following for every development account. Replace `user-a` and
`user-b` with local names only in private deployment notes:

```bash
# run as the target user
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.7/install.sh | bash

# load NVM, then install the current Node.js 26 line
export NVM_DIR="$HOME/.nvm"
. "$NVM_DIR/nvm.sh"
nvm install 26
nvm alias default 26

# user-local agent CLIs
curl -fsSL https://chatgpt.com/codex/install.sh | sh
curl -fsSL https://claude.ai/install.sh | bash
curl -fsSL https://opencode.ai/install | bash
curl -fsSL https://x.ai/cli/install.sh | bash
curl -fsSL https://herdr.dev/install.sh | sh

# user-local Moshi hook and agent integrations
MOSHI_HOOK_SKIP_FIRST_RUN=1 sh -c 'curl -fsSL https://getmoshi.app/install.sh | sh'
moshi-hook install
```

The `.nvmrc` file declares the Node.js version for `nvm use` or `nvm install`.
Automatic selection when entering a directory requires the shell hook; without
that hook, run `nvm use` or `nvm install` explicitly. Agent authentication
remains interactive and user-specific:

```bash
gh auth login
codex --login
claude
opencode auth login
```

Do not copy tokens between users or store them in dotfiles.

## Moshi host setup

Run Easy Pair on the server as the user that will own the connection:

```bash
moshi-hook host setup
```

The command checks SSH, `mosh-server`, and the multiplexer, then asks for the
address type. Select `IP`, enter the server's public IP, and wait for the
temporary QR code. Scan it in the Moshi app.

Example interactive step:

```text
Address type: IP
Server IP:    <PUBLIC_SERVER_IP>
```

Choose `Hostname` instead when the server has a reachable DNS name.

For a manual Moshi connection, use fields like these:

```text
Name:            user-a
Host:            server.example.com  # или публичный IP сервера
Port:            22
Username:        user-a
Authentication: SSH key
Connection type: Auto
```

Create a second connection with the same `Host` and `Port`, but a different
`Name` and `Username`:

```text
Name:            user-b
Host:            server.example.com
Port:            22
Username:        user-b
Authentication: SSH key
Connection type: Auto
```

`Host` and SSH `Port` are not the `moshi-hook` gateway port. The gateway stays
local and is proxied through SSH.

## Two users on one host

Use separate SSH destinations even when both accounts use the same public key:

```text
user-a@server.example.com
user-b@server.example.com
```

Their home directories, NVM installations, agent configs, Herdr sessions,
Moshi hooks, Unix sockets, and systemd user services remain separate.

Install the standard service for the first user:

```bash
moshi-hook service install
```

Moshi normally uses gateway `127.0.0.1:24543`. Before starting the second
user's service, give it another loopback port with a systemd drop-in:

```ini
# ~/.config/systemd/user/moshi-hook.service.d/override.conf
[Service]
ExecStart=
ExecStart=%h/.local/bin/moshi-hook serve --gateway-listen 127.0.0.1:24544
```

Apply the drop-in as the second user, before the first service start:

```bash
systemctl --user daemon-reload
moshi-hook service install
```

Pair each user separately from the Moshi app:

```bash
moshi-hook pair --token <token-for-this-user>
moshi-hook install
```

The Moshi client must support a custom gateway port for the second connection;
otherwise keep only one hook daemon on the default port or use separate hosts.
The gateway remains loopback-only.

## Mosh

Install the server package on Ubuntu and the client on the local Mac:

```bash
# server
sudo apt install mosh

# local macOS client
brew install mosh
```

Allow UDP `60000:61000` in the provider firewall when Mosh is used. SSH remains
the fallback transport.

## Verification

Run as each user:

```bash
id
node --version
docker ps
gh --version
moshi-hook status
systemctl --user status moshi-hook.service --no-pager
```

## Local Herdr shortcuts

Hide server addresses and usernames behind SSH aliases in the local
`~/.ssh/config`:

```sshconfig
Host agents-user-a
    HostName server.example.com
    User user-a
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

Host agents-user-b
    HostName server.example.com
    User user-b
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

Then add a short zsh function with completion to `~/.zshrc`:

```zsh
h() {
  case "$1" in
    user-a) herdr --remote agents-user-a --remote-keybindings server ;;
    user-b) herdr --remote agents-user-b --remote-keybindings server ;;
    *) echo "usage: h user-a|user-b" >&2; return 2 ;;
  esac
}

_h() {
  _describe 'account' '( user-a user-b )'
}

compdef _h h
```

Reload the shell and connect with:

```bash
source ~/.zshrc
h user-a
h user-b
```

An old host can be retained as a separate SSH alias, for example
`old-user-a`, without changing the shortcuts for the current server.
