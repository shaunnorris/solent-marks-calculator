#!/bin/bash
# Security scanning script for Docker images
# Runs multiple security scanners to identify vulnerabilities

set -e

IMAGE_NAME="solent-marks-calculator:latest"
REPORT_DIR="security-reports"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           Docker Security Scanning Suite                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Create reports directory
mkdir -p $REPORT_DIR

# Build image first
echo "📦 Building image..."
docker build -t $IMAGE_NAME .
echo ""

# 1. TRIVY - Comprehensive vulnerability scanner (RECOMMENDED)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 1. Running Trivy (Vulnerability Scanner)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v trivy &> /dev/null; then
    trivy image --severity HIGH,CRITICAL $IMAGE_NAME
    trivy image --format json --output $REPORT_DIR/trivy-report.json $IMAGE_NAME
    echo "✅ Trivy scan complete. Report: $REPORT_DIR/trivy-report.json"
else
    echo "⚠️  Trivy not installed. Install with:"
    echo "   curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin"
fi
echo ""

# 2. DOCKER SCOUT - Built into Docker
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 2. Running Docker Scout..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if docker scout version &> /dev/null; then
    docker scout cves $IMAGE_NAME
    echo "✅ Docker Scout scan complete"
else
    echo "⚠️  Docker Scout not available (requires Docker Desktop or plugin)"
fi
echo ""

# 3. GRYPE - Vulnerability scanner by Anchore
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 3. Running Grype..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v grype &> /dev/null; then
    grype $IMAGE_NAME --only-fixed
    grype $IMAGE_NAME -o json --file $REPORT_DIR/grype-report.json
    echo "✅ Grype scan complete. Report: $REPORT_DIR/grype-report.json"
else
    echo "⚠️  Grype not installed. Install with:"
    echo "   curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin"
fi
echo ""

# 4. HADOLINT - Dockerfile linter
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 4. Running Hadolint (Dockerfile Linter)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v hadolint &> /dev/null; then
    hadolint Dockerfile | tee $REPORT_DIR/hadolint-report.txt || true
    echo "✅ Hadolint scan complete. Report: $REPORT_DIR/hadolint-report.txt"
else
    echo "⚠️  Hadolint not installed. Install with:"
    echo "   wget -O /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64"
    echo "   chmod +x /usr/local/bin/hadolint"
fi
echo ""

# 5. DOCKLE - Container image linter
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 5. Running Dockle (Image Linter)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v dockle &> /dev/null; then
    dockle --exit-code 0 $IMAGE_NAME | tee $REPORT_DIR/dockle-report.txt
    echo "✅ Dockle scan complete. Report: $REPORT_DIR/dockle-report.txt"
else
    echo "⚠️  Dockle not installed. Install with:"
    echo "   curl -L https://github.com/goodwithtech/dockle/releases/latest/download/dockle_Linux-64bit.tar.gz | tar xz"
    echo "   sudo mv dockle /usr/local/bin"
fi
echo ""

# 6. SNYK - Vulnerability scanner (requires account but has free tier)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 6. Running Snyk (optional - requires login)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v snyk &> /dev/null; then
    if snyk auth &> /dev/null; then
        snyk container test $IMAGE_NAME --json-file-output=$REPORT_DIR/snyk-report.json || true
        echo "✅ Snyk scan complete. Report: $REPORT_DIR/snyk-report.json"
    else
        echo "⚠️  Snyk not authenticated. Run: snyk auth"
    fi
else
    echo "⚠️  Snyk not installed (optional). Install with:"
    echo "   npm install -g snyk"
fi
echo ""

# Summary
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    Scan Summary                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Reports saved in: $REPORT_DIR/"
ls -lh $REPORT_DIR/
echo ""
echo "📋 Recommendations:"
echo "  1. Review HIGH and CRITICAL vulnerabilities first"
echo "  2. Update base image if vulnerabilities found: python:3.12-slim"
echo "  3. Check for outdated Python packages in requirements.txt"
echo "  4. Run scans regularly (integrate into CI/CD)"
echo ""


