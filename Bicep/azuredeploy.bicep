@description('Resource Name for the IP Group.')
param ipGroupName string

@description('Resource Name for the Logic App.')
param logicAppName string

@description('Location where the resources should be deployed.')
param location string = resourceGroup().location

@description('Tags to apply to all resources.')
param tags object = {}

var logicAppWorkflow = json(loadTextContent('workflow.json'))

resource ipGroup 'Microsoft.Network/ipGroups@2021-05-01' = {
  name: ipGroupName
  location: location
  tags: tags
  properties: {
    ipAddresses: []
  }
}

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: logicAppWorkflow.definition
    parameters: {
      IpGroupResourceId: {
        value: ipGroup.id
      }
    }
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(ipGroup.id, logicApp.id, contributorRoleDefinition.id)
  scope: ipGroup
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: logicApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Existing resource definitions below

@description('This is the built-in Contributor role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#contributor')
resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}
