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

{{- define "mantle-node.el.name" -}}
{{- printf "%s-el" (include "mantle-node.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mantle-node.el.labels" -}}
{{ include "mantle-node.labels" . }}
app.kubernetes.io/component: execution-layer
mantle.xyz/el-kind: {{ .Values.el.kind }}
{{- end -}}

{{- define "mantle-node.el.selectorLabels" -}}
{{ include "mantle-node.selectorLabels" . }}
app.kubernetes.io/component: execution-layer
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

{{- define "mantle-node.elScriptsName" -}}
{{- printf "%s-el-scripts" (include "mantle-node.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mantle-node.rollupConfigName" -}}
{{- printf "%s-rollup-config" (include "mantle-node.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mantle-node.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "mantle-node.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Resolve jwtSecret / p2pNodeKey — both REQUIRED in the per-network values file.
The chart fails fast if either is missing or empty.
*/}}
{{- define "mantle-node.jwtSecret" -}}
{{- required "secrets.jwtSecret is required (set it in the per-network values file as a 32-byte hex string)" .Values.secrets.jwtSecret -}}
{{- end -}}

{{- define "mantle-node.p2pNodeKey" -}}
{{- required "secrets.p2pNodeKey is required (set it in the per-network values file as a 32-byte hex string)" .Values.secrets.p2pNodeKey -}}
{{- end -}}
