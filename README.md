# APISIX + etcd + ADC + GitHub Actions + OpenAPI Demo

This repository provides a runnable demo featuring:

- APISIX Gateway + etcd via Docker Compose
- OpenAPI (httpbin example) with APISIX/ADC annotations
- ADC CLI to generate and publish APISIX configuration
- GitHub Actions for CI/CD

Note: This demo routes to a local `httpbin` container by default for offline use. You can optionally switch to the public `httpbin.org`.

## Quickstart (Local)

Prerequisites: Docker 20+, Docker Compose, curl.

- Start APISIX + etcd + httpbin:
  - `make up`
  - Wait 10–20s for APISIX to be ready
- Verify Admin API (optional):
  - `curl -s http://localhost:9180/apisix/admin/routes -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' | head`
- Seed routes without ADC (admin API demo):
  - `make seed`
- Test traffic through APISIX:
  - `curl -i http://localhost:9080/get`
  - `curl -i http://localhost:9080/status/201`
  - `curl -i -X POST http://localhost:9080/anything -d 'hello=apisix'`
- Observability endpoints are available once Compose is up: Prometheus UI at `http://localhost:9090`, Grafana at `http://localhost:3000` (login `admin` / `admin`), and the APISIX metrics exporter at `http://localhost:9091/apisix/prometheus/metrics`. The Prometheus plugin is attached to the shared `httpbin_service` with `prefer_name=true` so route names appear on labels.

When ADC CLI is ready, use `make render` to produce APISIX config and `make publish` to deploy it (see below).

## OpenAPI + ADC annotations

- See `openapi/httpbin.yaml`, including `/get`, `/status/{code}`, `/anything`.
- The first `servers` entry defines upstream nodes (`httpbin:8080` for local compose).
- `x-adc-*` per operation guides ADC resource generation:
  - `x-adc-name`: route name override (`httpbin_get`, etc.)
  - `x-adc-plugins`: enable plugins (e.g., `cors`, `limit-count`)

## Use ADC (Local)

- Install ADC CLI (see https://github.com/api7/adc)
- Render:
  - `make render`
  - Output: `dist/apisix.yaml`
- Publish (requires Admin API key below):
  - `make publish`

## GitHub Actions (CI/CD)

- Workflow: `.github/workflows/cicd.yaml`
- Triggers: push to `main` or PR
- Steps:
  - Install ADC CLI (GitHub Actions downloads v0.21.2 release binary)
  - Validate and render OpenAPI → APISIX config
  - Publish to APISIX Admin API
Environment in workflow (demo only):
- The workflow uses plaintext env vars for simplicity:
  - `APISIX_ADMIN_API`: e.g., `http://YOUR_PUBLIC_VM:9180`
  - `APISIX_ADMIN_KEY`: demo `edd1c9f034335f136f87ad84b625c8f1`
- This is for demo purposes only. For production, use GitHub Secrets.

## Switch to httpbin.org (Optional)

If outbound network is allowed and you prefer public `httpbin.org`:

1. Edit `openapi/httpbin.yaml`, update the first `servers` entry to `https://httpbin.org` (or your upstream).
2. Add/adjust `x-adc-plugins` as needed (e.g., `proxy-rewrite` to set `host: httpbin.org`).
3. Re-run `make render` and publish.

## APISIX/etcd Configuration

- `docker-compose.yml` runs `etcd`, `apisix`, `httpbin` containers (no persistent volumes)
- APISIX config: stored in `apisix/conf/config.yaml` and mounted read-only into the APISIX container via Compose
  - etcd: `http://etcd:2379`
  - Admin API: `9180`
  - Gateway ports: `9080` (HTTP), `9443` (HTTPS)
  - Admin Key (demo only): `edd1c9f034335f136f87ad84b625c8f1`
  - APISIX image: `apache/apisix:3.14.1-ubuntu`

## Useful Commands

- `make up`: start all services
- `make logs`: tail APISIX logs
- `make render`: generate APISIX config using ADC
- `make publish`: publish config to APISIX Admin API
- `make seed`: seed routes via Admin API (no ADC)
- `make down`: stop containers (no persistent volumes)

## Running on a Public VM

- Point GitHub Actions to your VM by editing `.github/workflows/cicd.yaml` env:
  - `APISIX_ADMIN_API: "http://YOUR_PUBLIC_VM:9180"`
  - Ensure your VM firewall/security group allows inbound TCP 9180 from GitHub Actions runners (demo only). For production, restrict sources and rotate the admin key.

## Layout

- `docker-compose.yml`: containers orchestration
- `apisix/conf/config.yaml`: APISIX config mounted by Compose
- `openapi/httpbin.yaml`: OpenAPI with x-adc hints for ADC
- `monitoring/prometheus/prometheus.yml`: Prometheus scrape config (uses basic auth against APISIX metrics)
- `monitoring/grafana/provisioning/datasources/datasource.yaml`: Grafana data source provisioning for Prometheus
- `scripts/adc_render.sh`: ADC render script (auto-detect verbs)
- `scripts/adc_publish.sh`: ADC publish/apply/sync script (auto-detect verbs)
- `scripts/bootstrap_routes_via_admin.sh`: seed APISIX resources via Admin API
- `apisix/admin_payloads/*.json`: Admin API payload examples
- `.github/workflows/cicd.yaml`: CI/CD workflow
- `Makefile`: helper targets
