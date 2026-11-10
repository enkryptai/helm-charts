{{/*
Trusted CA for the red team Workflow pods, from global.trustedCA (docs/trusted-ca.md). Same shape
as enkryptai-stack.trustedCA.*: root context in, list items or nothing out; env is left to the proxy.
*/}}
{{- define "platform.trustedCA.envFrom" -}}
{{- if ((.Values.global).trustedCA).configMapName }}
- configMapRef:
    name: {{ .Release.Name }}-trusted-ca-env
{{- end }}
{{- end }}

{{- define "platform.trustedCA.volumeMount" -}}
{{- if ((.Values.global).trustedCA).configMapName }}
- name: trusted-ca
  mountPath: /etc/enkryptai/trusted-ca
  readOnly: true
{{- end }}
{{- end }}

{{- define "platform.trustedCA.volume" -}}
{{- with ((.Values.global).trustedCA).configMapName }}
- name: trusted-ca
  configMap:
    name: {{ . }}
    items:
      - key: {{ $.Values.global.trustedCA.key | default "ca.crt" }}
        path: ca.crt
{{- end }}
{{- end }}
