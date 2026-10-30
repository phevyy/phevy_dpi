"""Kullanici ayarlari ve dosya yollari (%APPDATA%\\phevy_dpi)."""
import json
import os

CONFIG_DIR = os.path.join(os.environ.get("APPDATA", os.path.expanduser("~")), "phevy_dpi")
CONFIG_FILE = os.path.join(CONFIG_DIR, "config.json")
EXTRA_DOMAINS_FILE = os.path.join(CONFIG_DIR, "domains.txt")
LOG_FILE = os.path.join(CONFIG_DIR, "log.txt")


def load_config():
    try:
        with open(CONFIG_FILE, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save_config(cfg):
    os.makedirs(CONFIG_DIR, exist_ok=True)
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        json.dump(cfg, f, indent=2)
