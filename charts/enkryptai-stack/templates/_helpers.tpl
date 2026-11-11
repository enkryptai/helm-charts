{{/*
Expand the name of the chart.
*/}}
{{- define "enkryptai-stack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "enkryptai-stack.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "enkryptai-stack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "enkryptai-stack.labels" -}}
helm.sh/chart: {{ include "enkryptai-stack.chart" . }}
{{ include "enkryptai-stack.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "enkryptai-stack.selectorLabels" -}}
app.kubernetes.io/name: {{ include "enkryptai-stack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "enkryptai-stack.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "enkryptai-stack.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image reference "<registry>/<repository>:<tag>", used by every image in this chart and
its subcharts (upstream openfga excepted).
registry: image.registry, else global.imageRegistry, else global.registry. Nothing is
prefixed when the repository already starts with a registry host (first path part has a
"." or ":", or is "localhost"), so repositories that carry a full path keep working.
tag: image.tag, else the "default" argument.
Usage: include "enkryptai-stack.image" (dict "image" .Values.image "global" .Values.global "default" .Chart.AppVersion)
*/}}
{{- define "enkryptai-stack.image" -}}
{{- $repo := .image.repository -}}
{{- $parts := splitList "/" $repo -}}
{{- $first := first $parts -}}
{{- $hasHost := and (gt (len $parts) 1) (or (contains "." $first) (contains ":" $first) (eq $first "localhost")) -}}
{{- $registry := .image.registry | default (.global).imageRegistry | default (.global).registry -}}
{{- $tag := .image.tag | default .default -}}
{{- if and $registry (not $hasHost) }}{{ $registry }}/{{ end }}{{ $repo }}{{ with $tag }}:{{ . }}{{ end }}
{{- end }}

{{/*
imagePullSecrets block for a pod spec: the component's own list, then
global.imagePullSecrets, without duplicates. Entries may be names ("regcred") or maps
({name: regcred}). Renders nothing when both lists are empty.
Usage: include "enkryptai-stack.imagePullSecrets" (dict "global" .Values.global "local" .Values.image.pullSecrets)
*/}}
{{- define "enkryptai-stack.imagePullSecrets" -}}
{{- $names := list -}}
{{- range (concat (.local | default list) ((.global).imagePullSecrets | default list)) }}
{{- $n := . -}}
{{- if kindIs "map" . }}{{ $n = .name }}{{ end -}}
{{- if and $n (not (has $n $names)) }}{{ $names = append $names $n }}{{ end -}}
{{- end }}
{{- with $names }}
imagePullSecrets:
{{- range . }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end }}
