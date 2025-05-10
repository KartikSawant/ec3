````markdown
# EC3 - Elastic Compute Cloud Companion

This script allows you to manage your AWS EC2 instances using aliases defined in a mapping file. You can start, stop, list, and check the status of instances.

## Problem

To start, stop, or check the status of an EC2 instance that you regularly use, you typically have to go through multiple steps in the AWS Console. This script simplifies that into a single command from your CLI.

## Installation

Please follow the installation steps in [INSTALL.md](./INSTALL.md) to set up the script.

## Usage

```bash
ec3 <start|stop|list|status> [alias] [--update]
````

* `start`: Start the instance associated with the alias.
* `stop`: Stop the instance associated with the alias.
* `list`: List all instances defined in the mapping file.
* `status`: Check the status of the instance associated with the alias.
* `--update`: *(Optional)* When used with `start`, it will wait for the instance to start and update the corresponding entry in your `~/.ssh/config` with the instance's new public IP (if an SSH alias is provided).

## Mapping File

The mapping file (`~/.ec3rc`) should contain lines in one of the following formats:

```
<alias>=<instance_id>:<region>
<alias>=<instance_id>:<region>:<ssh_host_alias>
```

### Example:

```ini
webserver=i-1234567890abcdef:us-west-2
database=i-0987654321fedcba:us-east-1:DB-SERVER
```

* The first two fields are required.
* The optional third field is the SSH `Host` name to update in your `~/.ssh/config`.

## Examples

Start an instance:

```bash
ec3 start webserver
```

Start and update its SSH config:

```bash
ec3 start docs-dev --update
```

Stop an instance:

```bash
ec3 stop webserver
```

List all instances:

```bash
ec3 list
```

Check the status of an instance:

```bash
ec3 status database
```