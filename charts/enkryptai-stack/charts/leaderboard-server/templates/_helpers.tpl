{{/*
Expand the name of the chart.
*/}}
{{- define "leaderboard-server.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "leaderboard-server.fullname" -}}
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
Service name. Defaults to the fullname; service.serviceName overrides it.
*/}}
{{- define "leaderboard-server.serviceName" -}}
{{- .Values.service.serviceName | default (include "leaderboard-server.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "leaderboard-server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "leaderboard-server.labels" -}}
helm.sh/chart: {{ include "leaderboard-server.chart" . }}
{{ include "leaderboard-server.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "leaderboard-server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "leaderboard-server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: leaderboard-server
{{- end }}

{{- define "leaderboard-server.imagePullSecrets" -}}
{{- include "enkryptai-stack.imagePullSecrets" (dict "global" .Values.global "local" .Values.image.pullSecrets) }}
{{- end }}
