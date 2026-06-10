{{/*
Common helpers for the mantle-node chart.
*/}}

{{- define "mantle-node.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mantle-node.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "mantle-node.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mantle-node.labels" -}}
helm.sh/chart: {{ include "mantle-node.chart" . }}
{{ include "mantle-node.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.network }}
mantle.xyz/network: {{ .Values.network }}
{{- end }}
{{- end -}}

{{- define "mantle-node.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mantle-node.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "mantle-node.l2.name" -}}
{{- printf "%s-l2" (include "mantle-node.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mantle-node.l2.labels" -}}
{{ include "mantle-node.labels" . }}
app.kubernetes.io/component: l2-client
mantle.xyz/l2-kind: {{ .Values.l2.kind }}
{{- end -}}

{{- define "mantle-node.l2.selectorLabels" -}}
{{ include "mantle-node.selectorLabels" . }}
app.kubernetes.io/component: l2-client
{{- end -}}

{{- define "mantle-node.opNode.name" -}}
{{- printf "%s-op-node" (include "mantle-node.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mantle-node.opNode.labels" -}}
{{ include "mantle-node.labels" . }}
app.kubernetes.io/component: op-node
{{- end -}}

{{- define "mantle-node.opNode.selectorLabels" -}}
{{ include "mantle-node.selectorLabels" . }}
app.kubernetes.io/component: op-node
{{- end -}}

{{- define "mantle-node.secretName" -}}
{{- printf "%s-secrets" (include "mantle-node.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mantle-node.configScriptsName" -}}
{{- printf "%s-init-scripts" (include "mantle-node.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mantle-node.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "mantle-node.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Resolve a value for jwtSecret / p2pNodeKey:
- if user supplied one, use it
- else, try to look up the existing Secret (so we don't rotate on upgrade)
- else, generate a fresh 32-byte hex string
*/}}
{{- define "mantle-node.jwtSecret" -}}
{{- if .Values.secrets.jwtSecret -}}
{{- .Values.secrets.jwtSecret -}}
{{- else -}}
{{- $existing := lookup "v1" "Secret" .Release.Namespace (include "mantle-node.secretName" .) -}}
{{- if and $existing $existing.data (index $existing.data "jwt_secret_txt") -}}
{{- index $existing.data "jwt_secret_txt" | b64dec -}}
{{- else -}}
{{- randAlphaNum 64 | lower -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "mantle-node.p2pNodeKey" -}}
{{- if .Values.secrets.p2pNodeKey -}}
{{- .Values.secrets.p2pNodeKey -}}
{{- else -}}
{{- $existing := lookup "v1" "Secret" .Release.Namespace (include "mantle-node.secretName" .) -}}
{{- if and $existing $existing.data (index $existing.data "p2p_node_key_txt") -}}
{{- index $existing.data "p2p_node_key_txt" | b64dec -}}
{{- else -}}
{{- randAlphaNum 64 | lower -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Compute the genesis.json source URL. Returns the explicit `config.genesisUrl`
when set, otherwise builds a raw.githubusercontent.com URL from
`config.source.{repo,ref,subdir}`.
*/}}
{{- define "mantle-node.genesisUrl" -}}
{{- if .Values.config.genesisUrl -}}
{{- .Values.config.genesisUrl -}}
{{- else -}}
{{- printf "https://raw.githubusercontent.com/%s/%s/%s/genesis.json" .Values.config.source.repo .Values.config.source.ref .Values.config.source.subdir -}}
{{- end -}}
{{- end -}}

{{- define "mantle-node.rollupUrl" -}}
{{- if .Values.config.rollupUrl -}}
{{- .Values.config.rollupUrl -}}
{{- else -}}
{{- printf "https://raw.githubusercontent.com/%s/%s/%s/rollup.json" .Values.config.source.repo .Values.config.source.ref .Values.config.source.subdir -}}
{{- end -}}
{{- end -}}
