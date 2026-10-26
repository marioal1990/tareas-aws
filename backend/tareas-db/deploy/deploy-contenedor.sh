#!/bin/bash
# ------------------------------------------------------------
# Se ejecuta EN LA EC2 vía SSM (lo envía el pipeline deploy-backend).
# __IMAGEN__ lo reemplaza el pipeline por la imagen a desplegar.
# ------------------------------------------------------------
set -euo pipefail

IMAGEN="__IMAGEN__"
REGISTRO="${IMAGEN%%/*}"
REGION=us-east-2
NOMBRE=tareas-db
HEALTH=http://localhost:8888/tareas-db/api/health
DIR=/opt/tareas-db

# 1) Docker (solo la primera vez)
if ! command -v docker >/dev/null; then
  echo "Instalando Docker..."
  dnf install -y -q docker
  systemctl enable --now docker
fi

# 2) Descargar la imagen desde ECR (credenciales del rol de la EC2)
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRO"
docker pull -q "$IMAGEN"

# 3) Variables de entorno: se reutiliza el app.env del servicio systemd.
#    Docker no entiende "export" ni comillas, así que se limpian.
sed -E 's/^export +//; s/^([A-Za-z_][A-Za-z0-9_]*)="(.*)"$/\1=\2/; s/^([A-Za-z_][A-Za-z0-9_]*)='"'"'(.*)'"'"'$/\1=\2/' \
  "$DIR/app.env" | grep -E '^[A-Za-z_][A-Za-z0-9_]*=' > "$DIR/docker.env"
chmod 600 "$DIR/docker.env"

# 4) Detener la versión actual (contenedor o servicio systemd antiguo)
ANTERIOR=ninguna
docker rm -f "$NOMBRE-anterior" >/dev/null 2>&1 || true
if docker inspect "$NOMBRE" >/dev/null 2>&1; then
  docker stop "$NOMBRE" >/dev/null
  docker rename "$NOMBRE" "$NOMBRE-anterior"
  ANTERIOR=contenedor
fi
SERVICIOS=$(systemctl list-unit-files 'tareas*.service' --no-legend | awk '{print $1}')
for s in $SERVICIOS; do
  if systemctl is-active --quiet "$s"; then ANTERIOR="systemd:$s"; fi
  systemctl disable --now "$s" >/dev/null 2>&1 || true
done
echo "Versión anterior: $ANTERIOR"

# 5) Levantar la nueva versión (los logs van a CloudWatch; "docker logs" sigue funcionando)
docker run -d --name "$NOMBRE" \
  --restart unless-stopped \
  -p 8888:8888 \
  --memory 1g \
  --env-file "$DIR/docker.env" \
  -e SPRING_PROFILES_ACTIVE=aws \
  -e AWS_REGION="$REGION" \
  --log-driver awslogs \
  --log-opt awslogs-region="$REGION" \
  --log-opt awslogs-group=/tareas/backend \
  --log-opt awslogs-stream="$NOMBRE-${IMAGEN##*:}-$(date +%Y%m%d%H%M%S)" \
  "$IMAGEN" >/dev/null

# 6) Esperar a que responda el health (Aurora puede tardar en despertar)
for i in $(seq 1 45); do
  if curl -sf "$HEALTH" >/dev/null; then
    echo "OK: $IMAGEN responde ($(curl -s "$HEALTH"))"
    docker rm -f "$NOMBRE-anterior" >/dev/null 2>&1 || true
    docker image prune -af >/dev/null   # borra imágenes que ya no usa ningún contenedor
    exit 0
  fi
  sleep 4
done

# 7) Falló: mostrar logs y volver a la versión anterior
echo "ERROR: la nueva versión no respondió. Últimos logs:"
docker logs --tail 60 "$NOMBRE" 2>&1 || true
docker rm -f "$NOMBRE" >/dev/null 2>&1 || true
case "$ANTERIOR" in
  contenedor) docker rename "$NOMBRE-anterior" "$NOMBRE" && docker start "$NOMBRE" >/dev/null ;;
  systemd:*)  s="${ANTERIOR#systemd:}"; systemctl enable --now "$s" ;;
esac
echo "Se restauró la versión anterior ($ANTERIOR)"
exit 1
