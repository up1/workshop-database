package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

const baseURL = "http://localhost:8080"

func main() {
	fmt.Println("🧪 Testing Order API...")
	
	// Wait a moment for server to start
	time.Sleep(2 * time.Second)
	
	// Test health check
	fmt.Println("\n1. Testing Health Check...")
	resp, err := http.Get(baseURL + "/health")
	if err != nil {
		fmt.Printf("❌ Health check failed: %v\n", err)
		return
	}
	defer resp.Body.Close()
	
	if resp.StatusCode == 200 {
		fmt.Println("✅ Health check passed")
	} else {
		fmt.Printf("❌ Health check failed with status: %d\n", resp.StatusCode)
	}
	
	// Test creating an order
	fmt.Println("\n2. Testing Create Order...")
	orderData := map[string]interface{}{
		"products": []map[string]interface{}{
			{
				"id":       1,
				"name":     "iPhone 15",
				"price":    999.99,
				"quantity": 1,
			},
			{
				"id":       2,
				"name":     "AirPods Pro",
				"price":    249.99,
				"quantity": 2,
			},
		},
		"total_price": 1499.97,
	}
	
	jsonData, _ := json.Marshal(orderData)
	resp, err = http.Post(baseURL+"/order", "application/json", bytes.NewBuffer(jsonData))
	if err != nil {
		fmt.Printf("❌ Create order failed: %v\n", err)
		return
	}
	defer resp.Body.Close()
	
	body, _ := io.ReadAll(resp.Body)
	
	if resp.StatusCode == 201 {
		fmt.Println("✅ Order created successfully")
		
		var result map[string]interface{}
		json.Unmarshal(body, &result)
		
		if data, ok := result["data"].(map[string]interface{}); ok {
			if orderID, ok := data["order_id"].(float64); ok {
				// Test getting the order
				fmt.Printf("\n3. Testing Get Order (ID: %.0f)...\n", orderID)
				resp, err = http.Get(fmt.Sprintf("%s/order/%.0f", baseURL, orderID))
				if err != nil {
					fmt.Printf("❌ Get order failed: %v\n", err)
					return
				}
				defer resp.Body.Close()
				
				if resp.StatusCode == 200 {
					fmt.Println("✅ Order retrieved successfully")
					body, _ := io.ReadAll(resp.Body)
					
					var orderResult map[string]interface{}
					json.Unmarshal(body, &orderResult)
					
					prettyJSON, _ := json.MarshalIndent(orderResult, "", "  ")
					fmt.Printf("📋 Order details:\n%s\n", prettyJSON)
				} else {
					fmt.Printf("❌ Get order failed with status: %d\n", resp.StatusCode)
				}
			}
		}
	} else {
		fmt.Printf("❌ Create order failed with status: %d\n", resp.StatusCode)
		fmt.Printf("Response: %s\n", body)
	}
	
	// Test database stats
	fmt.Println("\n4. Testing Database Stats...")
	resp, err = http.Get(baseURL + "/db/stats")
	if err != nil {
		fmt.Printf("❌ Database stats failed: %v\n", err)
		return
	}
	defer resp.Body.Close()
	
	if resp.StatusCode == 200 {
		fmt.Println("✅ Database stats retrieved successfully")
		body, _ := io.ReadAll(resp.Body)
		
		var stats map[string]interface{}
		json.Unmarshal(body, &stats)
		
		prettyJSON, _ := json.MarshalIndent(stats, "", "  ")
		fmt.Printf("📊 Database stats:\n%s\n", prettyJSON)
	} else {
		fmt.Printf("❌ Database stats failed with status: %d\n", resp.StatusCode)
	}
	
	// Test order stats
	fmt.Println("\n5. Testing Order Stats...")
	resp, err = http.Get(baseURL + "/order/stats")
	if err != nil {
		fmt.Printf("❌ Order stats failed: %v\n", err)
		return
	}
	defer resp.Body.Close()
	
	if resp.StatusCode == 200 {
		fmt.Println("✅ Order stats retrieved successfully")
		body, _ := io.ReadAll(resp.Body)
		
		var stats map[string]interface{}
		json.Unmarshal(body, &stats)
		
		prettyJSON, _ := json.MarshalIndent(stats, "", "  ")
		fmt.Printf("📈 Order stats:\n%s\n", prettyJSON)
	} else {
		fmt.Printf("❌ Order stats failed with status: %d\n", resp.StatusCode)
	}
	
	fmt.Println("\n🎉 API testing completed!")
}
