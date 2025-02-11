# EC3 - Elastic compute cloud companion

This script allows you to manage your AWS EC2 instances using aliases defined in a mapping file. You can start, stop, list, and check the status of instances.

## Problem

To start, stop, or check the status of an EC2 instance that you regularly use, you have to follow multiple steps by going into your browser. Instead of that, you can do it in a single command from your CLI.

## Installation

Please follow the installation steps in [INSTALL.md](./INSTALL.md) to set up the script.

## Usage

```bash
ec3 <start|stop|list|status> [alias]
```

- `start`: Start the instance associated with the alias.
- `stop`: Stop the instance associated with the alias.
- `list`: List all instances defined in the mapping file.
- `status`: Check the status of the instance associated with the alias.

## Mapping File

The mapping file (`~/.ec3rc`) should contain lines in the following format:

```
<alias>=<instance_id>:<region>
```

Example:

```
webserver=i-1234567890abcdef:us-west-2
database=i-0987654321fedcba:us-east-1
```

## Example

To start an instance:

```bash
ec3 start webserver
```

To stop an instance:

```bash
ec3 stop webserver
```

To list all instances:

```bash
ec3 list
```

To check the status of an instance:

```bash
ec3 status webserver
```