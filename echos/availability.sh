export API_URL="http://localhost:8080/api"

echo "Verificando distribución de carga entre instancias:"
for i in {1..10}; do
    UPSTREAM=$(curl -s -I ${API_URL}/health | grep -i "x-upstream-server" | cut -d' ' -f2)
    echo "Request $i manejado por: $UPSTREAM"
    sleep 0.2
done