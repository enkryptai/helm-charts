{{/*
Name of the chart, or nameOverride.
*/}}
{{- define "redteam-model.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Name of the Deployment, Service and HPA: fullnameOverride, else
"<release>-<name>" (just "<release>" when it already contains the name).
*/}}
{{- define "redteam-model.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Merges a list of maps from values (later maps win) and renders them as
"key: "value"" lines. Every value goes through tpl, so values may use
{{ .Release.Name }} and the like. Renders nothing when all maps are empty.
Usage: include "redteam-model.renderMap" (dict "context" $ "maps" (list .Values.labels .Values.service.labels))
*/}}
{{- define "redteam-model.renderMap" -}}
{{- $ctx := .context -}}
{{- $out := dict -}}
{{- range $m := .maps -}}
{{- range $k, $v := ($m | default dict) -}}
{{- $_ := set $out $k (tpl (toString $v) $ctx) -}}
{{- end -}}
{{- end -}}
{{- range $k, $v := $out }}
{{ $k }}: {{ $v | quote }}
{{- end -}}
{{- end }}

{{/*
Labels of a resource: labels, then the resource's own labels, then
selectorLabels (last, so they can't be overridden and the selector always matches).
Usage: include "redteam-model.labels" (dict "context" $ "labels" .Values.service.labels)
*/}}
{{- define "redteam-model.labels" -}}
{{- include "redteam-model.renderMap" (dict "context" .context "maps" (list .context.Values.labels .labels .context.Values.selectorLabels)) | trim }}
{{- end }}

{{/*
Selector labels (Deployment selector, Service selector). Immutable on a
Deployment once installed.
*/}}
{{- define "redteam-model.selectorLabels" -}}
{{- if not .Values.selectorLabels }}
{{- fail "redteam-model.selectorLabels must not be empty" }}
{{- end }}
{{- include "redteam-model.renderMap" (dict "context" . "maps" (list .Values.selectorLabels)) | trim }}
{{- end }}

{{/*
Annotations block of a resource, from its own annotations value.
Renders the whole "annotations:" block, or nothing when empty.
Usage: include "redteam-model.annotations" (dict "context" $ "annotations" .Values.service.annotations "indent" 2)
*/}}
{{- define "redteam-model.annotations" -}}
{{- $a := include "redteam-model.renderMap" (dict "context" .context "maps" (list .annotations)) | trim -}}
{{- with $a }}
{{- printf "annotations:" | nindent ($.indent | int) }}
{{- . | nindent (add $.indent 2 | int) }}
{{- end }}
{{- end }}

{{/*
Image pull secrets (image.pullSecrets + global.imagePullSecrets)
TODO: once PR #145 merges, call "enkryptai-stack.imagePullSecrets" here and use
"enkryptai-stack.image" for the image line in deployment.yaml, like every other chart.
*/}}
{{- define "redteam-model.imagePullSecrets" -}}
{{- $pullSecrets := list }}
{{- if .Values.image.pullSecrets }}
  {{- range .Values.image.pullSecrets }}
    {{- $pullSecrets = append $pullSecrets . }}
  {{- end }}
{{- end }}
{{- if (.Values.global).imagePullSecrets }}
  {{- range .Values.global.imagePullSecrets }}
    {{- $pullSecrets = append $pullSecrets . }}
  {{- end }}
{{- end }}
{{- if $pullSecrets }}
imagePullSecrets:
  {{- range $pullSecrets | uniq }}
  - name: {{ . }}
  {{- end }}
{{- end }}
{{- end }}

