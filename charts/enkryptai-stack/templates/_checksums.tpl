{{/*
Pod "annotations:" block: .annotations plus checksum/<name> (hash of data) for each ConfigMap and Secret that .templates (paths under the caller's templates/) render; empty when both are empty.
List a template only when the pod reads every object it renders. Secrets from another chart or subchart stay with Reloader.
Usage: include "enkryptai-stack.podAnnotations" (dict "ctx" $ "templates" (list "configmap.yaml") "annotations" .Values.podAnnotations)
*/}}
{{- define "enkryptai-stack.podAnnotations" -}}
{{- $ctx := .ctx -}}
{{- $data := dict -}}
{{- range .templates -}}
{{- range regexSplit "(?m)^---[ \\t]*$" (include (print $ctx.Template.BasePath "/" .) $ctx) -1 -}}
{{- $obj := fromYaml . -}}
{{- if has ($obj.kind | default "") (list "ConfigMap" "Secret") -}}
{{- $name := $obj.metadata.name -}}
{{- $_ := set $data $name (append (get $data $name | default (list)) (pick $obj "data" "stringData" "binaryData")) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- $out := dict -}}
{{- range $name, $parts := $data -}}
{{- $_ := set $out (printf "checksum/%s" ($name | trunc 63 | trimSuffix "-" | trimSuffix ".")) (toJson $parts | sha256sum) -}}
{{- end -}}
{{- $out = merge $out (.annotations | default dict) -}}
{{- with $out }}
annotations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
