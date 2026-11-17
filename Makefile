CLUSTER_NAME := kubescape-demo

.PHONY: help all scan-trigger

.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "Available targets:"
	@echo ""
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

create-presentation: ## Create presentation
	@echo "👉 Generate HTML..."
	marp kubescape.md -o kubescape.html #--theme-set theme/thefactory.css --allow-local-file

create-demo-cluster: ## Create a Kind demo cluster
	@echo "🚀 Creating kind cluster '$(CLUSTER_NAME)'..."
	kind create cluster --name $(CLUSTER_NAME) --config kind/kubescape-demo.yaml
	@echo "✅ Cluster '$(CLUSTER_NAME)' created."

pause-demo-cluster: ## Pause a Kind demo cluster
	@echo "⏸️ Pausing kind cluster '$(CLUSTER_NAME)'..."
	docker pause ${CLUSTER_NAME}-control-plane ${CLUSTER_NAME}-worker ${CLUSTER_NAME}-worker2
	@echo "✅ Cluster '$(CLUSTER_NAME)' paused."

unpause-demo-cluster: ## Unpause a Kind demo cluster
	@echo "▶️ Starting kind cluster '$(CLUSTER_NAME)'..."
	docker unpause ${CLUSTER_NAME}-control-plane ${CLUSTER_NAME}-worker ${CLUSTER_NAME}-worker2
	@echo "✅ Cluster '$(CLUSTER_NAME)' started."

delete-demo-cluster: ## Delete the Kind demo cluster
	@echo "🧹 Deleting kind cluster '$(CLUSTER_NAME)'..."
	kind delete cluster --name $(CLUSTER_NAME)
	@echo "✅ Cluster deleted."

deploy-applications: ## Deploy Applications
	@echo "📦 Installing components via helmfile..."
	helmfile apply
	@echo "🔀 Applying Traefik ingress routes..."
	kubectl apply -f traefik/ingress-route.yaml
	@echo "✅ All components installed."
	@echo "Run 'make scan-trigger' to create job that scan Controls and CVE's"
	@echo "Login in Headlamp http://headlamp.localhost and navigate on the left to Kubescape"

create-demo: create-demo-cluster deploy-applications ## Create Demo

scan-trigger: ## Trigger both scans now (configuration + vulnerability scan)
	@echo "🔎 Triggering configuration scan..."
	kubectl -n kubescape create job --from=cronjob/kubescape-scheduler config-scan-$$(date +%Y%m%d-%H%M%S)
	@echo "🔎 Triggering vulnerability scan..."
	kubectl -n kubescape create job --from=cronjob/kubevuln-scheduler vuln-scan-$$(date +%Y%m%d-%H%M%S)
	@echo "✅ Scan jobs started - watch: kubectl -n kubescape get jobs -w"
