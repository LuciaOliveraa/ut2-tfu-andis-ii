export API_URL="http://localhost:8080/api"
export TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmcmVzaCI6ZmFsc2UsImlhdCI6MTc1Nzg2NTM3NiwianRpIjoiMTQ3ZDAyNTctNjI0Zi00ZjQwLWI5OTgtODRmOWIwMTZlY2ZlIiwidHlwZSI6ImFjY2VzcyIsInN1YiI6Imx1YW1vcjEyIiwibmJmIjoxNzU3ODY1Mzc2LCJleHAiOjE3NTc4Njg5NzZ9.ela1-D3r3Go2Fn9nyvO1Od0xOn5Db2x2DNWD65jt_h0"

echo "Probando rate limiting - haciendo requests rápidas:"
for i in {1..100}; do
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