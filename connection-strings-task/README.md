# Azure Authentication

## Option 1: Interactive Login (az login with your user)

This is the easiest when you're just working manually on your VM.

1. On your VM terminal, simply run:

```bash
az login
```

2. It will open a browser window asking you to log in with your Azure Portal account (your normal username/password).
    - NOTE: If no browser, it will give you a code you can enter at https://microsoft.com/devicelogin.

3. Once logged in:
    - Your session is authenticated.
    - You can immediately run Azure CLI commands (like az webapp list, az vm list, etc.)

4. (Optional) If you have multiple subscriptions, you can set the correct one manually:

```bash
az account set --subscription "your-subscription-id"
```

NOTES: 
- ✅ No need to manage secrets
- ✅ Good for manual work


## Option 2: Service Principal Login (Non-Interactive for automation)

This is better if you want fully automated scripts (no manual login needed).

1. Create a Service Principal (only once)

```bash
az ad sp create-for-rbac --name "webapp-management-script" --role contributor --scopes /subscriptions/<your-subscription-id>
```

This will output:

```json
{
  "appId": "xxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "displayName": "webapp-management-script",
  "password": "super-strong-secret",
  "tenant": "xxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

Save this output securely!


2. Export the credentials into your environment

```bash
export AZURE_APP_ID="xxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export AZURE_PASSWORD="super-strong-secret"
export AZURE_TENANT_ID="xxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export AZURE_SUBSCRIPTION_ID="your-subscription-id"
```

3. Login using Service Principal

```bash
az login --service-principal --username "$AZURE_APP_ID" --password "$AZURE_PASSWORD" --tenant "$AZURE_TENANT_ID"
```

4. Set the subscription

```bash
az account set --subscription "$AZURE_SUBSCRIPTION_ID"
```

Now you are authenticated without any user interaction, and your scripts can run headlessly!


