all:

.PHONY: image
image:
	docker build -t scraping:1.0.0 .

.PHONY: chrome
	docker compose up chrome -d

.PHONY: app
app: chrome
	docker compose up app
