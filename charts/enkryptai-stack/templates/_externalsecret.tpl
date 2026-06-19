{{- define "enkryptai.externalsecrets.render" -}}

{{- $globalExternalSecrets := .Values.global.externalSecrets | default dict -}}
{{- $localExternalSecrets := .Values.externalSecrets | default dict -}}

{{- if and ($globalExternalSecrets.enabled | default false) ($localExternalSecrets.enabled | default false) ($localExternalSecrets.secrets) }}
{{- range $secret := $localExternalSecrets.secrets }}
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret

metadata:
  name: {{ required "externalSecrets.secrets[].name is required" $secret.name | quote }}
  namespace: {{ $secret.target.namespace | default $globalExternalSecrets.namespace | default $.Release.Namespace | quote }}
  labels:
    app.kubernetes.io/name: {{ $.Chart.Name }}
    helm.sh/chart: {{ $.Chart.Name }}-{{ $.Chart.Version | replace "+" "_" }}
    app.kubernetes.io/instance: {{ $.Release.Name }}
    app.kubernetes.io/managed-by: {{ $.Release.Service }}
  {{- with $.Values.global.externalSecrets.annotations }}
  annotations:
  {{ toYaml . | nindent 4 }}
  {{- end }}
spec:
  refreshInterval: {{ $secret.refreshInterval | default "15m" | quote }}

  secretStoreRef:
    name: {{ dig "secretStoreRef" "name" $globalExternalSecrets.clusterSecretStore.name $secret | quote }}
    kind: {{ dig "secretStoreRef" "kind" "ClusterSecretStore" $secret | quote }}

  target:
    name: {{ dig "target" "name" $secret.name $secret | quote }}
    creationPolicy: {{ dig "target" "creationPolicy" "Owner" $secret | quote }}
    deletionPolicy: {{ dig "target" "deletionPolicy" "Retain" $secret | quote }}

  {{- with $secret.data }}
  data:
{{ toYaml . | nindent 4 }}
  {{- end }}

  {{- with $secret.dataFrom }}
  dataFrom:
{{ toYaml . | nindent 4 }}
  {{- end }}

  {{- with $secret.template }}
  template:
{{ toYaml . | nindent 4 }}
  {{- end }}

{{- end }}
{{- end }}

{{- end -}}
