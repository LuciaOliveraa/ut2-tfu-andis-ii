export API_URL="http://localhost:8080/api"

echo "Probando disponibilidad con requests concurrentes:"
for i in {1..5}; do
    {
        RESPONSE=$(curl -s -w "Time: %{time_total}s - Status: %{http_code}" \
        -X GET ${API_URL}/health)
        echo "Concurrent request $i - $RESPONSE"
    } &
done
wait