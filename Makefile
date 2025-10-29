.PHONY: up down logs render publish seed

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f apisix

render:
	bash scripts/adc_render.sh

publish:
	bash scripts/adc_publish.sh

seed:
	bash scripts/bootstrap_routes_via_admin.sh
