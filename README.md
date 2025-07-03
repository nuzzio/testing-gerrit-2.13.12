# Gerrit 2.13.12 Webhook Setup Guide

This guide provides step-by-step instructions to set up a local Gerrit 2.13.12 instance with working webhooks using Docker.

## Prerequisites

- Docker and Docker Compose
- Git
- Python 3 (for webhook listener)
- curl

## Step 1: Initial Setup

### 1.1 Run the setup script
```bash
./setup.sh
```

This will:
- Download the webhooks plugin
- Start the Gerrit Docker container
- Wait for Gerrit to be ready
- Install the webhooks plugin
- Restart Gerrit to load the plugin

## Step 2: Configure Gerrit

### 2.1 Access Gerrit UI
Open http://localhost:8080 in your browser

### 2.2 Register a user account

Click "Become" in upper right

Click "New Account" under Register

Enter the same email you use for Git commits

Enter Full Name

Save changes

Click "Select Username"

enter a username

click "Continue"




### 2.3 Generate HTTP password
1. Click your username (top right) → Settings
2. Click "HTTP Password" in the left menu
3. Click "Generate Password"
4. **Save this password** - you'll need it for Git operations




### 2.4 Set up Administrator access

Click your username (top right) → Switch Account
Choose "Administrator"

3. Go to People → List Groups → Administrators
4. Add your user to the Administrators group

### 2.5 Set Require Change-Id in commit message to False
1. Go to Projects → List → All-Projects
2. Set Require Change-Id in commit message to False
3. Save changes

### 2.6 Configure All-Projects permissions
2. While in All-Projects - Click Access
4. Ensure Administrators group has Push permission

## Step 3: Enable Git Authentication

### 3.1 Update Gerrit configuration
```bash
docker exec -it $(docker-compose ps -q gerrit) vi /var/gerrit/etc/gerrit.config
```

Add under the `[auth]` section:
```ini
gitBasicAuthPolicy = HTTP
```

### 3.2 Restart Gerrit
```bash
docker-compose restart gerrit
```

## Step 4: Configure Webhooks

### 4.1 Clone All-Projects with authentication

Note: you may need to retry git clone a few times to be prompted for credentials.

```bash
cd checkouts
git clone http://localhost:8080/a/All-Projects
```

When prompted:
- Username: Your Gerrit username
- Password: Your HTTP password (from Step 2.3)

```bash
cd All-Projects
```

### 4.2 Fetch meta/config branch
```bash
git fetch origin refs/meta/config:refs/meta/config
git checkout refs/meta/config
```

### 4.3 Create webhooks configuration
Create `webhooks.config` file:
```bash
vi webhooks.config
```

Add the following content:
```ini
[remote "webhook-listener"]
  url = http://host.docker.internal:8001/gerrit
  event = project-created
  event = change-merged
  connectionTimeout = 5000
  socketTimeout = 5000
  maxTries = 3
  retryInterval = 1000
  sslVerify = false
```

### 4.4 Commit and push for review
```bash
git add webhooks.config
git commit -m "Configure webhooks for All-Projects"
git push origin HEAD:refs/for/refs/meta/config
```

### 4.5 Review and merge the change
1. Go to Gerrit UI 
2. Click on "My" → "Changes"
3. Find your change (it will be for refs/meta/config)
4. Review and give it +2
5. Click Submit to merge

### 4.6 Restart Gerrit
```bash
docker-compose restart gerrit
```

## Step 5: Test Webhooks

### 5.1 Start the webhook listener
In a new terminal:
```bash
python3 webhook-listener.py
```

You should see:
```
Webhook listener started on port 8001
URL: http://localhost:8001
```

### 5.2 Create a test project
1. In Gerrit UI, go to Projects → Create New Project
2. Create a project called "test-webhook"
3. Check "Access" - it should inherit from All-Projects

### 5.3 Clone and test
```bash
cd checkouts
git clone http://localhost:8080/test-webhook
cd test-webhook
# if no master branch, create one
git branch -m master

# Create a test file
echo "webhook test" > test.txt
git add test.txt
git commit -m "Test webhook trigger"

# Push for review
git push origin HEAD:refs/for/master
```

### 5.4 Review and merge the change
1. Go to Gerrit UI
2. Click on "My" → "Changes"
3. Find your change in "test-webhook"
4. Review and give it +2
5. Click Submit to merge

### 5.5 Verify webhook fired
Check the webhook listener terminal. You should see the webhook payload with event details.

## Webhook Events

The configured events will trigger webhooks:
- `project-created` - New project created in Gerrit
- `change-merged` - Code merged to branch

## Troubleshooting

### Check webhook plugin is loaded
```bash
docker logs $(docker-compose ps -q gerrit) | grep -i "Loaded plugin webhooks"
```

### Test webhook connectivity
```bash
docker exec $(docker-compose ps -q gerrit) \
  curl -X POST http://host.docker.internal:8001/test \
  -H "Content-Type: application/json" \
  -d '{"test": "from container"}'
```

### View Gerrit logs
```bash
docker-compose logs -f gerrit
```

### Common issues
1. **Authentication errors**: Make sure you're using the HTTP password, not your regular password
2. **Webhooks not firing**: Ensure webhooks.config is in refs/meta/config and merged
3. **Permission denied**: Check that your user is in the Administrators group
4. **Port conflicts**: The webhook listener uses port 8001 by default

## Clean Up

To completely reset and start over:
```bash
docker-compose down -v
rm webhooks.jar
rm -rf checkouts/All-Projects checkouts/test-webhook
```


### REF
- https://gerrit-releases.storage.googleapis.com/index.html
- https://gerrit-documentation.storage.googleapis.com/Documentation/2.13.12/index.html
- https://github.com/GerritCodeReview/docker-gerrit
- https://github.com/nuzzio/gerrit-webhooks-plugin-builder/releases/download/2.13.12/webhooks-2.13.12.jar

