# Traefik v2 #

Traefik v2 setup for Entur

## To-Do

* Create pipeline
* Create new dashboards/metrics

* Additional notes:
  * deployment method/steps:
    * create new lb ips
    * deploy new traefik instances
    * ensure traefik instances works
    * turn off publishedServices for old traefik instances to avoid external dns overriding ip adresses
    * follow on external dns that ip adresses are changes

## Configure for a new cluster

First figure out the IP and name to use for our ingress:

```shell
make list-ip PROJ=entur-rtd TYPE=api 
```

This will print out a table, take note of the `NAME` and the `ADDRESS`:

    NAME                   ADDRESS/RANGE   TYPE      PURPOSE  NETWORK  REGION  SUBNET  STATUS
    gke-entur-rtd-api-001  34.149.209.198  EXTERNAL                                    RESERVED

Next we must know the names of the certificates:

```shell
make list-certs PROJ=entur-rtd
```

Almost done, but we need the certificates to allow WAF integration. Select the needed certs.

    NAME           TYPE          CREATION_TIMESTAMP             EXPIRE_TIME
    rtd-entur-io   SELF_MANAGED  2021-12-14T06:42:58.308-08:00  2022-03-14T06:41:04.000-07:00
    rtd-entur-org  SELF_MANAGED  2021-12-15T01:27:20.020-08:00  2022-03-15T01:23:01.000-07:00M

Then, fill out a `.yaml` file for your target environment. The folder name should match the names used in Harness.

```yaml
# ./environments/gcp-rtd/api.yaml
service:
  spec:
    loadBalancerIP: "34.149.209.198"
templates:
  preSharedCerts: rtd-entur-io,rtd-entur-org
  environment: rtd
  staticIpName: gke-entur-rtd-api-001

```

## Local test

```shell
make lint
make template

# with overrides
make lint ENVIRONMENT=gcp-dev INSTANCE_TYPE=api
```

## Force to kubernetes

```shell
make template ENVIRONMENT=gcp-prod-y6u1 INSTANCE_TYPE=public
# `kubectx` be in correct cluster
kubectl apply -f template-gcp-prod-y6u1-public.yaml
```

### Manual install ###

```shell
# be in the correct k8s cluster

instanceType=public
helm template -n traefik-v2-$instanceType \
  --dependency-update \
  -f helm/traefik-v2/values.yaml \
  -f helm/traefik-v2/values-${instanceType}.yaml \
  -f environments/gcp-rtd/${instanceType}.yaml \
  traefik-v2-$instanceType helm/traefik-v2

instanceType=public
helm upgrade --install -n traefik-v2-$instanceType \
  -f helm/traefik-v2/values.yaml \
  -f helm/traefik-v2/values-${instanceType}.yaml \
  -f environments/gcp-rtd/${instanceType}.yaml \
  traefik-v2-$instanceType helm/traefik-v2
```

