{{/*
Outbound proxy env list from global.proxy (docs/outbound-proxy.md), or nothing when httpProxy and
httpsProxy are empty. Takes the root context. The proxy uses env only; the trusted CA uses envFrom
and volumes, so the two never edit the same lines.
*/}}
{{- define "enkryptai-stack.proxy.env" -}}
{{- $p := (.Values.global).proxy | default dict }}
{{- if or $p.httpProxy $p.httpsProxy }}
{{- $no := list "localhost" "127.0.0.1" "::1" "169.254.169.254" "kubernetes.default" ".svc" ".cluster.local" (printf ".%s" .Release.Namespace) ".enkryptai-stack" ".redteam-jobs" ".argo-events" }}
{{- $no = concat $no (splitList "," (include "enkryptai-stack.proxy.serviceHosts" .)) }}
{{- range splitList "," ($p.noProxy | default "") }}{{ with trim . }}{{ $no = append $no . }}{{ end }}{{ end }}
{{- $noProxy := $no | uniq | join "," }}
{{- with $p.httpProxy }}
- name: HTTP_PROXY
  value: {{ . | quote }}
- name: http_proxy
  value: {{ . | quote }}
{{- end }}
{{- with $p.httpsProxy }}
- name: HTTPS_PROXY
  value: {{ . | quote }}
- name: https_proxy
  value: {{ . | quote }}
{{- end }}
- name: NO_PROXY
  value: {{ $noProxy | quote }}
- name: no_proxy
  value: {{ $noProxy | quote }}
{{- /* Node reads the proxy variables only with this set (Node 22.21 and 24 or later). */}}
- name: NODE_USE_ENV_PROXY
  value: "1"
{{- end }}
{{- end }}

{{/* Short Service names the components call without a domain; NO_PROXY cannot match them by suffix. Add new Services here. */}}
{{- define "enkryptai-stack.proxy.serviceHosts" -}}
{{- $names := list "frontend" "gateway-kong" "guardrails" "redteam-proxy" "openfga" "minio" "supabase-storage" "functions" "nats" "valkey" "enkryptai-opensearch-cluster" "nginx-html-service" "compliance-scan" "leaderboard-client" "leaderboard-server" "mcp-scanner" "skill-scanner" "secure-mcp-gateway-service" }}
{{- range list "guardrails-model" "guardrails-multi-modal" "litellm" "supabase-analytics" "supabase-auth" "supabase-db" "supabase-functions" "supabase-imgproxy" "supabase-kong" "supabase-meta" "supabase-realtime" "supabase-rest" "supabase-studio" "supabase-vector" }}
{{- $names = append $names (printf "%s-%s" $.Release.Name .) }}
{{- end }}
{{- join "," $names }}
{{- end }}
