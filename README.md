# Event Router on Azure Functions for GitHub Issue

## Table of Contents

- [About](#about)
- [Getting Started](#getting_started)

## About <a name = "about"></a>

This function routes event to GitHub Issue. Currently it supports events from Azure Event Grid (Azure Event Grid event schema).

It posts the received event to a GitHub Issue of target repo with "Azure-Event" label. 

<img src="https://github.com/ToruMakabe/az-func-eventrouter-for-gh-issue/blob/main/image/sample_issue.png?raw=true" width="800">

### Use cases

Recognize that as GitHub Issue

* Azure Kubernetes Service cluster upgrade task is required
  * [Notify when there is a change in the available Kubernetes versions](https://docs.microsoft.com/en-us/azure/aks/quickstart-event-grid)
* Container image tag on manifest needs to be updated
  * [Send events from container registry to Event Grid](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-event-grid-quickstart)

## Getting Started <a name = "getting_started"></a>

First, build the platform with Terraform. Then deploy the function in GitHub Actions. Pushing tags with semantic versioning (vx.y.z) will run the deployment workflow.

Creating event-subscription is out of scope of this router. Please refer to [this document](https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-event-grid-trigger?tabs=csharp%2Cbash#create-a-subscription) for that.

### Prerequisites & Tested

* Terraform: 1.0.3
  * hashicorp/azurerm: 2.69
  * integrations/github: 4.12
* Azure Functions
  * Plan: Consumption
  * OS: Linux
  * Runtime: Python 3.8

### Notes

#### Config options and the evaluation order

Each params takes precedence over the item below it. For example, setting an env. var overrides the same parameter in the configuration file.

* Key Vault secret ([settings.py](./app/shared/settings.py))
* env. var
* config file ([settings.ini](./app/shared/settings.ini))
* default in code ([settings.py](./app/shared/settings.py))
