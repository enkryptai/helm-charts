{{/*
Expand the name of the chart.
*/}}
{{- define "gateway-kong.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "gateway-kong.fullname" -}}
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
{{- define "gateway-kong.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "gateway-kong.labels" -}}
helm.sh/chart: {{ include "gateway-kong.chart" . }}
{{ include "gateway-kong.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "gateway-kong.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gateway-kong.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: gateway-kong
{{- end }}

{{- define "gateway-kong.imagePullSecrets" -}}
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

{{- define "gateway-kong.renderEnv" -}}
{{- toYaml . | nindent 0 -}}
{{- end -}}

{{/*
Resolve gateway image: prefer image.gateway.repository, fallback to global.registry/image.gateway.name
*/}}
{{- define "gateway-kong.gatewayImage" -}}
{{- if .Values.image.gateway.repository -}}
{{ .Values.image.gateway.repository }}:{{ .Values.image.gateway.tag }}
{{- else -}}
{{ .Values.global.registry }}/{{ .Values.image.gateway.name }}:{{ .Values.image.gateway.tag }}
{{- end -}}
{{- end }}

{{/*
Resolve sync image
*/}}
{{- define "gateway-kong.syncImage" -}}
{{- if .Values.image.sync.repository -}}
{{ .Values.image.sync.repository }}:{{ .Values.image.sync.tag }}
{{- else -}}
{{ .Values.global.registry }}/{{ .Values.image.sync.name }}:{{ .Values.image.sync.tag }}
{{- end -}}
{{- end }}

{{/*
Resolve fluent-bit image
*/}}
{{- define "gateway-kong.fluentBitImage" -}}
{{- if .Values.image.fluentBit.repository -}}
{{ .Values.image.fluentBit.repository }}:{{ .Values.image.fluentBit.tag }}
{{- else -}}
{{ .Values.global.registry }}/{{ .Values.image.fluentBit.name }}:{{ .Values.image.fluentBit.tag }}
{{- end -}}
{{- end }}
