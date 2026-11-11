{{/*
Trusted CA from global.trustedCA (docs/trusted-ca.md). Each helper takes the root context and
renders list items, or nothing when configMapName is empty. The CA uses envFrom, volumeMounts and
volumes only; the outbound proxy owns env, so the two never edit the same lines.
*/}}
{{- define "enkryptai-stack.trustedCA.envFrom" -}}
{{- if ((.Values.global).trustedCA).configMapName }}
- configMapRef:
    name: {{ .Release.Name }}-trusted-ca-env
{{- end }}
{{- end }}

{{- define "enkryptai-stack.trustedCA.volumeMount" -}}
{{- if ((.Values.global).trustedCA).configMapName }}
- name: trusted-ca
  mountPath: /etc/enkryptai/trusted-ca
  readOnly: true
{{- end }}
{{- end }}

{{- define "enkryptai-stack.trustedCA.volume" -}}
{{- with ((.Values.global).trustedCA).configMapName }}
- name: trusted-ca
  configMap:
    name: {{ . }}
    items:
      - key: {{ $.Values.global.trustedCA.key | default "ca.crt" }}
        path: ca.crt
{{- end }}
{{- end }}
