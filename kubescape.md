---
marp: true
theme: default
paginate: true
title: Kubescape Demo on Kind
author: Hidde
style: |
  :root {
    --brand: #326de6;
  }
  section {
    font-family: -apple-system, "Segoe UI", Roboto, sans-serif;
    font-size: 26px;
    padding: 50px 60px;
  }
  h1, h2 { color: var(--brand); }
  code { color: #c7254e; background: #f4f4f4; }
  pre code { color: inherit; }
  table { font-size: 22px; }
  section.lead {
    background: linear-gradient(135deg, #0b1f4b 0%, #326de6 100%);
    color: white;
    text-align: center;
    justify-content: center;
  }
  section.lead h1, section.lead h2 { color: white; }
  section.lead code { color: #ffd866; background: transparent; }
  footer { color: #888; font-size: 14px; }
---

<!-- _class: lead -->

# Kubescape

---

## Kubescape

- CNCF (Cloud Native Computing Foundation) Project
- Create by ARMO
- 13-12-2022 Sandbox
- 13-01-2025 Incubating
- Current version v4.0.21

---

## Kubescape capabilities

🔍 Misconfiguration Scanning	Scan clusters
🐳 Image Vulnerability Scanning
🩹 Image Patching (Automatically patch vulnerable images using Copacetic)
🔧 Auto-Remediation (Automatically fix misconfigurations in Kubernetes manifests)
🛡️ Admission Control (Enforce security policies with Validating Admission Policies)
📊 Runtime Security (eBPF-based runtime monitoring via Inspektor Gadget)
🤖 AI Integration (MCP server for AI assistant integration)

---

## What is this demo?

- Misconfiguration Scanning
- Image Vulnerability Scanning

---

## Compliance: Frameworks

| Framework | Who made it | What it is | Type | Core question |
|---|---|---|---|---|
| **NSA-CISA** | US gov (NSA + CISA) | *Kubernetes Hardening Guidance* — recommended hardening measures | Prescriptive guidance | *What* should a secure cluster look like? |
| **MITRE ATT&CK®** | MITRE (community-backed) | Catalogue of real-world adversary tactics & techniques | Descriptive threat model | *How* do attackers actually operate? |
| **CIS Benchmark** | Center for Internet Security (community consensus) | Detailed, granular configuration audit with pass/fail checks | Prescriptive audit / benchmark | *Does* each setting meet the baseline? |

---

## Compliance: Frameworks example

One privileged pod, three ways to see it:

| Framework | What it is | What it says | Example |
|---|---|---|---|
| **NSA-CISA** | NSA & CISA *Kubernetes Hardening Guidance* | *what* to fix — graded Critical / High / Medium | Running as **root** + `privileged: true` → **Critical** |
| **MITRE ATT&CK®** | Catalogue of attacker tactics & techniques | *why* it matters — the attack technique a finding enables | That pod → **Deploy Container (T1610)** |
| **CIS Benchmark** | Community baseline, versioned per K8s release | *score* — `cis-v1.10.0`, 0–100 | **Privileged container** control fails → score drops |

There’s overlap, but each frames it differently — NSA-CISA says it’s critical, CIS says the control fails, ATT&CK links it to an attack technique.

---

## Compliance: Misconfiguration Scanning

🔍 Using NSA-CISA, MITRE ATT&CK®, and CIS Benchmarks for scanning:

- Clusters
- YAML files
- Helm charts

---

## Vulnerabilities: Image scanning

- Detect CVEs in container images using Grype
- Generate SBOM's

---

## Dashboard: Headlamp

- CNCF (Cloud Native Computing Foundation) Project
- Extensible Kubernetes web UI.
- 17-05-2023 Sandbox
- Current version v0.46.0

---

## Demo: Kind cluster

### Questions?
