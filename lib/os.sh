#!/usr/bin/env bash
# OS detection + shared helpers. Sourced by installers/syncers/doctor scripts.
set -euo pipefail

detect_os() {
  case "$(uname -s)" in
    Darwin) echo mac ;;
    Linux)
      if [ -f /etc/arch-release ]; then echo arch
      elif [ -f /etc/os-release ]; then
        . /etc/os-release
        case "${ID:-}" in ubuntu|debian|pop) echo ubuntu ;; *) echo linux-generic ;; esac
      else echo linux-generic; fi
      ;;
    *) echo unknown ;;
  esac
}
OS="$(detect_os)"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && git rev-parse --show-toplevel 2>/dev/null || pwd)"   # BASH_SOURCE (sourced lib), not $0
