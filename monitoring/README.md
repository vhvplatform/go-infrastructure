# Monitoring & Observability

Observability stack for the SaaS Platform.

## Components

### Prometheus
- **Purpose**: Metrics collection and alerting
- **Collects**: Service metrics, infrastructure metrics
- **Retention**: 15 days
- **Scrape interval**: 30s

### Grafana
- **Purpose**: Visualization and dashboards
- **Dashboards**: Services overview, infrastructure monitoring
- **Access**: Port-forward or ingress

### Loki
- **Purpose**: Log aggregation
- **Integration**: Promtail for log collection
- **Retention**: 7 days

### AlertManager
- **Purpose**: Alert routing and notification
- **Integrations**: Slack, PagerDuty
- **Routes**: Critical → PagerDuty, Warning → Slack

## Quick Start

### Access Grafana

```bash
# Port-forward
kubectl port-forward svc/grafana 3000:3000 -n saas-framework

# Open browser
open http://localhost:3000

# Default credentials
# Username: admin
# Password: (retrieve from secret)
kubectl get secret grafana -n saas-framework -o jsonpath="{.data.admin-password}" | base64 -d
```

### Access Prometheus

```bash
kubectl port-forward svc/prometheus 9090:9090 -n saas-framework
open http://localhost:9090
```

## ServiceMonitors

ServiceMonitors automatically discover and scrape metrics from services:

- `api-gateway` - /metrics on port 8080
- `auth-service` - /metrics on gRPC port
- `user-service` - /metrics on gRPC port
- `tenant-service` - /metrics on gRPC port
- `notification-service` - /metrics on port 8084
- `system-config-service` - /metrics on gRPC port

## Dashboards

### Services Overview
- Request rate per service
- Error rate (5xx responses)
- Response time (p50, p95, p99)
- Memory usage
- CPU usage
- Active pods

### Infrastructure
- MongoDB status and connections
- Redis memory usage
- RabbitMQ queue size
- Disk usage
- Network I/O

## Alert Rules

### Service Alerts
- `ServiceDown` - Service unavailable for 5m
- `HighErrorRate` - Error rate > 5% for 5m
- `HighLatency` - p95 latency > 1s for 5m
- `HighMemoryUsage` - Memory > 90% for 5m
- `HighCPUUsage` - CPU > 90% for 5m

### Infrastructure Alerts
- `MongoDBDown` - MongoDB unavailable for 5m
- `RedisDown` - Redis unavailable for 5m
- `RabbitMQDown` - RabbitMQ unavailable for 5m
- `HighDiskUsage` - Disk usage > 90%
- `PodCrashLooping` - Pod restarting frequently

## Alert Notifications

### Slack
- Channel: `#saas-alerts` (all alerts)
- Channel: `#saas-critical` (critical only)
- Channel: `#saas-warnings` (warnings only)

Configure webhook URL in:
```yaml
monitoring/alerts/slack.yaml
```

### PagerDuty
- Service: SaaS Platform
- Escalation: On-call engineer
- Critical alerts only

Configure service key in:
```yaml
monitoring/alerts/pagerduty.yaml
```

## Custom Metrics

Services should expose metrics in Prometheus format:

```go
// Example Go metrics
import "github.com/prometheus/client_golang/prometheus"

var (
    requestCounter = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total HTTP requests",
        },
        []string{"method", "path", "status"},
    )
)
```

## Log Aggregation

Loki collects logs from all pods:

```bash
# View logs in Grafana Explore
# Query examples:
{namespace="saas-framework-dev"}
{app="api-gateway"} |= "error"
{namespace="saas-framework-dev"} | json | level="error"
```

## Best Practices

1. **Instrument all services** - Expose metrics on /metrics
2. **Use consistent labels** - app, namespace, environment
3. **Set appropriate alert thresholds** - Avoid alert fatigue
4. **Create runbooks** - Document alert responses
5. **Monitor the monitors** - Ensure Prometheus/Grafana are healthy
6. **Optimize retention** - Balance cost vs. data needs
7. **Use dashboards** - Create team-specific views
8. **Log structured data** - Use JSON for logs
9. **Test alerts** - Verify notification delivery
10. **Review regularly** - Update thresholds based on traffic

## Troubleshooting

### Metrics not appearing

```bash
# Check ServiceMonitor
kubectl get servicemonitor -n saas-framework-dev

# Check Prometheus targets
# Access Prometheus UI and go to Status → Targets
kubectl port-forward svc/prometheus 9090:9090 -n saas-framework
```

### Alerts not firing

```bash
# Check AlertManager config
kubectl get configmap alertmanager -n saas-framework -o yaml

# Check AlertManager UI
kubectl port-forward svc/alertmanager 9093:9093 -n saas-framework
```

### Dashboards not loading

```bash
# Check Grafana logs
kubectl logs -l app=grafana -n saas-framework

# Verify data source
# Grafana UI → Configuration → Data Sources → Prometheus
```

## References

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/)
