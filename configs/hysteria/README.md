# Hysteria config placement

Recommended layout:
- Keep a template in this repo (without secrets), for example `configs/hysteria/client.yaml.example`.
- Keep the real client config with credentials outside git, for example:
  `/persist/secrets/hysteria/client.yaml`

Run example:
`hysteria client -c /persist/secrets/hysteria/client.yaml`

If you want this to start automatically, add a dedicated systemd user service
that points to the same file in `/persist/secrets`.
