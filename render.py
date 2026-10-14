#!/usr/bin/env python3
"""Render cloud-init user-data and meta-data from their templates."""
import sys

from jinja2 import Environment, FileSystemLoader


def main():
    args = sys.argv[1:]
    if len(args) > 6:
        print("usage: render.py [NAME [PASSWORD [HOSTNAME [IP_ADDRESS [IP_GATEWAY [DNS_SERVERS]]]]]]", file=sys.stderr)
        return 2

    name = args[0] if len(args) > 0 else "ub"
    password = args[1] if len(args) > 1 else "P@5Sub!"
    hostname = args[2] if len(args) > 2 else "ubuntu"
    ip_address = args[3] if len(args) > 3 else "192.168.68.201"
    gateway = args[4] if len(args) > 4 else "192.168.68.1"
    dns_servers = args[5] if len(args) > 5 else "192.168.100.1,192.168.68.1,1.1.1.1"
    env = Environment(loader=FileSystemLoader("."), keep_trailing_newline=True)
    context = {
        "name": name,
        "nama": name,
        "user": name,
        "username": name,
        "password": password,
        "pass": password,
        "katasandi": password,
        "hostname": hostname,
        "host": hostname,
        "ip_address": ip_address,
        "gateway": gateway,
        "dns_servers": dns_servers,
    }

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
