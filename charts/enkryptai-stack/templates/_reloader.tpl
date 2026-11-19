{{/*
Workload "annotations:" block: .annotations plus Reloader named lists, names regex-escaped. Secrets come from
global.reloadSecrets["<Kind>/<name>"] (Secrets no chart renders; the on-prem admin tool writes the map), and the
ConfigMap from global.trustedCA.configMapName (a customer ConfigMap no chart renders). Empty when all are empty.
*/}}
{{- define "enkryptai-stack.reloadAnnotations" -}}
{{- $g := .ctx.Values.global | default dict -}}
{{- $out := dict -}}
{{- $secrets := list -}}
{{- range (get ($g.reloadSecrets | default dict) (printf "%s/%s" .kind .name)) | default list }}{{ $secrets = append $secrets (regexQuoteMeta .) }}{{ end -}}
{{- with $secrets }}{{ $_ := set $out "secret.reloader.stakater.com/reload" (. | uniq | join ",") }}{{ end -}}
{{- with ($g.trustedCA | default dict).configMapName }}{{ $_ := set $out "configmap.reloader.stakater.com/reload" (regexQuoteMeta .) }}{{ end -}}
{{- $out = merge $out (.annotations | default dict) -}}
{{- with $out -}}
annotations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
