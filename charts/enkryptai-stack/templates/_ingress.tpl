{{/*
IngressClass name for an Ingress: the component's own `ingress.className` when
set, otherwise `global.ingress.className`. Empty output means no
`ingressClassName`, so the cluster's default IngressClass is used.

Defined in the parent chart so every subchart Ingress uses the same rule.

Usage (in a subchart Ingress template):
  {{- with include "enkryptai-stack.ingressClassName" (dict "ingress" .Values.ingress "context" $) }}
  ingressClassName: {{ . }}
  {{- end }}
*/}}
{{- define "enkryptai-stack.ingressClassName" -}}
{{- $global := .context.Values.global | default dict -}}
{{- $globalIngress := $global.ingress | default dict -}}
{{- (.ingress).className | default $globalIngress.className | default "" -}}
{{- end }}
