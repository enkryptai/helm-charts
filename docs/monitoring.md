# Monitoring Enkrypt AI Stack

## Quick Tip: Access Redteaming Job Logs

For checking logs of running Redteaming jobs, you can leverage the **Argo Workflows dashboard** by port-forwarding it to your local system:

```bash
# Port-forward the Argo server
kubectl -n enkryptai-stack port-forward svc/argo-server 2746:2746
```

Then open your browser and access the dashboard at:
[https://localhost:2746](https://localhost:2746)


Monitoring is an optional but **highly recommended** part of the deployment to ensure observability, performance visibility, and troubleshooting capabilities across the cluster and applications.



---

### Recommended Stack

| Type        | Tool / Stack                                         |                                   Description                                                                                               |
|------------ |------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------- |
| **Metrics** | **Prometheus** (`kube-prometheus-stack`)             | Collects and visualizes cluster and application-level metrics.                                                                              |
| **Logs**    | **Loki**                                             | Lightweight log aggregation system that integrates seamlessly with Grafana.                                                                 |
| **Tracing** | **OpenTelemetry (OTel)**                             | Captures distributed traces, metrics, and logs for deeper insight into application behavior. Note tracing is not supported for Redteam jobs |

---


### Suggested Setup

- Install the **kube-prometheus-stack** Helm chart for metrics collection, alerting, and dashboards.
- Deploy a **single-instance Loki** setup for log aggregation.
- Use the **OpenTelemetry Operator for Kubernetes** to auto-instrument your applications for trace and log export.
- The operator can automatically inject sidecars or environment configurations to capture telemetry data.
- Integrate **Grafana** for unified visualization of logs, metrics, and traces.

---

### Note

> The monitoring stack is **not part of the EnkryptAI stack** by default.
> However, it can be **installed alongside EnkryptAI** to enable full observability.


---

### References

- [kube-prometheus-stack Helm Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Grafana Loki](https://grafana.com/oss/loki/)
- [OpenTelemetry Operator for Kubernetes](https://github.com/open-telemetry/opentelemetry-operator)

---
