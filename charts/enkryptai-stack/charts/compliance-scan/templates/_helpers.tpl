{{/*
Expand the name of the chart.
*/}}
{{- define "compliance-scan.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "compliance-scan.fullname" -}}
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
{{- define "compliance-scan.serviceName" -}}
{{- .Values.service.serviceName | default (include "compliance-scan.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "compliance-scan.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "compliance-scan.labels" -}}
helm.sh/chart: {{ include "compliance-scan.chart" . }}
{{ include "compliance-scan.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "compliance-scan.selectorLabels" -}}
app.kubernetes.io/name: {{ include "compliance-scan.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: compliance-scan
{{- end }}

{{- define "compliance-scan.imagePullSecrets" -}}
{{- include "enkryptai-stack.imagePullSecrets" (dict "global" .Values.global "local" .Values.image.pullSecrets) }}
{{- end }}
