Data Bags & Vaults
------------------

## Datacenters
Items in the datacenters data bag model the infrastructure of CLC datacenters -- the platform, storage, network topology, VSphere, etc.  Sensitive information in these items is factored into separate data bags that are encrypted and managed using chef-vault.  

By CLC convention, items in this data bag are named _DC_.json.

## Secrets and secrets_qa

The secrets and secrets_qa data bags are used specifically for [chef-vault](https://github.com/Nordstrom/chef-vault) secrets. Vaults intended for use in the clc_qa organization should be stored in secrets_qa. Productin secrets should be stored in secrets. This allows us to namespace secrets so that vaults with the same name but different secrets in QA and production can be source controlled together.

The `["provisioner"]["vault_bag"]` attribute controls which data bag secrets get pulled from at runtime. This attribute is set in the top level environment parent files located in the [clc_library cookbook](https://github.com/Tier3/clc_library/tree/master/files/default/environment_parent).

Within each of these **realms** of QA and production, there are four families of secrets which are currently stored in three separate vaults, but could potentially be split into additional vaults as explained here:

### Application specific secrets

These are secrets that are applicable within an application. An application here is considered to be synonymous with our application scoped chef environments. These secrets should not be shared outside of the chef_environment. They can be stored in one or more vaults, all of which should be defined in:

```
['provisioner']['cluster_vaults']

```

These should be accessed from cookbook recipes using the `clc_secrets` library function defined in the `clc_library` cookbook. That function takes a single string which is the name of the vault being accessed. If no argument is passed, it defaults to the first vault in the `clister_vaults` array.

### Domain Administrator Password

This is the windows active directory domain's admin password. This is only used by two cookbooks. The provisioner uses it to domain join new windows nodes. The Active Directory cookbook uses it for creating primary and secondary domain controllers.

This secret is placed in a vault named `<domain FQDN>_domain`. The FQDN of a domain is set in the attribute:

```
['clc_library']['win_fqdn']
```

This attribute is set in the top level environment parent files located in the clc_library cookbook. The domain admin password should be accessed using the `win_domain_admin_password` method in `clc_library`.

### Local Administrator Password

This is the password of a local administrator used for remote access on a node. They are accesswd by all nodes just aThere are separate attributes for linux and windows:

```
local_root_password
local_admin_password
```

These are kept in a vault whose name is stored in the attribute:

```
['clc_library']['admin_password_vault']
```

This is set in the top level environment parent files located in the clc_library cookbook. Currently this vault name is set to be the same as `['clc_library']['win_fqdn']`. All nodes need to be able to access this secret so that they can set their password from the stock bootstrap password to the local admin password after initial provisioning. These local passwords should be accessed using the `local_password` method in the `clc_library` cookbook. This method takes an optional parameter of `platform` which is used to determine which password to return - windows or linux. If no value is passed, it uses the platform of the current runtime environment.

### Hypervisor secrets

These are used to authenticate with VMWare and are only used by the provisioner. They reside in vaults named `<DC>_secrets`. The provisioner uses the `provisioner_secrets` method in its library to retrieve these secrets.

### Vault Workflow in the Abstract

Cleartext data bag items are simply JSON files which you create and maintain with a text editor.
Vault items are data bags that have been encrypted using the public/private keypairs associated with specific chef clients.

For a chef node to access a vault item, the item must previously have been encrypted using the public client key of the node requesting it.

The basic process for creating and maintaining a vault item is therefore:

1. An existing user within a given chef server organization creates a vault item, specifying:
  * key:value data elements  (Data elements can be specified either on the command line with ```knife vault```, or through a plaintext JSON file.)
  * other users in the organization who can administer the vault item
  * the search query used to find nodes that should be able to access the vault item

2. A new node needing access to the vault is launched, and subsequently joined to the Chef Server organization in which the vault is maintained. That is, its node and client objects are saved within the server.

3. An administrator for the vault item 'refreshes' it, which re-runs the search query that was specified when the item was created.  Assuming the new node matches the stored query, its public key is added to the set that can access the vault.

At any point after the vault item has been created, an administrator can update key:value data elements, the stored search query, and/or the list of authorized administrators.

### Vault Workflow in the Context of CLC

_A human creates a vault item._

_A provisioner launches a cluster node and refreshes a vault item._

_A cluster node reads a vault item._

#### For CI purposes
* A vault item for testing has been pre-created and included in the data_bags/secrets_qa directory.
* The client key used to create the vault item has been exported into the cookbooks/provisioner/test directory.
* The integration tests for the provisioner cookbook (currently for Ubuntu only) uses these pre-created artifacts to validate that a newly launched node is granted access to the vault item for its environment.
