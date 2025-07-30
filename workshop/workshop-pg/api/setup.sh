#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Setting up Order Management API${NC}"
echo "=================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo -e "${RED}❌ Go is not installed. Please install Go first.${NC}"
    exit 1
fi

echo -e "\n${YELLOW}1. Downloading Go dependencies...${NC}"
go mod tidy
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Dependencies downloaded successfully${NC}"
else
    echo -e "${RED}❌ Failed to download dependencies${NC}"
    exit 1
fi

echo -e "\n${YELLOW}2. Building the application...${NC}"
go build -o bin/order-api main.go
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Application built successfully${NC}"
else
    echo -e "${RED}❌ Failed to build application${NC}"
    exit 1
fi

echo -e "\n${YELLOW}3. Starting PostgreSQL database...${NC}"
docker-compose up -d
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ PostgreSQL started successfully${NC}"
else
    echo -e "${RED}❌ Failed to start PostgreSQL${NC}"
    exit 1
fi

echo -e "\n${YELLOW}4. Waiting for PostgreSQL to be ready...${NC}"
sleep 10

echo -e "\n${YELLOW}5. Running database migrations...${NC}"
# Check if psql is available
if command -v psql &> /dev/null; then
    psql -h localhost -U postgres -d workshop_db -f migrations/001_init.sql
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Database migrations completed successfully${NC}"
    else
        echo -e "${RED}❌ Failed to run migrations${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  psql not found. Running migrations via Docker...${NC}"
    docker exec -i workshop_postgres psql -U postgres -d workshop_db < migrations/001_init.sql
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Database migrations completed successfully${NC}"
    else
        echo -e "${RED}❌ Failed to run migrations${NC}"
        exit 1
    fi
fi

echo -e "\n${YELLOW}6. Creating .env file...${NC}"
if [ ! -f .env ]; then
    cp .env.example .env
    echo -e "${GREEN}✅ .env file created from .env.example${NC}"
else
    echo -e "${YELLOW}⚠️  .env file already exists${NC}"
fi

echo -e "\n${GREEN}🎉 Setup completed successfully!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Start the API server: ${YELLOW}make run${NC} or ${YELLOW}go run main.go${NC}"
echo -e "2. Test the API: ${YELLOW}./test_api.sh${NC}"
echo -e "3. View database: ${YELLOW}make db-shell${NC}"
echo -e "4. View logs: ${YELLOW}make docker-logs${NC}"
echo ""
echo -e "${BLUE}API endpoints will be available at:${NC}"
echo -e "• Health check: ${YELLOW}http://localhost:8080/health${NC}"
echo -e "• Create order: ${YELLOW}POST http://localhost:8080/order${NC}"
echo -e "• Get order: ${YELLOW}GET http://localhost:8080/order/:id${NC}"
echo -e "• Database stats: ${YELLOW}GET http://localhost:8080/db/stats${NC}"
echo ""
echo -e "${BLUE}Database connection:${NC}"
echo -e "• Host: localhost:5432"
echo -e "• Database: workshop_db"
echo -e "• Username: postgres"
echo -e "• Password: password"
