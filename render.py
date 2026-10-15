#!/usr/bin/env python3
"""Render cloud-init user-data and meta-data from their templates.

Usage:
    python3 render.py [KEY=VALUE ...]

Supported keys (all optional):
    name          Nama user (default: ub)
    password      Password user (default: P@5Sub!)
    hostname      Hostname VM (default: ubuntu)
    ip_address    IP statis VM (default: 192.168.68.201)
    ip_gateway    Gateway jaringan (default: 192.168.68.1)
    dns_servers   Daftar DNS (default: 192.168.100.1,192.168.68.1,1.1.1.1)
    net_mode      Mode jaringan: bridged atau nat (default: bridged)

Alias diterima: user/nama/username -> name,
                pass/katasandi -> password,
                host -> hostname,
                ip -> ip_address.
"""
import sys

from jinja2 import Environment, FileSystemLoader


DEFAULTS = {
    "name": "ub",
    "password": "P@5Sub!",
    "hostname": "ubuntu",
    "ip_address": "192.168.68.201",
    "gateway": "192.168.68.1",
    "dns_servers": "192.168.100.1,192.168.68.1,1.1.1.1",
    "net_mode": "bridged",
    "ssh_host_port": "2222",
}

ALIASES = {
    "user": "name",
    "nama": "name",
    "username": "name",
    "pass": "password",
    "katasandi": "password",
    "host": "hostname",
    "ip": "ip_address",
    "ip_gateway": "gateway",
    "dns": "dns_servers",
}


def parse_args(args):
    context = dict(DEFAULTS)
    for arg in args:
        if "=" not in arg:
            print(
                f"error: argumen '{arg}' tidak valid, gunakan format KEY=VALUE",
                file=sys.stderr,
            )
            return None
        key, value = arg.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")

        key = ALIASES.get(key, key)
        if key not in DEFAULTS:
            print(
                f"warning: kunci '{key}' tidak dikenal, diabaikan",
                file=sys.stderr,
            )
            continue
        context[key] = value
    return context


def main():
    context = parse_args(sys.argv[1:])
    if context is None:
        return 2

    env = Environment(loader=FileSystemLoader("."), keep_trailing_newline=True)

    for template_name, output_name in (
        ("user-data.template.yml", "user-data"),
        ("meta-data.template.yml", "meta-data"),
        ("network-config.template.yml", "network-config"),
    ):
        rendered = env.get_template(template_name).render(**context)
        with open(output_name, "w", encoding="utf-8") as output_file:
            output_file.write(rendered)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
