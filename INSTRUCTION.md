# ToDo App — MySQL StatefulSet Instructions

## Prerequisites

- `kind` installed (https://kind.sigs.k8s.io/)
- `kubectl` installed and configured
- Docker running locally

## 1. Create the cluster

Spin up a local Kubernetes cluster using `kind` and the provided
configuration file:

```bash
kind create cluster --config cluster.yml
```

Verify the cluster is up:

```bash
kubectl cluster-info --context kind-kind
```

## 2. Deploy all resources

Run the bootstrap script, which applies all manifests in the correct order:

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

## 3. Validate the MySQL StatefulSet

Check that all 3 MySQL pods are running:

```bash
kubectl get pods -n mysql
```

You should see `mysql-0`, `mysql-1`, and `mysql-2`, each with status `Running`.

Check the StatefulSet status:

```bash
kubectl get statefulset -n mysql
```

Check that each pod has its own PersistentVolumeClaim, created via
`volumeClaimTemplates`:

```bash
kubectl get pvc -n mysql
```

You should see one PVC per pod (e.g., `data-mysql-0`, `data-mysql-1`,
`data-mysql-2`).

Check that the headless service resolves to individual pod IPs:

```bash
kubectl run dns-test -n mysql --rm -it --image=busybox:1.28 --restart=Never -- \
  nslookup mysql-0.mysql.mysql.svc.cluster.local
```

## 4. Validate secrets are correctly read by MySQL

Connect to `mysql-0` and confirm the database, user, and privileges were
initialized as expected:

```bash
kubectl exec -it mysql-0 -n mysql -- \
  mysql -u mysqluser -p"$(kubectl get secret mysql-secret -n mysql -o jsonpath='{.data.MYSQL_PASSWORD}' | base64 -d)" \
  -e "SHOW DATABASES;"
```

You should see the `todolist` database in the output, confirming that
`MYSQL_DATABASE`, `MYSQL_USER`, and `MYSQL_PASSWORD` from the Secret were
applied correctly, and that `init.sql` (mounted from the ConfigMap into
`/docker-entrypoint-initdb.d`) was executed.

## 5. Validate liveness and readiness probes

Describe a MySQL pod and confirm both probes are configured and passing:

```bash
kubectl describe pod mysql-0 -n mysql
```

Look for the `Liveness` and `Readiness` sections, and confirm the pod's
`Conditions` show `Ready: True`.

## 6. Validate the app connects to `mysql-0`

Check that the app pods are running:

```bash
kubectl get pods -n todoapp
```

Confirm the app's database connection secret is correctly mounted as
environment variables:

```bash
kubectl exec -n todoapp <app-pod-name> -- env | grep -E "NAME|USER|PASSWORD|HOST"
```

(Replace `<app-pod-name>` with an actual pod name from
`kubectl get pods -n todoapp`.)

The `HOST` value should be `mysql-0.mysql.mysql.svc.cluster.local`,
confirming the app is configured to connect specifically to the
zero-indexed MySQL pod.

## 7. Validate the app is working end to end

Forward a local port to the app service:

```bash
kubectl port-forward -n todoapp service/todoapp-service 8000:80
```

Open http://localhost:8000 in your browser, create a to-do item, and
confirm it persists after refreshing the page — this validates that data
is being written to and read from MySQL through the app.

## Cleaning up

```bash
kind delete cluster
```