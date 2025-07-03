#!/bin/bash

# Gerrit 2.13.12 Setup Script with Webhooks
# This script sets up a local Gerrit instance and downloads the webhooks plugin

echo "==================================="
echo "Gerrit 2.13.12 Setup with Webhooks"
echo "==================================="
echo ""

# Step 1: Download webhooks plugin
echo "Step 1: Downloading webhooks plugin..."
if [ ! -f webhooks.jar ]; then
    curl -L -o webhooks.jar https://github.com/nuzzio/gerrit-webhooks-plugin-builder/releases/download/2.13.12/webhooks-2.13.12.jar
    
    if [ $? -eq 0 ] && [ -f webhooks.jar ]; then
        echo "✓ Successfully downloaded webhooks plugin"
    else
        echo "✗ Failed to download webhooks plugin"
        exit 1
    fi
else
    echo "✓ webhooks.jar already exists"
fi

# Step 2: Start Gerrit container
echo ""
echo "Step 2: Starting Gerrit container..."
docker-compose up -d

if [ $? -eq 0 ]; then
    echo "✓ Gerrit container started"
else
    echo "✗ Failed to start Gerrit container"
    exit 1
fi

# Step 3: Wait for Gerrit to be ready
echo ""
echo "Step 3: Waiting for Gerrit to be ready..."
echo "This may take up to a minute..."

until curl -s http://localhost:8080 > /dev/null 2>&1; do
    echo -n "."
    sleep 5
done
echo ""
echo "✓ Gerrit is running!"

# Step 4: Install webhooks plugin
echo ""
echo "Step 4: Installing webhooks plugin..."
docker cp webhooks.jar $(docker-compose ps -q gerrit):/var/gerrit/plugins/

if [ $? -eq 0 ]; then
    echo "✓ Webhooks plugin copied to container"
else
    echo "✗ Failed to copy webhooks plugin"
    exit 1
fi

# Step 5: Restart Gerrit to load plugin
echo ""
echo "Step 5: Restarting Gerrit to load webhooks plugin..."
docker-compose restart gerrit

# Wait for restart
sleep 10
until curl -s http://localhost:8080 > /dev/null 2>&1; do
    echo -n "."
    sleep 5
done
echo ""
echo "✓ Gerrit restarted successfully"

# Display next steps
echo ""
echo "===================================="
echo "Setup Complete!"
echo "===================================="
echo ""
echo "Gerrit is now running at: http://localhost:8080"
echo ""
echo "Next steps:"
echo "1. Open http://localhost:8080 in your browser"
echo "2. Follow the README.md guide starting from Step 2"
echo ""
echo "To start the webhook listener:"
echo "  python3 webhook-listener.py"
echo ""
echo "Webhook URL for configuration:"
echo "  http://host.docker.internal:8001/gerrit"
echo ""