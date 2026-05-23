# ⚡️ cloudshell-tunnel

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-Bash-green.svg)]()
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-lightgrey.svg)]()

A zero-dependency, 1-click CLI utility to provision secure, high-speed SOCKS5 tunnels via Google Cloud Shell. 

## 🌍 The Problem (Why this exists)
In many regions, ISPs heavily throttle international traffic, severely disrupting developer workflows. For security researchers, OSINT investigators, and developers relying on international APIs, Docker registries, or secure endpoints, this throttling causes dropped connections and unworkable latency. 

**`cloudshell-tunnel` acts as critical access infrastructure.** It provides a lightweight, automated way to bypass localized ISP shaping by securely routing traffic through Google's backbone network, restoring expected speeds and connectivity for essential development tasks.

## ✨ Features
* **Zero-Dependency Setup:** Only requires the standard `gcloud` SDK.
* **1-Click Provisioning:** Spin up and tear down a secure tunnel in a single command.
* **Graceful Teardown:** Built-in trap handling ensures no orphaned background processes or lingering port bindings.
* **Transparent Routing:** Maps a local port to a dynamic SOCKS proxy for seamless browser or terminal integration.

## 🚀 Quick Start

### 1. Prerequisites
Ensure you have the [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed and authenticated:
```text
gcloud auth login

curl -sL [https://raw.githubusercontent.com/imgolamrabbani/cloudshell-tunnel/main/install.sh](https://raw.githubusercontent.com/imgolamrabbani/cloudshell-tunnel/main/install.sh) | bash



To specify a custom port:
cloudshell-tunnel 8080
