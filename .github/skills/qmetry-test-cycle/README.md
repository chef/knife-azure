# knife-azure e2e tests (QMetry test cycle skill)

Runs a QMetry test cycle against real Azure VMs using the Copilot CLI skill
[`qmetry-test-cycle`](SKILL.md).

## Prerequisites

- Copilot CLI
- knife Habitat package (already bundles the knife-azure plugin):
  `hab pkg install chef/knife --binlink`, then check
  `knife azurerm server create --help` works
- Chef license: `CHEF_LICENSE_KEY` set, or knife already licensed
- Azure subscription and a resource group for the test VMs
- Azure CLI `az`, logged in to the same subscription (used for cleanup)
- QMetry MCP server `qtm4j`: get an API key in Jira (QMetry -> Configuration ->
  Open API), install `@smartbear/mcp` (Node 22+) under
  `~/.copilot/mcp-servers/smartbear-mcp`, merge
  [`mcp-config.template.json`](mcp-config.template.json)
  into `~/.copilot/mcp-config.json`, and restart the CLI

## Connect to Azure

Add the following to your knife config (e.g. `~/.chef/knife.rb`, outside the repo,
or set `KNIFE_CONFIG=/path/to/knife.rb`):

```ruby
knife[:azure_subscription_id] = "<subscription-id>"   # always required
knife[:azure_tenant_id]       = "<tenant-id>"
knife[:azure_client_id]       = "<service-principal-app-id>"
knife[:azure_client_secret]   = "<service-principal-secret>"
```

Create the service principal with:
`az ad sp create-for-rbac --name knife-azure-e2e --role Contributor --scopes /subscriptions/<subscription-id>/resourceGroups/<resource-group>`

Check: `knife azurerm server list -r <resource-group>` runs without an auth error.

## Configuration

```bash
cp test/e2e/config.template.yml test/e2e/config.yml   # git-ignored, never commit
```

In `config.yml` (`linux:` and `windows:` sections), set at least:

- `resource-group-name`: the test resource group
- `connection-password`: your own strong password (replace `<fill-me>`)
- `service-location`, `vm-size`, `image-reference-*`: check they fit your
  subscription and region

Missing values are asked for during the run.

## Run

```bash
copilot --allow-tool 'qtm4j' --allow-tool 'shell(knife)' --allow-tool 'shell(ruby)' \
        --allow-tool 'shell(az)' --allow-tool 'write'
```

Then ask: `run QMetry cycle CHEF-TR-XXXX`.
