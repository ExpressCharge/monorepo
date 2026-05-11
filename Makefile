.PHONY: help bootstrap update \
        web-dev web-build web-test web-check \
        email-worker-dev email-worker-test email-worker-check email-worker-deploy \
        ios-build ios-test ios-format ios-check \
        steve-build steve-up steve-test \
        docs-dev docs-build docs-check docs-author docs-author-tier docs-drift docs-vocab \
        test check up down compose-build

DENO ?= $(HOME)/.deno/bin/deno
XCODEBUILD_DESTINATION ?= platform=iOS Simulator,name=iPhone 17 Pro,OS=latest

help:
	@awk 'BEGIN{FS=":.*##"; printf "Targets:\n"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  %-22s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

bootstrap: ## Initialize submodules
	git submodule update --init --recursive

update: ## Pull latest main from each submodule + stage pointer bumps
	git submodule update --remote --merge
	git diff --submodule=log

# --- web -------------------------------------------------------------

web-dev: ## Run web in dev mode (Vite + Deno)
	cd web && $(DENO) task dev

web-build: ## Build web for production
	cd web && $(DENO) task build

web-test: ## Run web tests
	cd web && $(DENO) task test

web-check: ## fmt + lint + typecheck
	cd web && $(DENO) task check

# --- email-worker ----------------------------------------------------

email-worker-dev: ## Run email-worker locally (wrangler dev)
	cd email-worker && npx wrangler dev

email-worker-check: ## Typecheck the email-worker
	cd email-worker && npx tsc --noEmit

email-worker-test: ## Run email-worker tests (if present)
	cd email-worker && npm test --if-present

email-worker-deploy: ## Deploy email-worker to Cloudflare
	cd email-worker && bin/deploy.sh

# --- ios -------------------------------------------------------------

ios-build: ## Regenerate Xcode project + build for simulator
	cd ios && xcodegen generate && \
	xcodebuild -scheme ExpresScan-Debug \
	  -destination "$(XCODEBUILD_DESTINATION)" build

ios-test: ## Run iOS unit + UI tests
	cd ios && xcodegen generate && \
	xcodebuild -scheme ExpresScan-Debug \
	  -destination "$(XCODEBUILD_DESTINATION)" test

ios-format: ## Run swift-format
	cd ios && xcrun swift-format format --recursive -i \
	  App Sources Tests ExpresScanTests ExpresScanUITests

ios-check: ## Lint
	cd ios && xcrun swift-format lint --recursive --strict \
	  App Sources Tests ExpresScanTests ExpresScanUITests

# --- steve (OCPP backend) -------------------------------------------

steve-build: ## Build the StEvE Docker image
	cd steve && docker compose build

steve-up: ## Bring up StEvE + MariaDB (needs docker-compose.app.env)
	cd steve && docker compose up -d

steve-test: ## Run StEvE unit tests
	cd steve && ./mvnw test -B -ntp

# --- docs (Starlight site at docs.polaris.express) ------------------

docs-dev: ## Run the docs site in dev (http://localhost:4321)
	cd docs && npm run dev

docs-build: ## Build the docs site for production
	cd docs && npm run build

docs-check: ## Lint + typecheck the docs site
	cd docs && npm run check

docs-author: ## Author one article: make docs-author SLUG=user.web.sessions.start-a-charge
	cd docs && npm run author -- --slug $(SLUG)

docs-author-tier: ## Author all entries in a tier: make docs-author-tier TIER=P0
	cd docs && npm run author:tier -- --tier $(TIER) --concurrency $(or $(CONCURRENCY),1)

docs-drift: ## Check articles for code_refs drift
	cd docs && npm run drift

docs-vocab: ## Refresh the docs cspell vocab from sibling submodules
	cd docs && npm run vocab

# --- aggregate -------------------------------------------------------

check: web-check email-worker-check ios-check docs-check ## All lint / typecheck

test: web-test email-worker-test ios-test ## All test suites

compose-build: ## Build the integrated docker stack
	docker compose build

up: ## Bring up the integrated stack
	docker compose up -d

down: ## Tear down the integrated stack
	docker compose down
