export API_URL="http://localhost:8080/api"

echo "Probando rate limiting en registro (5 por minuto):"
for i in {1..100}; do
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST ${API_URL}/register \
        -H "Content-Type: application/json" \
        -d "{\"username\": \"test${i}\", \"password\": \"pass123\"}")
    echo "Register attempt $i: HTTP $HTTP_STATUS"
    
    if [ "$HTTP_STATUS" = "429" ]; then
        echo "Rate limiting en registro activado!"
        break
    fi
    sleep 0.1
done