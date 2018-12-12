# Bootstrap examples

## ARM mode

Bootstrap existing Azure ARM VM using following command:

```knife bootstrap azurerm <server> --azure-resource-group-name <resource_group_name> --azure-service-location <location>```

```$ knife bootstrap azurerm myVMName --azure-resource-group-name myResourceGroup --azure-service-location 'westus'```

You can use other options like --azure-dns-name, --bootstrap-version with this command and there are many more options which can be used with this command. Use --help to identify more options.

NOTE: This command only works for single VM bootstrap.

## ASM mode

Bootstrap existing Azure ASM VM using following command:

```knife bootstrap azure <server>```

```$ knife bootstrap azure myVMName```

You can use other options like --azure-dns-name, --bootstrap-version with this command. There are many more options which can be used with this command. Use --help to identify more options.

NOTE: This command only works for single VM bootstrap.
