# =============================================================
#  Weather App - ArgoCD Deploy Script
#  Usage: .\deploy.ps1
#         .\deploy.ps1 -ApiKey "YOUR_KEY"
# =============================================================

param(
    [Parameter(Mandatory = $false)]
    [string]$ApiKey = "46121827ef30b0ae1fd0bf5cc6e29b53",

    [Parameter(Mandatory = $false)]
    [string]$Namespace = "weather",

    [Parameter(Mandatory = $false)]
    [int]$FrontendNodePort = 30080,

    [Parameter(Mandatory = $false)]
    [int]$SyncTimeoutSeconds = 300
)

$HELM_BASE       = "$PSScriptRoot\infra\weather-helm-infra\charts"
$ARGOCD_DIR      = "$PSScriptRoot\infra\weather-helm-infra\argocd"
$BACKEND_VALUES  = "$HELM_BASE\weather-backend\values.yaml"
$FRONTEND_VALUES = "$HELM_BASE\weather-frontend\values.yaml"
$ARGOCD_INSTALL  = "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
$ARGOCD_PORT     = 8080
$APP_PORT        = 8081
$ErrorActionPreference = "Continue"

# ---------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------

function Log-Step {
    param([string]$msg)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  $msg" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Assert-Ok {
    param([string]$context)
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[FATAL] $context failed (exit code $LASTEXITCODE). Aborting." -ForegroundColor Red
        exit 1
    }
}

function Check-Command {
    param([string]$cmd)
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Host "[ERROR] '$cmd' is not installed or not in PATH." -ForegroundColor Red
        exit 1
    }
}

function Get-HelmImageTag {
    param([string]$valuesFile)
    $content = Get-Content $valuesFile | Where-Object { $_ -match '^\s*tag:' }
    if ($content) {
        return ($content -split ':',2)[1].Trim().Trim('"').Trim("'")
    }
    return "unknown"
}

function Get-HelmImageRepo {
    param([string]$valuesFile)
    $content = Get-Content $valuesFile | Where-Object { $_ -match '^\s*repository:' }
    if ($content) {
        return ($content -split ':',2)[1].Trim().Trim('"').Trim("'")
    }
    return "unknown"
}

function Wait-ArgoApp {
    param([string]$AppName, [int]$Timeout)
    $elapsed  = 0
    $interval = 10
    while ($elapsed -lt $Timeout) {
        $syncStatus   = kubectl get application $AppName -n argocd -o "jsonpath={.status.sync.status}" 2>$null
        $healthStatus = kubectl get application $AppName -n argocd -o "jsonpath={.status.health.status}" 2>$null

        if ($syncStatus -eq "Synced" -and $healthStatus -eq "Healthy") {
            Write-Host "[OK] $AppName is Synced + Healthy" -ForegroundColor Green
            return $true
        }

        Write-Host "  Waiting for $AppName ... sync=$syncStatus health=$healthStatus (${elapsed}s/${Timeout}s)" -ForegroundColor Gray
        Start-Sleep -Seconds $interval
        $elapsed += $interval
    }
    Write-Host "[WARN] $AppName did not reach Synced+Healthy within ${Timeout}s" -ForegroundColor Yellow
    return $false
}

# ---------------------------------------------------------------
# Read image versions from values.yaml
# ---------------------------------------------------------------

$BackendRepo  = Get-HelmImageRepo  $BACKEND_VALUES
$BackendTag   = Get-HelmImageTag   $BACKEND_VALUES
$FrontendRepo = Get-HelmImageRepo  $FRONTEND_VALUES
$FrontendTag  = Get-HelmImageTag   $FRONTEND_VALUES

# ---------------------------------------------------------------
# Deployment version banner
# ---------------------------------------------------------------

Write-Host ""
Write-Host "+--------------------------------------------------+" -ForegroundColor Magenta
Write-Host "  WEATHER APP DEPLOYMENT (ArgoCD)"                    -ForegroundColor Magenta
Write-Host "+--------------------------------------------------+" -ForegroundColor Magenta
Write-Host "  Namespace  : $Namespace"                           -ForegroundColor White
Write-Host "  Backend    : ${BackendRepo}:${BackendTag}"         -ForegroundColor White
Write-Host "  Frontend   : ${FrontendRepo}:${FrontendTag}"       -ForegroundColor White
Write-Host "  App port   : localhost:$APP_PORT"                  -ForegroundColor White
Write-Host "  Deploy via : ArgoCD (GitOps)"                      -ForegroundColor White
Write-Host "+--------------------------------------------------+" -ForegroundColor Magenta
Write-Host ""

# ---------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------

Log-Step "Pre-flight checks"
Check-Command "minikube"
Check-Command "kubectl"
Check-Command "helm"
Write-Host "[OK] All required tools found." -ForegroundColor Green

# ---------------------------------------------------------------
# Step 1: Clean-delete Minikube profile
# ---------------------------------------------------------------

Log-Step "Step 1: Deleting existing Minikube profile (clean slate)"
minikube delete 2>$null
Write-Host "[OK] Old Minikube profile deleted (or was not running)." -ForegroundColor Green

# ---------------------------------------------------------------
# Step 2: Start Minikube fresh with docker driver
# ---------------------------------------------------------------

Log-Step "Step 2: Starting Minikube (4 CPUs, 4 GB RAM, docker driver)"
minikube start --cpus=4 --memory=4096 --driver=docker
Assert-Ok "minikube start"
Write-Host "[OK] Minikube started successfully." -ForegroundColor Green

# Verify API server is reachable before proceeding
Write-Host "  Verifying cluster connectivity..." -ForegroundColor Gray
kubectl cluster-info 2>$null | Out-Null
Assert-Ok "kubectl cluster-info"
Write-Host "[OK] Cluster is reachable." -ForegroundColor Green

# ---------------------------------------------------------------
# Step 3: Create weather namespace
# ---------------------------------------------------------------

Log-Step "Step 3: Creating namespace '$Namespace'"
kubectl get namespace $Namespace 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "[SKIP] Namespace '$Namespace' already exists." -ForegroundColor Yellow
} else {
    kubectl create namespace $Namespace
    Assert-Ok "kubectl create namespace $Namespace"
    Write-Host "[OK] Namespace '$Namespace' created." -ForegroundColor Green
}

# ---------------------------------------------------------------
# Step 4: Create API Key Secret
# ---------------------------------------------------------------

Log-Step "Step 4: Creating OpenWeather API key secret in '$Namespace'"
kubectl get secret weather-backend-secret -n $Namespace 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "[INFO] Secret already exists -- deleting and recreating." -ForegroundColor Yellow
    kubectl delete secret weather-backend-secret -n $Namespace
    Assert-Ok "kubectl delete secret"
}
kubectl create secret generic weather-backend-secret `
    --from-literal=OPENWEATHER_API_KEY=$ApiKey `
    -n $Namespace
Assert-Ok "kubectl create secret"
Write-Host "[OK] Secret created." -ForegroundColor Green

# ---------------------------------------------------------------
# Step 5: Install ArgoCD
# ---------------------------------------------------------------

Log-Step "Step 5: Installing ArgoCD"
kubectl get namespace argocd 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    kubectl create namespace argocd
    Assert-Ok "kubectl create namespace argocd"
}
kubectl apply --server-side -n argocd -f $ARGOCD_INSTALL
Assert-Ok "kubectl apply ArgoCD install"
Write-Host "[OK] ArgoCD manifests applied." -ForegroundColor Green

# ---------------------------------------------------------------
# Step 6: Wait for ArgoCD to be ready
# ---------------------------------------------------------------

Log-Step "Step 6: Waiting for ArgoCD to be ready (up to 180s)"

kubectl wait deployment argocd-server `
    -n argocd `
    --for=condition=Available `
    --timeout=180s
Assert-Ok "kubectl wait argocd-server"

kubectl wait deployment argocd-repo-server `
    -n argocd `
    --for=condition=Available `
    --timeout=120s
Assert-Ok "kubectl wait argocd-repo-server"

# argocd-application-controller is a StatefulSet — wait for it separately
kubectl wait statefulset argocd-application-controller `
    -n argocd `
    --for=jsonpath='{.status.readyReplicas}'=1 `
    --timeout=120s 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [INFO] Waiting extra 30s for application-controller to be ready..." -ForegroundColor Gray
    Start-Sleep -Seconds 30
}

Write-Host "[OK] ArgoCD is ready." -ForegroundColor Green

# ---------------------------------------------------------------
# Step 7: Apply ArgoCD Application YAMLs
# ---------------------------------------------------------------

Log-Step "Step 7: Applying ArgoCD Application manifests"

Write-Host "  Applying namespace.yaml ..." -ForegroundColor Gray
kubectl apply -f "$ARGOCD_DIR\namespace.yaml"
Assert-Ok "kubectl apply namespace.yaml"

Write-Host "  Applying backend-app.yaml ..." -ForegroundColor Gray
kubectl apply -f "$ARGOCD_DIR\backend-app.yaml"
Assert-Ok "kubectl apply backend-app.yaml"

Write-Host "  Applying frontend-app.yaml ..." -ForegroundColor Gray
kubectl apply -f "$ARGOCD_DIR\frontend-app.yaml"
Assert-Ok "kubectl apply frontend-app.yaml"

Write-Host "  Applying root-app.yaml ..." -ForegroundColor Gray
kubectl apply -f "$ARGOCD_DIR\root-app.yaml"
Assert-Ok "kubectl apply root-app.yaml"

Write-Host "[OK] ArgoCD Applications created." -ForegroundColor Green

# ---------------------------------------------------------------
# Step 8: Wait for ArgoCD apps to sync
# ---------------------------------------------------------------

Log-Step "Step 8: Waiting for ArgoCD apps to sync (up to ${SyncTimeoutSeconds}s)"

$backendOk  = Wait-ArgoApp -AppName "weather-backend"  -Timeout $SyncTimeoutSeconds
$frontendOk = Wait-ArgoApp -AppName "weather-frontend" -Timeout $SyncTimeoutSeconds

if ($backendOk -and $frontendOk) {
    Write-Host "[OK] All ArgoCD apps are Synced + Healthy." -ForegroundColor Green
} else {
    Write-Host "[WARN] Some apps may not be fully synced. Check ArgoCD dashboard." -ForegroundColor Yellow
}

# ---------------------------------------------------------------
# Step 9: Install Prometheus + Grafana (kube-prometheus-stack)
# ---------------------------------------------------------------

Log-Step "Step 9: Installing Prometheus + Grafana (kube-prometheus-stack)"

$MONITORING_NS = "monitoring"
$PROM_RELEASE  = "kube-prom-stack"
$GRAFANA_PORT  = 3000

kubectl get namespace $MONITORING_NS 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    kubectl create namespace $MONITORING_NS
    Assert-Ok "kubectl create namespace $MONITORING_NS"
    Write-Host "[OK] Namespace '$MONITORING_NS' created." -ForegroundColor Green
}

Write-Host "  Adding prometheus-community helm repo ..." -ForegroundColor Gray
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>$null
helm repo update prometheus-community 2>$null
Assert-Ok "helm repo add"

Write-Host "  Installing kube-prometheus-stack (minimal resources for 4GB Minikube) ..." -ForegroundColor Gray
helm upgrade --install $PROM_RELEASE prometheus-community/kube-prometheus-stack `
    -n $MONITORING_NS `
    --set prometheus.prometheusSpec.retention=7d `
    --set prometheus.prometheusSpec.resources.requests.memory=384Mi `
    --set grafana.persistence.enabled=false `
    --set alertmanager.enabled=false `
    --wait `
    --timeout 5m 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARN] kube-prometheus-stack install/upgrade had issues. Continuing..." -ForegroundColor Yellow
} else {
    Write-Host "[OK] Prometheus + Grafana installed." -ForegroundColor Green
}

Write-Host "  Waiting for Grafana deployment ..." -ForegroundColor Gray
kubectl wait deployment ${PROM_RELEASE}-grafana `
    -n $MONITORING_NS `
    --for=condition=Available `
    --timeout=120s 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [INFO] Grafana may still be starting. Port-forward will work when ready." -ForegroundColor Gray
}

# Install Loki (log aggregation) - lightweight single-binary mode
$LOKI_RELEASE = "loki"
$LOKI_PORT    = 3100
Write-Host "  Adding grafana helm repo for Loki ..." -ForegroundColor Gray
helm repo add grafana https://grafana.github.io/helm-charts 2>$null
helm repo update grafana 2>$null

Write-Host "  Installing Loki 3.x (single-binary, no cache) ..." -ForegroundColor Gray
helm upgrade --install $LOKI_RELEASE grafana/loki `
    -n $MONITORING_NS `
    --set loki.auth_enabled=false `
    --set loki.commonConfig.replication_factor=1 `
    --set loki.storage.type=filesystem `
    --set singleBinary.replicas=1 `
    --set write.replicas=0 `
    --set read.replicas=0 `
    --set backend.replicas=0 `
    --set loki.useTestSchema=true `
    --set chunksCache.enabled=false `
    --set resultsCache.enabled=false `
    --set lokiCanary.enabled=false `
    --set test.enabled=false `
    --set singleBinary.resources.requests.memory=128Mi `
    --set singleBinary.resources.limits.memory=256Mi `
    --wait --timeout 5m 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARN] Loki install had issues. Continuing..." -ForegroundColor Yellow
} else {
    Write-Host "[OK] Loki installed." -ForegroundColor Green
}

Write-Host "  Installing Promtail (log collector) ..." -ForegroundColor Gray
helm upgrade --install promtail grafana/promtail `
    -n $MONITORING_NS `
    --set "config.clients[0].url=http://loki-gateway.monitoring.svc.cluster.local/loki/api/v1/push" `
    --wait --timeout 3m 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARN] Promtail install had issues. Continuing..." -ForegroundColor Yellow
} else {
    Write-Host "[OK] Promtail installed (log collector)." -ForegroundColor Green
}

# ---------------------------------------------------------------
# Step 10: Print cluster status
# ---------------------------------------------------------------

Log-Step "Step 10: Deployment Status"
Write-Host ""
Write-Host "--- ArgoCD Applications ---" -ForegroundColor Cyan
kubectl get applications -n argocd
Write-Host ""
Write-Host "--- Pods in '$Namespace' ---" -ForegroundColor Cyan
kubectl get pods -n $Namespace
Write-Host ""
Write-Host "--- Services in '$Namespace' ---" -ForegroundColor Cyan
kubectl get svc -n $Namespace

# ---------------------------------------------------------------
# Step 11: Start port-forwards + open browser
# ---------------------------------------------------------------

Log-Step "Step 11: Starting port-forwards"

# Decode ArgoCD admin password
$ARGOCD_PASS = kubectl -n argocd get secret argocd-initial-admin-secret `
    -o jsonpath="{.data.password}" 2>$null
if ($ARGOCD_PASS) {
    $bytes       = [System.Convert]::FromBase64String($ARGOCD_PASS)
    $ARGOCD_PASS = [System.Text.Encoding]::UTF8.GetString($bytes)
}

# Decode Grafana admin password
$GRAFANA_PASS = kubectl -n $MONITORING_NS get secret ${PROM_RELEASE}-grafana `
    -o jsonpath="{.data.admin-password}" 2>$null
if ($GRAFANA_PASS) {
    $bytes         = [System.Convert]::FromBase64String($GRAFANA_PASS)
    $GRAFANA_PASS  = [System.Text.Encoding]::UTF8.GetString($bytes)
}

# ArgoCD port-forward (new window, stays open)
Write-Host "  Starting ArgoCD port-forward on localhost:$ARGOCD_PORT ..." -ForegroundColor Gray
Start-Process powershell -ArgumentList `
    "-NoExit", "-Command", `
    "Write-Host 'ArgoCD port-forward -- keep this window open' -ForegroundColor Cyan; kubectl port-forward svc/argocd-server -n argocd ${ARGOCD_PORT}:443"

# App port-forward (new window, stays open)
Write-Host "  Starting app port-forward on localhost:$APP_PORT ..." -ForegroundColor Gray
Start-Process powershell -ArgumentList `
    "-NoExit", "-Command", `
    "Write-Host 'App port-forward -- keep this window open' -ForegroundColor Cyan; kubectl port-forward svc/weather-frontend -n $Namespace ${APP_PORT}:80"

# Grafana port-forward (new window, stays open)
Write-Host "  Starting Grafana port-forward on localhost:$GRAFANA_PORT ..." -ForegroundColor Gray
Start-Process powershell -ArgumentList `
    "-NoExit", "-Command", `
    "Write-Host 'Grafana port-forward -- keep this window open' -ForegroundColor Cyan; kubectl port-forward svc/${PROM_RELEASE}-grafana -n $MONITORING_NS ${GRAFANA_PORT}:80"


# Wait briefly for port-forwards to bind
Start-Sleep -Seconds 4

$APP_URL = "http://localhost:${APP_PORT}"

# ---------------------------------------------------------------
# Final banner
# ---------------------------------------------------------------

Write-Host ""
Write-Host "+--------------------------------------------------+" -ForegroundColor Magenta
Write-Host "  DEPLOYMENT COMPLETE"                               -ForegroundColor Magenta
Write-Host "+--------------------------------------------------+" -ForegroundColor Magenta
Write-Host "  Backend    : ${BackendRepo}:${BackendTag}"         -ForegroundColor White
Write-Host "  Frontend   : ${FrontendRepo}:${FrontendTag}"       -ForegroundColor White
Write-Host "  Namespace  : $Namespace"                           -ForegroundColor White
Write-Host "  App URL    : $APP_URL"                             -ForegroundColor Green
Write-Host "+--------------------------------------------------+" -ForegroundColor Magenta
Write-Host "  ArgoCD UI  : https://localhost:$ARGOCD_PORT"       -ForegroundColor Green
Write-Host "  ArgoCD user: admin"                                -ForegroundColor White
if ($ARGOCD_PASS) {
    Write-Host "  ArgoCD pass: $ARGOCD_PASS"                     -ForegroundColor White
} else {
    Write-Host "  ArgoCD pass: (run: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)" -ForegroundColor Yellow
}
Write-Host "  Grafana UI : http://localhost:$GRAFANA_PORT"       -ForegroundColor Green
Write-Host "  Grafana user: admin"                               -ForegroundColor White
if ($GRAFANA_PASS) {
    Write-Host "  Grafana pass: $GRAFANA_PASS"                   -ForegroundColor White
} else {
    Write-Host "  Grafana pass: kubectl -n $MONITORING_NS get secret ${PROM_RELEASE}-grafana -o jsonpath='{.data.admin-password}' | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(`$_)) }" -ForegroundColor Yellow
}
Write-Host "  Loki DS URL: http://loki-gateway.monitoring.svc.cluster.local (add in Grafana -> Connections -> Loki)" -ForegroundColor Green
Write-Host "+--------------------------------------------------+" -ForegroundColor Magenta
Write-Host ""

Start-Process $APP_URL
