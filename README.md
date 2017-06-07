# Beaker Host Generator

`beaker-hostgenerator` is a command line utility designed to generate beaker
host config files using a compact command line SUT specification.

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-generate-toc again -->
**Table of Contents**

- [Beaker Host Generator](#beaker-host-generator)
    - [Hypervisors](#hypervisors)
    - [Usage](#usage)
        - [Simple two-host layout](#simple-two-host-layout)
        - [Single host with Arbitrary Roles](#single-host-with-arbitrary-roles)
        - [Two hosts with multiple hypervisors and arbitrary host settings](#two-hosts-with-multiple-hypervisors-and-arbitrary-host-settings)
        - [Arbitrary global configuration settings](#arbitrary-global-configuration-settings)
        - [Custom hypervisor](#custom-hypervisor)
        - [URL-encoded input](#url-encoded-input)
    - [Testing](#testing)
        - [Test Fixtures](#test-fixtures)
            - [Generated Fixtures](#generated-fixtures)
    - [Support](#support)
    - [License](#license)

<!-- markdown-toc end -->

## Hypervisors

Any hypervisor may be specified and generated, but if it's not a built-in
hypervisor you will have to provide the entire hypervisor configuration as
input. See the [Custom hypervisor](#custom-hypervisor) example for more
information.

It currently provides built-in configuration for Puppets' internal
[vmpooler][vmpooler] hypervisor, [always-be-scheduling][always-be-scheduling]
hypervisor, static (non-provisioned) nodes, and is designed in a way that makes
it possible to easily add support for additional hypervisors
(any hypervisor type supported by [beaker][beaker]).

To see the list of built-in hypervisors you can run:
```
$ beaker-hostgenerator --list
```

## Usage

Below are some example usages of `beaker-hostgenerator`.

### Simple two-host layout

```
$ beaker-hostgenerator centos6-64mdca-32a
```

Will generate

```yaml
---
HOSTS:
  centos6-64-1:
    pe_dir:
    pe_ver:
    pe_upgrade_dir:
    pe_upgrade_ver:
    hypervisor: vmpooler
    platform: el-6-x86_64
    template: centos-6-x86_64
    roles:
    - agent
    - master
    - database
    - dashboard
  centos6-32-2:
    pe_dir:
    pe_ver:
    pe_upgrade_dir:
    pe_upgrade_ver:
    hypervisor: vmpooler
    platform: el-6-i386
    template: centos-6-i386
    roles:
    - agent
CONFIG:
  nfs_server: none
  consoleport: 443
  pooling_api: http://vmpooler.delivery.puppetlabs.net/
```

### Single host with Arbitrary Roles

```
$ beaker-hostgenerator centos6-32compile_master,another_role.ma
```

Will generate

```yaml
---
HOSTS:
  centos6-32-1:
    pe_dir:
    pe_ver:
    pe_upgrade_dir:
    pe_upgrade_ver:
    hypervisor: vmpooler
    platform: el-6-i386
    template: centos-6-i386
    roles:
    - agent
    - master
    - compile_master
    - another_role
    frictionless_options:
      main:
        dns_alt_names: puppet
        environmentpath: "/etc/puppetlabs/puppet/environments"
CONFIG:
  nfs_server: none
  consoleport: 443
  pooling_api: http://vmpooler.delivery.puppetlabs.net/
```

### Two hosts with multiple hypervisors and arbitrary host settings

```
$ beaker-hostgenerator centos6-64m{hypervisor=none\,hostname=static-master}-redhat7-64a{somekey=some-value}
```

Will generate

```yaml
---
HOSTS:
  static-master:
    pe_dir:
    pe_ver:
    pe_upgrade_dir:
    pe_upgrade_ver:
    platform: el-6-x86_64
    hypervisor: none
    roles:
    - agent
    - master
  redhat7-64-1:
    pe_dir:
    pe_ver:
    pe_upgrade_dir:
    pe_upgrade_ver:
    hypervisor: vmpooler
    platform: el-7-x86_64
    template: redhat-7-x86_64
    somekey: some-value
    roles:
    - agent
CONFIG:
  nfs_server: none
  consoleport: 443
  pooling_api: http://vmpooler.delivery.puppetlabs.net/
```

### Two hosts with arbitrary host settings with arbitrary lists

```
$ beaker-hostgenerator centos6-64m{disks=\[16\]-redhat7-64a{disks=\[8\,16\]}
```

Will generate

```yaml
---
HOSTS:
  centos6-64-1:
    pe_dir:
    pe_ver:
    pe_upgrade_dir:
    pe_upgrade_ver:
    platform: el-6-x86_64
    hypervisor: vmpooler
    disks:
    - 16
    roles:
    - agent
    - master
  redhat7-64-1:
    pe_dir:
    pe_ver:
    pe_upgrade_dir:
    pe_upgrade_ver:
    hypervisor: vmpooler
    platform: el-7-x86_64
    template: redhat-7-x86_64
    disks:
    - 8
    - 16
    roles:
    - agent
CONFIG:
  nfs_server: none
  consoleport: 443
  pooling_api: http://vmpooler.delivery.puppetlabs.net/



### Arbitrary global configuration settings

```
$ beaker-hostgenerator --global-config {preserve_hosts=onfail\,log_level=debug\,server.ip=12.345.6789} redhat7-64m
```

Will generate

```yaml
---
HOSTS:
  redhat7-64-1:
    pe_dir:
    pe_ver:
    pe_upgrade_dir:
    pe_upgrade_ver:
    hypervisor: vmpooler
    platform: el-7-x86_64
    template: redhat-7-x86_64
    roles:
    - agent
    - master
CONFIG:
  nfs_server: none
  consoleport: 443
  preserve_hosts: onfail
  log_level: debug
  server.ip: 12.345.6789
  pooling_api: http://vmpooler.delivery.puppetlabs.net/
```

### Custom hypervisor

The following example shows one way of generating a custom hypervisor that
includes both per-host configuration and global configuration.

The term "custom" in this case signifies that it's not a built-in hypervisor
(like `vmpooler`), which means we'll have to provide all the configuration
ourselves as there isn't any built-in configuration for our hypervisor.

```
$ beaker-hostgenerator --hypervisor=custom --global={custom_api=http://api.custom.net} centos6-64
```

Will generate

```yaml
---
HOSTS:
  centos6-64-1:
    pe_dir:
    pe_ver:
    pe_upgrade_dir:
    pe_upgrade_ver:
    platform: el-6-x86_64
    hypervisor: custom
    roles:
    - agent
CONFIG:
  nfs_server: none
  consoleport: 443
  custom_api: http://api.custom.net
```

### URL-encoded input

It may be necessary to URL-encode the input in order for it to properly be used
in certain contexts, such as Jenkins.

In most cases it will only be necessary to escape the characters that support
arbitrary settings, which means the following characters:

- `{` is `%7B`
- `,` is `%2C`
- `}` is `%7D`
- ` ` is `%20`
- `[` is `%5B`
- `]` is `%5D`

For a full URL encoding reference see: http://www.w3schools.com/tags/ref_urlencode.asp

```
$ beaker-hostgenerator centos6-64mcd-aix53-POWERfa%7Bhypervisor=aix%2Cvmhostname=pe-aix-53-acceptance.delivery.puppetlabs.net%7D
```

Is equivalent to

```
$ beaker-hostgenerator centos6-64mcd-aix53-POWERfa{hypervisor=aix,vmhostname=pe-aix-53-acceptance.delivery.puppetlabs.net}
```

And will generate

```yaml
---
HOSTS:
  centos6-64-1:
    pe_dir:
    pe_ver:
    pe_upgrade_dir:
    pe_upgrade_ver:
    hypervisor: vmpooler
    platform: el-6-x86_64
    template: centos-6-x86_64
    roles:
    - agent
    - master
    - dashboard
    - database
  aix53-POWER-1:
    pe_dir:
    pe_ver:
    pe_upgrade_dir:
    pe_upgrade_ver:
    platform: aix-5.3-power
    hypervisor: aix
    vmhostname: pe-aix-53-acceptance.delivery.puppetlabs.net
    roles:
    - agent
    - frictionless
CONFIG:
  nfs_server: none
  consoleport: 443
  pooling_api: http://vmpooler.delivery.puppetlabs.net/
```

## Testing

Beaker Host Generator currently uses both rspec and minitest tests. To run both
at the same time, run:
```bash
bundle exec rake test
```

### Test Fixtures

Beaker Host Generator makes extensive use of test fixtures to validate its
behavior under specific conditions. An example of such a test fixture is as
follows:

```yaml
---
arguments_string: "--pe_dir /opt/hello centos6-64mdc"
environment_variables: {}
expected_hash:
  HOSTS:
    centos6-64-1:
      pe_dir: "/opt/hello"
      pe_ver: 
      pe_upgrade_dir: 
      pe_upgrade_ver: 
      hypervisor: vmpooler
      platform: centos-6-x86_64
      template: centos-6-x86_64
      roles:
      - agent
      - master
      - database
      - dashboard
  CONFIG:
    nfs_server: none
    consoleport: 443
    pooling_api: http://vmpooler.delivery.puppetlabs.net/
expected_exception: 
```

These test fixtures are yaml files searched for in the directory
`test/fixtures`. The data structure expected in these files is a hash with four
keys:

- `arguments_string`: The command line arguments that should be passed to
  `beaker-hostgenerator`
- `environment_variables`: The environment variables that should be set during
  the `beaker-hostgenerator` call.
- `expected_hash`: A hash that should match the output of `beaker-hostgenerator`
  when it is run with `options\_string`
- `expected_exception`: If the `arguments_string` passed to `beaker-hostgenerator`
  is expected to lead to an exceptional state, this is the name of the exception
  that the fixture test will attempt to match.

#### Generated Fixtures

It is possible to generate test fixtures using the current state of the
`beaker-hostgenerator` library. To do this, call the `generate:fixtures` Rake
task.

However, this is not something that should need to be done very often. If you
are running tests and find that some fixtures no longer work, you have most
likely made a change that incompatibly changes the behavior of
`beaker-hostgenerator` for other users. Use the test fixtures as a guide to
figure out what you did wrong and figure out how to achieve your goal without
potentially breaking `beaker-hostgenerator` for other users.

There are a few circumstances when you should expect to run the
`generate:fixtures` task:

- When you modify the `FixtureGenerator` to generate new fixtures.
- When you need to fix a bug (generated hosts are not usable without your
  change, for example).
- When preparing for a major version bump of Beaker Host Generator.


## Support

Support offered by [Puppet](https://puppet.com) may not always be timely
since it is maintained by a tooling support team that is primarily focused on
improving tools, infrastructure, and automation for our Enterprise products.

That being said, we will happily accept and review PRs from community members
interested in extending and using `beaker-hostgenerator` for their own purposes.
See the [contributing][contributing] doc for more information about how to
contribute.

If you have questions or comments, please contact the Beaker team at the
`#puppet-dev` IRC channel on chat.freenode.org

## License

`beaker-hostgenerator` is distributed under the
[Apache License, Version 2.0][apache-v2]. See the [LICENSE][license] file for more details.

[vmpooler]: https://github.com/puppetlabs/vmpooler
[beaker]: https://github.com/puppetlabs/beaker
[license]: LICENSE
[contributing]: CONTRIBUTING.md
[apache-v2]: http://www.apache.org/licenses/LICENSE-2.0.html
[always-be-scheduling]: https://github.com/puppetlabs/always-be-scheduling
