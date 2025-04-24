# Reverse Proxy for Ollama + Open Web UI

## What is this package?

`reverse_proxy` is a **tiny Nginx‑based proxy container _plus_ helper scripts** that let you:

* host **Open Web UI** on a cheap cloud VM (“droplet”),
* keep **Ollama / Web UI** actually running at home,
* bridge both worlds with a secure **SSH reverse tunnel**,
* (re)deploy in one command on each side.

### Why an SSH reverse tunnel?

*Normal SSH* ( `ssh you@server` ) gives **you** a shell _on_ the server.<br>
**Reverse** tunnelling flips that: the server opens a port (e.g. `3333`)
and _forwards_ every hit back to a port on **your home machine**.
The proxy container then points its Nginx upstream to this tunnel port,
so anyone hitting `http://droplet` transparently reaches your local Web UI.

## Relevant parameters (stored in `params.json`)

| Key               | Meaning                                               | Typical |
|-------------------|-------------------------------------------------------|---------|
| `LOCAL_UI_PORT`   | Port where Web UI listens on your home PC             | `3000` |
| `TUNNEL_UI_PORT`  | Port opened on the droplet and used by Nginx          | `3333` |
| `UI_IP`           | Home PC’s LAN/WAN IP reachable **from** the droplet   | `192.168.0.235` |
| `ipMapping`       | Fixed mapping string for the reverse tunnel           | `0.0.0.0:localhost` |

> **Note** `params.json` stays local (it’s in `.gitignore`)—no secrets in Git.

---

### Pre-built Docker image :arrow_down:

Skip the build step and pull the latest proxy straight from Docker Hub:

```bash
docker pull lmielke/ollama-reverse-proxy:latest
```

That image is refreshed every time dockerize.ps1 is run on the dev machine, so :latest always contains the current Nginx config.
To launch it manually:

``` bash
docker run -d --name reverse-proxy \
  -e UI_PORT=<TUNNEL_UI_PORT> \
  -e UI_IP=<docker0-ip> \
  -p 80:80 lmielke/ollama-reverse-proxy:latest
```
## Step‑by‑step setup

### 1 · Dev machine (`while‑ai‑2`)

```powershell
git clone <repo> reverse_proxy
cd reverse_proxy
.\prepare.ps1           # checks tools, calls set_params.ps1 → writes params.json
.\dockerize.ps1 -u <dockerhub-user>   # build & push container image
```

### 2 · Home server (`while‑ai‑0 / while‑ai‑1`)

```powershell
cd reverse_proxy
.\server.ps1            # shows config → enter:  user@droplet-ip
# tunnel now runs detached
```

### 3 · Droplet (SSH root@droplet)

```bash
git clone <repo> reverse_proxy   # first time only
cd reverse_proxy
bash compose.sh                  # pulls repo, (re)starts proxy container
```

Open a browser: `http://<droplet-ip>` → you should see Open Web UI.

---

## What to expect

* **Every run** of `compose.sh` pulls the latest image & restarts the container.
* `server.ps1` detaches the SSH process—close your terminal, tunnel lives on.
* If SSH drops (reboot, Wi‑Fi), just rerun `server.ps1`.

---

## Minimum requirements

* Windows 10/11 + PowerShell + OpenSSH (`while‑ai‑*` hosts)
* Ubuntu 22.04 droplet with Docker & Docker Compose
* A Docker Hub account (for image publish)

---

## License

MIT – see `LICENSE`.
