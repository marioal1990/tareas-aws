#!/bin/bash
set -e
BUCKET=tareas-frontend-mario-2026
DIST_ID=EXXXXXXXXXXXXX   # ID de tu distribución (pestaña General)

ng build

# Archivos con hash en el nombre: caché larga (cambian de nombre en cada build)
aws s3 sync dist/frontend/browser s3://$BUCKET --delete \
  --exclude index.html --cache-control "public,max-age=31536000,immutable"

# index.html: sin caché, para que siempre apunte a la última versión
aws s3 cp dist/frontend/browser/index.html s3://$BUCKET/index.html \
  --cache-control "no-cache"

aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"
echo "Desplegado en https://$(aws cloudfront get-distribution --id $DIST_ID \
  --query 'Distribution.DomainName' --output text)"