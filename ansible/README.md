# Ubuntu development server bootstrap

This playbook reproduces the public, reusable part of the remote development
server: SSH hardening, UFW, unattended upgrades, Docker, Node.js, tmux, Mosh,
Neovim, lazygit, GitHub CLI, optional default and directory-scoped Git
identities and SSH keys, and the configs from this repository.

It deliberately does **not** store:

- server IPs or hostnames;
- private SSH keys;
- GitHub, Claude, Codex, or npm credentials;
- project repository names, IDs, paths, or environment variables.

Concrete Git profiles and account bindings stay in ignored controller-local
files. GitHub SSH key registration is optional and uses tokens already stored
by the controller's `gh` CLI; those tokens are never copied to the server.

## What it manages

- a non-root development user with passwordless sudo for automation;
- public-key-only SSH access, root-login denial, UFW, and unattended upgrades;
- Docker Engine and Compose with bounded local logs;
- pinned NVM, Node.js, Neovim, lazygit, tmux plugins, and npm tools;
- Mosh, GitHub CLI, common shell utilities, and development packages;
- the tmux, lazygit, tmuxinator, and Neovim configuration in this repository;
- optional account-aware Git identities and server-generated SSH keys;
- read-only post-deployment checks for security and toolchain state.

The playbooks support Ubuntu on `x86_64` and `aarch64`. They are intended for a
single-user development server rather than a shared production host.

## Deployment model

There are two entry points:

| Playbook | Initial connection | Purpose |
|---|---|---|
| `bootstrap.yml` | provider-created root or sudo user | Create the development user, install its public key, and harden access |
| `site.yml` | development user | Install and verify the complete development environment |

Run Ansible from a trusted controller such as a MacBook. The controller keeps
the inventory, account mapping, GitHub credentials, and the public login key.
The server generates its own GitHub private keys; private key material never
passes through the controller or this repository.

## Repository layout

```text
ansible/
├── .env.example                 # Non-secret environment variable schema
├── inventory.example.yml        # Generic target inventory
├── git-profiles.example.yml     # Generic Git identity/account schema
├── bootstrap.yml                # First-access and security playbook
├── site.yml                     # Development environment playbook
├── group_vars/all.yml           # Public defaults and pinned versions
├── roles/                       # Idempotent implementation and verification
└── run-playbook.sh              # Trusted local .env loader and entry point
```

Real controller values belong in ignored files:

```text
ansible/.env
ansible/inventory.yml
ansible/local/git-profiles.yml
```

## Requirements

Controller:

- OpenSSH and a verified connection to the target;
- `uv` for the isolated Python environment;
- `gh` only when GitHub SSH keys should be registered automatically.

Target:

- a supported Ubuntu image;
- initial root or passwordless-sudo access from the provider;
- outbound HTTPS access for APT repositories and pinned tool downloads.

## Controller setup

Run Ansible from the MacBook (or another trusted controller):

```bash
brew install uv gh
cd ansible
uv venv .venv
uv pip install --python .venv/bin/python -r requirements.txt
.venv/bin/ansible-galaxy collection install -r requirements.yml -p .collections
cp inventory.example.yml inventory.yml
cp .env.example .env
mkdir -p local
cp git-profiles.example.yml local/git-profiles.yml
chmod 600 .env inventory.yml local/git-profiles.yml
```

Edit the ignored `inventory.yml` with the real hostname, desired user, public
key path, and optional provider monitoring rules. Connect to the new host once
with SSH first so its host key is recorded and verified.

Edit the ignored `.env` and `local/git-profiles.yml` only when the default or
directory-scoped Git identities and SSH keys should be managed. The committed
role contains no account names, project paths, emails, server identifiers, or
tokens.

When automatic GitHub key registration is enabled, authenticate every required
account on the controller:

```bash
gh auth login --hostname github.com
gh auth status --hostname github.com
```

The values in `.env` are account names understood by
`gh auth token --user <account>`, not tokens. A fine-grained token needs the
`Git SSH keys: write` user permission; a classic token needs
`write:public_key`.

## First boot

On a fresh provider image where root SSH is initially available:

```bash
./run-playbook.sh bootstrap.yml -u root
```

The bootstrap creates the development user and installs its public key before
disabling root/password SSH. Keep the current root terminal open and verify the
new login in a second terminal before closing it:

```bash
ssh developer@server.example.com
sudo -n true
```

If the provider gives a non-root sudo user instead, run `bootstrap.yml` as that
user with `--become` access.

## Development environment

```bash
./run-playbook.sh site.yml -u developer
```

Run it a second time after the first successful install. Normal configuration
tasks should report no changes; verification commands always run read-only:

```bash
./run-playbook.sh site.yml -u developer
```

To preview configuration changes:

```bash
./run-playbook.sh site.yml -u developer --check --diff
```

Some first-run download/install tasks cannot produce a complete check-mode
preview, so validate on a disposable clean VM before updating pinned versions.

After the first installation, reconnect once so Docker group membership is
present in the new login session.

For a focused Git account and baseline verification:

```bash
./run-playbook.sh site.yml --tags git_profiles,verify
```

The expected result of a second unchanged run is `changed=0`. A non-zero change
count should be reviewed before treating the configuration as reproducible.

## Connecting and persistent work

SSH or Mosh transports the terminal; tmux owns the durable work session:

```bash
ssh developer@server.example.com
tmux new-session -A -s work
```

After a network interruption, reconnect and run the same tmux command. Agent
processes, tests, and editor panes continue on the server while the client is
disconnected. With Mosh installed locally, an alternative connection is:

```bash
mosh developer@server.example.com
tmux new-session -A -s work
```

Mosh requires UDP access to the configured `mosh_port_range`; SSH remains
available for environments that block UDP.

## Default and directory-scoped Git identities and SSH keys

`git-profiles.example.yml` documents the generic profile schema. The optional
default profile supplies the identity and SSH key used outside a more specific
directory. Each directory-scoped profile overrides it through Git `includeIf`.
Every SSH-enabled profile:

- owns a distinct server-generated Ed25519 keypair;
- gets a `git-profile-<id>` SSH alias for initial clones;
- may register its public key through the GitHub API.

The default profile applies outside a more specific directory. For example, a
repository created below a directory-scoped profile receives that profile's
identity and `core.sshCommand`; other repositories retain the default account.
Inspect the effective configuration with:

```bash
git config --show-origin --get-regexp '^(user\.|core\.sshCommand)'
ssh -T git-profile-profile_one
```

GitHub prints a successful authentication message and exits with status `1`
because it does not provide interactive shell access.

For API registration, `.env` binds the generic profile to an account already
authenticated by the controller's `gh` CLI. The playbook obtains the token
locally with `gh auth token`, verifies the token's login through `GET /user`,
lists current SSH keys, and creates the key only when its public material is
absent. A fine-grained token needs the `Git SSH keys: write` user permission;
a classic token needs `write:public_key`.

GitHub SSH keys do not have a native expiration time. The role reports keys
older than `git_ssh_rotation_reminder_days` but never rotates or deletes access
during a normal bootstrap. The stable GitHub title is:

```text
<GIT_SSH_KEY_TITLE_PREFIX>:<GIT_SSH_SERVER_ID>:<profile-id>
```

If the title already belongs to different key material, the playbook fails
instead of replacing it. Rebuilding a server therefore requires either
restoring its private keys or performing an explicit reviewed rotation.

GitHub does not allow one public SSH key to be attached to multiple accounts,
so profiles bound to different accounts must use different keypairs. This role
also enforces unique key material across profiles.

## Other authentication

Public GitHub repositories work over HTTPS without authentication:

```bash
git clone https://github.com/owner/repository.git
```

Private repositories and pushes can use the managed server-side SSH keys.
GitHub CLI API authentication and Claude/Codex authentication remain separate
concerns. Never copy a MacBook private key into this repository or into the
playbook.

Docker group membership is equivalent to root access. It is enabled here for a
single-user development server so tools can run Docker without sudo.

## Rebuilding and rotating GitHub keys

Use a stable, non-secret `GIT_SSH_SERVER_ID` for the lifetime of one server.
Use a different server ID for a replacement host so both servers can coexist
during migration.

GitHub SSH keys have no native expiration. The playbook reports a reminder
after `git_ssh_rotation_reminder_days` but does not automatically delete or
replace keys. If an existing title points to different key material, the run
fails deliberately. Review and remove the old GitHub key, then rerun the
playbook only after confirming another access path.

## Updating pinned versions

Tool and plugin versions live in `group_vars/all.yml`; Ansible collection
versions live in `requirements.yml`. Update them intentionally, update any
checksums in the same change, run the playbook on a disposable Ubuntu host,
then run it again and require `changed=0`.

Neovim starts from a pinned Kickstart revision, applies `nvim/kickstart.patch`,
copies the repository configuration, and restores `nvim/lazy-lock.json`.
Running an update-oriented Lazy command during provisioning would mutate the
lockfile and break idempotence, so the role uses the pinned lock state.

## Troubleshooting

- **Host key verification failed:** connect once with plain SSH and verify the
  provider fingerprint before rerunning Ansible.
- **GitHub registration returns 403:** reauthenticate the selected controller
  account and verify its `Git SSH keys: write` or `write:public_key` permission.
- **A GitHub key title already exists with different material:** perform an
  explicit key rotation; the playbook will not replace it automatically.
- **A repository uses the wrong account:** confirm it is below the exact
  trailing-slash directory in `local/git-profiles.yml`, then inspect
  `git config --show-origin --list`.
- **Node.js is missing in a non-interactive SSH command:** rerun `site.yml`; the
  role loads NVM before Ubuntu's non-interactive shell guard.
- **Docker permission denied after installation:** disconnect and reconnect so
  the new group membership is applied.
- **Claude's curl installer returns 403:** this bootstrap installs the pinned
  npm CLI package instead of depending on the web installer.
