# Kubescape Demo

A self-contained, local Kubernetes security demo.

Everything runs locally; no Kubescape Cloud/SaaS account is required. Scan results are stored in-cluster and viewed through the Headlamp UI.

## Architecture

| Component | Namespace | Chart / version | Purpose |
|---|---|---|---|
| Traefik | `networking` | traefik 34.4.1 | Ingress controller, NodePort on the `ingress-ready` node, host ports 80/443 |
| Headlamp | `headlamp` | headlamp 0.45.0 | Web dashboard with the Kubescape plugin (v0.11.2) |
| Kubescape Operator | `kubescape` | kubescape-operator 1.40.4 | Configuration, node, SBOM, and vulnerability scanning |

Cluster: 1 control-plane + 2 workers (`kind/kubescape-demo.yaml`).

### Kubescape capabilities

Enabled: configuration scan, continuous scan, node scan, node SBOM generation, vulnerability scan, risk acceptance.
Disabled: relevancy, VEX, runtime observability/detection, network policy generation, malware detection, node profiling, seccomp generation, auto-upgrading, Prometheus exporter.

Frameworks installed: `cis-v1.10.0`, `nsa`, `mitre`, `DevOpsBest`, `ArmoBest`, `cis-aks-t1.2.0`.

## Prerequisites

You need Docker and a few CLI tools. Pick the install that matches your OS.

Whichever OS you're on, you need:

- **Docker** — must be running (`docker info` should succeed)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [helm](https://helm.sh/docs/intro/install/) — used by helmfile
- [helmfile](https://helmfile.readthedocs.io/en/latest/#installation)

<details>
<summary>🍏 macOS</summary>

```sh
brew install kind kubectl helm helmfile
```
</details>

<details>
<summary>🐧 Linux (Debian/Ubuntu)</summary>

```sh
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# kind
curl -Lo kind "https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64" && chmod +x kind && sudo mv kind /usr/local/bin/

# helmfile
curl -Lo helmfile "https://github.com/helmfile/helmfile/releases/latest/download/helmfile_linux_amd64" && chmod +x helmfile && sudo mv helmfile /usr/local/bin/
```
</details>

<details>
<summary>🪟 Windows (WSL2)</summary>

The recommended way to run Kind on Windows is **WSL2** with a Linux distro. From an **administrator** PowerShell:

```powershell
wsl --install -d Ubuntu
```

Restart, then make sure **Docker Desktop is using the WSL2 backend**. In the Ubuntu distro, install the tools (same commands as Linux):

```bash
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# kind
curl -Lo kind "https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64" && chmod +x kind && sudo mv kind /usr/local/bin/

# helmfile
curl -Lo helmfile "https://github.com/helmfile/helmfile/releases/latest/download/helmfile_linux_amd64" && chmod +x helmfile && sudo mv helmfile /usr/local/bin/
```

> From WSL2, open the demo at **http://headlamp.localhost** in your Windows browser. If `*.localhost` doesn't resolve, add `127.0.0.1 headlamp.localhost` to `C:\Windows\System32\drivers\etc\hosts`.
</details>

> **Before you start:** host ports 80 and 443 must be free — Kind maps them to the cluster for ingress. Check with `lsof -i :80 -i :443`.

## Quick start

1. Ensure Docker is running and nothing is using ports 80/443:

   ```sh
   docker info
   lsof -i :80 -i :443
   ```

2. Create the cluster and install all components in one go:

   ```sh
   make create-demo
   ```

   This runs two steps:

   1. `create-demo-cluster` — creates the Kind cluster `kubescape-demo`
   2. `deploy-applications` — `helmfile apply` + applies the Traefik IngressRoute

   First run pulls the node images and charts, so it can take a few minutes.

3. Once `make create-demo` finishes, wait for everything to be ready:

   ```sh
   kubectl get pods -A
   ```

   You want `Running`/`Completed` across namespaces; if anything is stuck, give it another ~30s.

### Open Headlamp

Browse to **http://headlamp.localhost** — the Kubescape plugin is pre-installed and shows scan results in the sidebar.

> Note: Headlamp runs with `unsafeUseServiceAccountToken: true` and no authentication. This is fine for a local demo on a trusted machine; never expose it beyond localhost.

## Scanning

Scans run automatically on a schedule via CronJobs. To trigger them on demand:

```sh
make scan-trigger         # starts one-off config scan + vulnerability scan
kubectl -n kubescape get jobs -w
```

Results appear in Headlamp under the Kubescape plugin shortly after the jobs complete.

## Cluster lifecycle

```sh
make pause-demo-cluster     # docker pause all 3 nodes (frees CPU/RAM, keeps state)
make unpause-dev-cluster    # resume the cluster
make delete-demo-cluster    # tear everything down
```

## Repository layout

```
Makefile                    # cluster lifecycle, deploy, and scan-trigger targets
helmfile.yaml               # pinned charts and value files for all releases
kind/kubescape-demo.yaml    # Kind cluster config (3 nodes, host ports 80/443)
traefik/values.yaml         # NodePort ingress, JSON access logs
traefik/ingress-route.yaml  # routes headlamp.localhost -> Headlamp
headlamp/values.yaml        # Headlamp + Kubescape plugin init container
kubescape/values.yaml       # operator capabilities and frameworks
kubescape/job.yaml          # manual scan jobs (alternative to `make scan-trigger`)
```

## Useful commands

```sh
# Inspect scan results as custom resources
kubectl get kscans,kscansvuln,kscannode -A 2>/dev/null

# Watch the operator
kubectl -n kubescape get pods -w

# Re-deploy after changing any values.yaml
helmfile apply

# Full reset
make delete-demo-cluster && make create-demo
```

## Troubleshooting

- **`port is already allocated` / cluster won't start** — something else uses host port 80/443 (often a local web server or another Kind cluster). Free the ports or edit `extraPortMappings` in `kind/kubescape-demo.yaml`.
- **`headlamp.localhost` doesn't resolve** — modern browsers resolve `*.localhost` natively; if yours doesn't, add `127.0.0.1 headlamp.localhost` to `/etc/hosts`.
- **No results in the plugin** — check that the operator pods are up (`kubectl -n kubescape get pods`) and that the CronJobs ran (`kubectl -n kubescape get cronjobs`); use `make scan-trigger` to force a scan.
- **Paused cluster won't respond** — run `make unpause-dev-cluster`; the API server may need ~30s to recover after unpausing.
