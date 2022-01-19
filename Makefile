ENV=gcp-rtd
TYPE=public
PROJ=entur-rtd
SUBDIRS := $(wildcard ./environments/*)

all: $(SUBDIRS)
$(SUBDIRS):
	@echo $@
	helm lint helm/traefik-v2 \
		--strict \
		--with-subcharts \
		-f helm/traefik-v2/values-public.yaml \
		-f $@/public.yaml

.PHONY: all $(SUBDIRS)

lint:
	helm lint helm/traefik-v2 -f helm/traefik-v2/values-$(TYPE).yaml -f environments/$(ENV)/$(TYPE).yaml

template:
	helm template -n traefik-v2-$(TYPE) \
		--dependency-update \
		-f helm/traefik-v2/values-$(TYPE).yaml \
		-f environments/$(ENV)/$(TYPE).yaml \
		traefik-v2-$(TYPE) helm/traefik-v2 > template-$(ENV)-$(TYPE).yaml

list-ip:
	gcloud compute addresses list --project $(PROJ) --filter="name~'$(PROJ)-$(TYPE)'"

list-certs:
	gcloud compute ssl-certificates list --project $(PROJ)
