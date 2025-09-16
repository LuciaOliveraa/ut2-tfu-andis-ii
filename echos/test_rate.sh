export API_URL="http://localhost:8080/api"
export TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmcmVzaCI6ZmFsc2UsImlhdCI6MTc1Nzk3NTAxNSwianRpIjoiNTQxZjJlYmUtYjQxZC00MzQ0LWJiMzItNmQ4ZjU1ZmJhN2M2IiwidHlwZSI6ImFjY2VzcyIsInN1YiI6ImRlbW9BREEyIiwibmJmIjoxNzU3OTc1MDE1LCJleHAiOjE3NTc5Nzg2MTV9.pSUQookVsDbhpn1w0IsuHdEBdjzbenby1C1EuWQn8c4"

echo "Probando rate limiting - haciendo requests rápidas:"
for i in {1..60}; do
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        -X GET "${API_URL}/orders" \
        -H "Authorization: Bearer ${TOKEN}")
    echo "Request $i: HTTP $HTTP_STATUS"
    if [ "$HTTP_STATUS" = "429" ]; then
        echo "Rate limiting activado!"
        break
    fi
    sleep 0.1
done