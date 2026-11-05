{{/*
Outbound proxy env list for the red team Workflow pods, from global.proxy (docs/outbound-proxy.md).
Same shape as enkryptai-stack.proxy.env, without the stack's short Service names.
*/}}
{{- define "platform.proxy.env" -}}
{{- $p := (.Values.global).proxy | default dict }}
{{- if or $p.httpProxy $p.httpsProxy }}
{{- $no := list "localhost" "127.0.0.1" "::1" "169.254.169.254" "kubernetes.default" ".svc" ".cluster.local" (printf ".%s" .Release.Namespace) ".enkryptai-stack" ".redteam-jobs" ".argo-events" }}
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
