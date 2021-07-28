from decouple import config

import azure.core as core
from azure.keyvault.secrets import SecretClient
from azure.identity import DefaultAzureCredential

GITHUB_REPO_OWNER = config('EVENTROUTER_GITHUB_REPO_OWNER', default='')
GITHUB_REPO_NAME = config('EVENTROUTER_GITHUB_REPO_NAME', default='')
GITHUB_LABEL = config('EVENTROUTER_GITHUB_LABEL', default='')
GITHUB_TOKEN = config('EVENTROUTER_GITHUB_TOKEN', default='')

KEY_VAULT_NAME = config('KEY_VAULT_NAME', default='')

# override when using key vault
if KEY_VAULT_NAME != '':
    kv_url = f"https://{KEY_VAULT_NAME}.vault.azure.net"
    credential = DefaultAzureCredential()
    client = SecretClient(vault_url=kv_url, credential=credential)

    try:
        secret = client.get_secret("github-token-create-issue")
        GITHUB_TOKEN = secret.value
    except core.exceptions.HttpResponseError:
        raise
