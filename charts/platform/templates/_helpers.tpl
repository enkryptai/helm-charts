{{/*
Hook annotations for resources that are hooks only when platform-core is
bundled into this release (platform-core.enabled: true). In that layout the
operator CRDs are installed by this same release, so CRs must wait for
post-install. When platform-core is its own release, installed first, the CRDs
already exist and these resources render as normal resources, so helm upgrade
updates them and helm uninstall removes them.

Usage: {{- include "platform.hookAnnotations" (dict "root" $ "hook" "post-install" "weight" "20") | nindent 4 }}
*/}}
{{- define "platform.hookAnnotations" -}}
{{- if index .root.Values "platform-core" "enabled" }}
"helm.sh/hook-weight": {{ .weight | quote }}
"helm.sh/hook": {{ .hook }}
{{- end }}
{{- end }}
