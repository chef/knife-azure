<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

# knife-azure 1.3.0 doc changes:

### `-j` option for bootstrap
The `knife-azure` documentation for the `knife azure server create` command
should be updated to include the following option:

    -j JSON_ATTRIBS, --json-attributes JSON_ATTRIBS

This is a JSON string that is added to the first run of a chef-client with the
same meaning as the documentation for the
[`knife bootstrap`](http://docs.getchef.com/knife_bootstrap.html) command.



