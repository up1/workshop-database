#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:8080"

echo -e "${BLUE}🧪 Testing Order Management API${NC}"
echo "=================================="

# Test 1: Health Check
echo -e "\n${YELLOW}1. Testing Health Check...${NC}"
response=$(curl -s -w "HTTP_STATUS:%{http_code}" "$BASE_URL/health")
http_code=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
body=$(echo "$response" | sed -E 's/HTTP_STATUS:[0-9]*$//')

if [ "$http_code" -eq 200 ]; then
    echo -e "${GREEN}✅ Health check passed${NC}"
    echo "$body" | jq .
else
    echo -e "${RED}❌ Health check failed (HTTP $http_code)${NC}"
fi

# Test 2: Create Order
echo -e "\n${YELLOW}2. Testing Create Order...${NC}"
order_payload='{
  "products": [
    {
      "id": 1,
      "name": "iPhone 15 Pro",
      "price": 1199.99,
      "quantity": 1
    },
    {
      "id": 2,
      "name": "AirPods Pro",
      "price": 249.99,
      "quantity": 2
    }
  ],
  "total_price": 1699.97
}'

response=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d "$order_payload" \
  "$BASE_URL/order")

http_code=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
body=$(echo "$response" | sed -E 's/HTTP_STATUS:[0-9]*$//')

if [ "$http_code" -eq 201 ]; then
    echo -e "${GREEN}✅ Order created successfully${NC}"
    echo "$body" | jq .
    
    # Extract order ID for next test
    order_id=$(echo "$body" | jq -r '.data.order_id')
    
    # Test 3: Get Order
    echo -e "\n${YELLOW}3. Testing Get Order (ID: $order_id)...${NC}"
    response=$(curl -s -w "HTTP_STATUS:%{http_code}" "$BASE_URL/order/$order_id")
    http_code=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed -E 's/HTTP_STATUS:[0-9]*$//')
    
    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✅ Order retrieved successfully${NC}"
        echo "$body" | jq .
    else
        echo -e "${RED}❌ Get order failed (HTTP $http_code)${NC}"
        echo "$body"
    fi
    
    # Test 4: Update Order Status
    echo -e "\n${YELLOW}4. Testing Update Order Status...${NC}"
    status_payload='{"status": "success"}'
    
    response=$(curl -s -w "HTTP_STATUS:%{http_code}" \
      -X PATCH \
      -H "Content-Type: application/json" \
      -d "$status_payload" \
      "$BASE_URL/order/$order_id/status")
    
    http_code=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed -E 's/HTTP_STATUS:[0-9]*$//')
    
    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✅ Order status updated successfully${NC}"
        echo "$body" | jq .
        
        # Verify the status update
        echo -e "\n${YELLOW}5. Verifying Status Update...${NC}"
        response=$(curl -s -w "HTTP_STATUS:%{http_code}" "$BASE_URL/order/$order_id")
        http_code=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
        body=$(echo "$response" | sed -E 's/HTTP_STATUS:[0-9]*$//')
        
        if [ "$http_code" -eq 200 ]; then
            status=$(echo "$body" | jq -r '.status')
            if [ "$status" = "success" ]; then
                echo -e "${GREEN}✅ Status successfully updated to 'success'${NC}"
            else
                echo -e "${RED}❌ Status not updated correctly (current: $status)${NC}"
            fi
            echo "$body" | jq .
        fi
    else
        echo -e "${RED}❌ Update order status failed (HTTP $http_code)${NC}"
        echo "$body"
    fi
    
else
    echo -e "${RED}❌ Create order failed (HTTP $http_code)${NC}"
    echo "$body"
fi

# Test 6: Order Statistics
echo -e "\n${YELLOW}6. Testing Order Statistics...${NC}"
response=$(curl -s -w "HTTP_STATUS:%{http_code}" "$BASE_URL/order/stats")
http_code=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
body=$(echo "$response" | sed -E 's/HTTP_STATUS:[0-9]*$//')

if [ "$http_code" -eq 200 ]; then
    echo -e "${GREEN}✅ Order statistics retrieved successfully${NC}"
    echo "$body" | jq .
else
    echo -e "${RED}❌ Order statistics failed (HTTP $http_code)${NC}"
    echo "$body"
fi

# Test 7: Database Statistics
echo -e "\n${YELLOW}7. Testing Database Statistics...${NC}"
response=$(curl -s -w "HTTP_STATUS:%{http_code}" "$BASE_URL/db/stats")
http_code=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
body=$(echo "$response" | sed -E 's/HTTP_STATUS:[0-9]*$//')

if [ "$http_code" -eq 200 ]; then
    echo -e "${GREEN}✅ Database statistics retrieved successfully${NC}"
    echo "$body" | jq .
else
    echo -e "${RED}❌ Database statistics failed (HTTP $http_code)${NC}"
    echo "$body"
fi

# Test 8: Error Handling - Invalid Order ID
echo -e "\n${YELLOW}8. Testing Error Handling (Invalid Order ID)...${NC}"
response=$(curl -s -w "HTTP_STATUS:%{http_code}" "$BASE_URL/order/99999")
http_code=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
body=$(echo "$response" | sed -E 's/HTTP_STATUS:[0-9]*$//')

if [ "$http_code" -eq 404 ]; then
    echo -e "${GREEN}✅ Error handling working correctly (404 for invalid ID)${NC}"
    echo "$body" | jq .
else
    echo -e "${RED}❌ Error handling not working correctly (expected 404, got $http_code)${NC}"
    echo "$body"
fi

echo -e "\n${BLUE}🎉 API testing completed!${NC}"
