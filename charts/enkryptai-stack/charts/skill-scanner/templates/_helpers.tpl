{{/*
Expand the name of the chart.
*/}}
{{- define "skill-scanner.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "skill-scanner.fullname" -}}
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
{{- define "skill-scanner.serviceName" -}}
{{- .Values.service.serviceName | default (include "skill-scanner.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "skill-scanner.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "skill-scanner.labels" -}}
helm.sh/chart: {{ include "skill-scanner.chart" . }}
{{ include "skill-scanner.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "skill-scanner.selectorLabels" -}}
app.kubernetes.io/name: {{ include "skill-scanner.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: skill-scanner
{{- end }}

{{- define "skill-scanner.imagePullSecrets" -}}
{{- $pullSecrets := list }}
{{- if .Values.image.pullSecrets }}
  {{- range .Values.image.pullSecrets }}
    {{- $pullSecrets = append $pullSecrets . }}
  {{- end }}
{{- end }}
{{- if .Values.global.imagePullSecrets }}
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
