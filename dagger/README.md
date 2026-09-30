# Dagger

I am currently in the process of migrating my CI platform to
[Dagger](https://dagger.io/).

## Modules

The root module (`dagger.json` in the repository root) loads the following
modules from [`modules/`](./modules/) as toolchains:

* `ansible`
* `compliance`
* `github`
* [`python`](./modules/python/README.md)
* [`terraform`](./modules/terraform/README.md)
* `yaml`

The `docker` and `shell` modules are loaded as dependencies only.

Run every check with:

```sh
dagger check
```

Or a subset of checks with a filter, e.g.:

```sh
dagger check 'python:*'
```

## Running Dagger in Kubernetes

### Prerequisites

* A running Kubernetes cluster with a preconfigured `kubectl` profile.
* [Helm](https://helm.sh/docs/intro/install/)

### Setup

1. Install the Dagger Engine DaemonSet on the Kubernetes cluster.

```sh
helm upgrade                                                                  \
   --install                                                                  \
   --namespace=dagger                                                         \
   --create-namespace                                                         \
   dagger                                                                     \
   oci://registry.dagger.io/dagger-helm
```

1. Wait for the Dagger Engine to become ready.

```sh
kubectl wait                                                                  \
   --for condition=Ready                                                      \
   --timeout=60s pod                                                          \
   --selector=name=dagger-dagger-helm-engine                                  \
   --namespace=dagger
```

1. Get the Dagger Engine pod name.

```sh
DAGGER_ENGINE_POD_NAME="$(kubectl get pod                                     \
   --selector=name=dagger-dagger-helm-engine                                  \
   --namespace=dagger                                                         \
   --output=jsonpath='{.items[0].metadata.name}'                              \
)"

export DAGGER_ENGINE_POD_NAME
```

1. Set the `_EXPERIMENTAL_DAGGER_RUNNER_HOST` variable.

```sh
export _EXPERIMENTAL_DAGGER_RUNNER_HOST="kube-pod://${DAGGER_ENGINE_POD_NAME}\
?namespace=dagger"
```

1. Check for install success.

```sh
dagger query <<EOF
{
    container {
        from(address:"alpine") {
            withExec(args: ["uname", "-a"]) { stdout }
        }
    }
}
EOF
```
