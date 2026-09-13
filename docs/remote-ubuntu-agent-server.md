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
moshi-hook service install
```

The `.nvmrc` shell hook may be added to shell startup so entering a project
directory automatically selects its declared Node version. Agent
authentication remains interactive and user-specific:

```bash
gh auth login
codex --login
claude
opencode auth login
```

Do not copy tokens between users or store them in dotfiles.

## Moshi host setup

Easy Pair запускается на самом сервере под нужной учёткой:

```bash
moshi-hook host setup
```

Команда проверяет SSH, `mosh-server` и multiplexer, затем предлагает выбрать
тип адреса. Выбери `IP`, введи публичный IP сервера и дождись временного
QR-кода. Отсканируй его в приложении Moshi.

Пример интерактивного шага:

```text
Address type: IP
Server IP:    <PUBLIC_SERVER_IP>
```

Hostname можно выбрать вместо IP, если у сервера есть доступное DNS-имя.

Если подключение добавляется вручную в Moshi, поля выглядят так:

```text
Name:            user-a
Host:            server.example.com  # или публичный IP сервера
Port:            22
Username:        user-a
Authentication: SSH key
Connection type: Auto
```

Для второй учётки создаётся отдельное подключение с тем же `Host` и `Port`, но
с другим `Name` и `Username`:

```text
Name:            user-b
Host:            server.example.com
Port:            22
Username:        user-b
Authentication: SSH key
Connection type: Auto
```

`Host` и SSH `Port` не являются gateway-портом `moshi-hook`. Gateway остаётся
локальным и проксируется через SSH.

## Two users on one host

Use separate SSH destinations even when both accounts use the same public key:

```text
user-a@server.example.com
user-b@server.example.com
```

Their home directories, NVM installations, agent configs, Herdr sessions,
Moshi hooks, Unix sockets, and systemd user services remain separate.

Moshi normally uses gateway `127.0.0.1:24543`. When two user daemons run on one
host, give the second daemon another loopback port with a systemd drop-in:

```ini
# ~/.config/systemd/user/moshi-hook.service.d/override.conf
[Service]
ExecStart=
ExecStart=%h/.local/bin/moshi-hook serve --gateway-listen 127.0.0.1:24544
```

Apply it as the second user:

```bash
systemctl --user daemon-reload
systemctl --user enable --now moshi-hook.service
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
