module BeakerHostGenerator
  # Contains all the platform information that ends up in the generated hosts
  # configuration. This includes the various OS-specific platform
  # configuration, and PE-specific installation & upgrade configuration.
  #
  # Any data used by any hypervisor or any other abstraction should be defined
  # in this module, likely in the `osinfo` hash. The hypervisor implementation
  # must then use the provided module functions (likely `get_platform_info`) to
  # extract the relevant portions of the `osinfo` data.
  #
  # This module is intended to be used by either directly accessing the static
  # functions like `BeakerHostGenerator::Data.<function>()` or as a mixin via
  # `include BeakerHostGenerator::Data` and then `<function>()`.
  module Data
    module_function
    MAIN_PE_VERSION=2021.0
    PE_TARBALL_SERVER="https://artifactory.delivery.puppetlabs.net/artifactory/generic_enterprise__local"

    def pe_version
      ENV['pe_version']
    end

    def pe_upgrade_version
      ENV['pe_upgrade_version']
    end

    def pe_dir(version)
      return if version.nil? || version.empty?

      base_regex = '(\A\d+\.\d+)\.\d+'
      source = case version
      when /#{base_regex}\Z/
        then "#{PE_TARBALL_SERVER}/archives/releases/#{version}/"
      when /#{base_regex}-rc\d+\Z/
        then "#{PE_TARBALL_SERVER}/archives/internal/%s/"
      when /#{base_regex}-.*(PEZ|pez)_.*/
        then "#{PE_TARBALL_SERVER}/%s/feature/ci-ready"
      when /#{base_regex}-.*/
        then "#{PE_TARBALL_SERVER}/%s/ci-ready"
      else
        ''
      end

      pe_family = $1
      gem_version = Gem::Version.new(pe_family)
      if(gem_version < Gem::Version.new("#{MAIN_PE_VERSION}") || version =~ /#{base_regex}-rc\d+\Z/)
        pe_branch = pe_family
      else
        pe_branch = 'main'
      end

      return sprintf(source, ("#{pe_branch}" || ''))
    end

    PE_USE_WIN32 = ENV['pe_use_win32']

    BASE_CONFIG = {
      'HOSTS' => {},
      'CONFIG' => {
        'nfs_server' => 'none',
        'consoleport' => 443,
      }
    }

    def base_host_config(options)
      {
        'pe_dir' => options[:pe_dir] || pe_dir(pe_version),
        'pe_ver' => options[:pe_ver] || pe_version,
        'pe_upgrade_dir' => options[:pe_upgrade_dir] || pe_dir(pe_upgrade_version),
        'pe_upgrade_ver' => options[:pe_upgrade_ver] || pe_upgrade_version,
      }
    end

    # This is where all the information for all platforms lives, irrespective
    # of the hypervisor(s).
    # This hash contains every OS that BHG supports as keys, and the values are
    # hashes that contain hypervisor-specific data about that OS.
    # Every OS also has a special "general" section for data that should always
    # be included regardless of the hypervisor.
    # Hypervisor implementations will then grab specific bits of data out of
    # this hash and combine them to produce the generated hosts output.
    def osinfo
      result = {}

      # Fedora
      (19..33).each do |release|
        # 32 bit support was dropped in Fedora 31
        if release < 31
          result["fedora#{release}-32"] = {
            :general => {
              'platform' => "fedora-#{release}-i386"
            }
          }
        end

        result["fedora#{release}-64"] = {
          :general => {
            'platform' => "fedora-#{release}-x86_64"
          }
        }
      end

      result.merge!({
        'aix53-POWER' => {
          :general => {
            'platform'           => 'aix-5.3-power',
            'packaging_platform' => 'aix-5.3-power'
          },
          :abs => {
            'template' => 'aix-5.3-power'
          }
        },
        'aix61-POWER' => {
          :general => {
            'platform'           => 'aix-6.1-power',
            'packaging_platform' => 'aix-6.1-power'
          },
          :abs => {
            'template' => 'aix-6.1-power'
          }
        },
        'aix71-POWER' => {
          :general => {
            'platform'           => 'aix-7.1-power',
            'packaging_platform' => 'aix-7.1-power'
          },
          :abs => {
            'template' => 'aix-7.1-power'
          }
        },
        'aix72-POWER' => {
          :general => {
            'platform'           => 'aix-7.2-power',
            'packaging_platform' => 'aix-7.1-power'
          },
          :abs => {
            'template' => 'aix-7.2-power'
          }
        },
        'amazon6-64' => {
            :general => {
                'platform'           => 'el-6-x86_64',
                'packaging_platform' => 'el-6-x86_64'
            },
            :abs => {
                'template' => 'amazon-6-x86_64'
            }
        },
        'amazon7-64' => {
            :general => {
                'platform'           => 'el-7-x86_64',
                'packaging_platform' => 'el-7-x86_64'
            },
            :abs => {
                'template' => 'amazon-7-x86_64'
            }
        },
        'amazon7-ARM64' => {
          :general => {
            'platform'           => 'el-7-aarch64',
            'packaging_platform' => 'el-7-aarch64'
          },
          :abs => {
            'template' => 'amazon-7-arm64'
          }
        },
        'archlinuxrolling-64' => {
          :general => {
            'platform' => 'archlinux-rolling-x64',
          },
          :vagrant => {
            'box' => 'archlinux/archlinux',
          },
          :docker => {
            'image' => 'archlinux/archlinux',
          }
        },
        'arista4-32' => {
          :general => {
            'platform'           => 'eos-4-i386',
            'packaging_platform' => 'eos-4-i386'
          },
          :vmpooler => {
            'template' => 'arista-4-i386'
          }
        },
        'centos4-32' => {
          :general => {
            'platform' => 'el-4-i386'
          }
        },
        'centos4-64' => {
          :general => {
            'platform' => 'el-4-x86_64'
          }
        },
        'centos5-32' => {
          :general => {
            'platform'           => 'el-5-i386',
            'packaging_platform' => 'el-5-i386'
          }
        },
        'centos5-64' => {
          :general => {
            'platform'           => 'el-5-x86_64',
            'packaging_platform' => 'el-5-x86_64'
          },
          :docker => {
            'docker_image_commands' => [
              'cp /bin/true /sbin/mingetty',
              'yum install -y crontabs initscripts iproute openssl sysvinit-tools tar wget which',
              'sed -i -e "/mingetty/d" /etc/inittab'
            ]
          }
        },
        'centos6-32' => {
          :general => {
            'platform'           => 'el-6-i386',
            'packaging_platform' => 'el-6-i386'
          }
        },
        'centos6-64' => {
          :general => {
            'platform'           => 'el-6-x86_64',
            'packaging_platform' => 'el-6-x86_64'
          },
          :docker => {
            'docker_image_commands' => [
              'cp /bin/true /sbin/mingetty',
              'rm -rf /var/run/network/*',
              'yum install -y crontabs initscripts iproute openssl sysvinit-tools tar wget which',
              'rm /etc/init/tty.conf'
            ]
          }
        },
        'centos7-64' => {
          :general => {
            'platform'           => 'el-7-x86_64',
            'packaging_platform' => 'el-7-x86_64'
          },
          :docker => {
            'docker_image_commands' => [
              'cp /bin/true /sbin/agetty',
              'yum install -y crontabs initscripts iproute openssl sysvinit-tools tar wget which ss'
            ]
          }
        },
        'centos8-64' => {
          :general => {
            'platform'           => 'el-8-x86_64',
            'packaging_platform' => 'el-8-x86_64'
          },
          :docker => {
            'docker_image_commands' => [
              'cp /bin/true /sbin/agetty',
              'yum install -y crontabs initscripts iproute openssl wget which glibc-langpack-en'
            ]
          }
        },
        # Deprecated
        'cisconx-64' => {
          :general => {
            'platform'           => 'cisco_nexus-7-x86_64',
            'packaging_platform' => 'cisco-wrlinux-5-x86_64',
            'vrf' => 'management',
            'ssh' => {
              'user' => 'beaker'
            }
          },
          :vmpooler => {
            'template' => 'cisco-nxos-9k-x86_64'
          }
        },
        # Deprecated
        'ciscon7k-64' => {
          :general => {
            'platform'           => 'cisco_nexus-7k-x86_64',
            'packaging_platform' => 'cisco-wrlinux-5-x86_64',
            'vrf' => 'management',
            'ssh' => {
              'user' => 'admin'
            }
          },
          :abs => {
            'template' => 'cisco-n7k-7k-x86_64'
          }
        },
        # Deprecated
        'cisconxhw-64' => {
          :general => {
            'platform'           => 'cisco_nexus-7-x86_64',
            'packaging_platform' => 'cisco-wrlinux-5-x86_64',
            'vrf' => 'management',
            'ssh' => {
              'user' => 'devops'
            }
          },
          :abs => {
            'template' => 'cisco-nxos_hw-9k-x86_64'
          }
        },
        'cisco_n9k-VM' => {
          :general => {
            'platform'           => 'cisco_nexus-7-x86_64',
            'packaging_platform' => 'cisco-wrlinux-5-x86_64',
            'vrf' => 'management',
            'ssh' => {
              'user' => 'beaker'
            }
          },
          :vmpooler => {
            'template' => 'cisco-nxos-9k-x86_64'
          }
        },
        'cisco_n7k-HW' => {
          :general => {
            'platform'           => 'cisco_nexus-7k-x86_64',
            'packaging_platform' => 'cisco-wrlinux-5-x86_64',
            'vrf' => 'management',
            'ssh' => {
              'user' => 'admin'
            }
          },
          :abs => {
            'template' => 'cisco-n7k-x86_64'
          }
        },
        'cisco_n7k_vdc-HW' => {
          :general => {
            'platform'           => 'cisco_nexus-7k-x86_64',
            'packaging_platform' => 'cisco-wrlinux-5-x86_64',
            'vrf' => 'management',
            'ssh' => {
              'user' => 'admin'
            }
          },
          :abs => {
            'template' => 'cisco-n7k_vdc-x86_64'
          }
        },
        'cisco_n9k-HW' => {
          :general => {
            'platform'           => 'cisco_nexus-7-x86_64',
            'packaging_platform' => 'cisco-wrlinux-5-x86_64',
            'vrf' => 'management',
            'ssh' => {
              'user' => 'devops'
            }
          },
          :abs => {
            'template' => 'cisco-n9k-x86_64'
          }
        },
        'cisco_ios_c2960-HW' => {
          :general => {
            'platform' => 'cisco_ios-12-arm32',
            'ssh' => {
              'user' => 'admin'
            }
          },
          :abs => {
            'template' => 'cisco-ios_c2960-arm'
          }
        },
        'cisco_ios_c3560-HW' => {
          :general => {
            'platform' => 'cisco_ios-12-arm32',
            'ssh' => {
              'user' => 'admin'
            }
          },
          :abs => {
            'template' => 'cisco-ios_c3560-arm'
          }
        },
        'cisco_ios_c3750-HW' => {
          :general => {
            'platform' => 'cisco_ios-12-arm32',
            'ssh' => {
              'user' => 'admin'
            }
          },
          :abs => {
            'template' => 'cisco-ios_c3750-arm'
          }
        },
        'cisco_ios_c4507r-HW' => {
          :general => {
            'platform' => 'cisco_ios-12-arm32',
            'ssh' => {
              'user' => 'admin'
            }
          },
          :abs => {
            'template' => 'cisco-ios_c4507r-arm'
          }
        },
        'cisco_ios_c4948-HW' => {
          :general => {
            'platform' => 'cisco_ios-12-arm32',
            'ssh' => {
              'user' => 'admin'
            }
          },
          :abs => {
            'template' => 'cisco-ios_c4948-arm'
          }
        },
        'cisco_ios_c6503-HW' => {
          :general => {
            'platform' => 'cisco_ios-12-arm32',
            'ssh' => {
              'user' => 'admin'
            }
          },
          :abs => {
            'template' => 'cisco-ios_c6503-arm'
          }
        },
        'cisco_iosxe_c3650-HW' => {
          :general => {
            'platform' => 'cisco_iosxec3650-arm32',
            'ssh' => {
              'user' => 'admin'
            }
          },
          :abs => {
            'template' => 'cisco-iosxe_c3650-arm'
          }
        },
        'cisco_iosxe_c4503-HW' => {
          :general => {
            'platform' => 'cisco_iosxe-3-arm32',
            'ssh' => {
              'user' => 'admin'
            }
          },
          :abs => {
            'template' => 'cisco-iosxe_c4503-arm'
          }
        },
        'cisco_xr_9k-VM' => {
          :general => {
            'platform'           => 'cisco_ios_xr-6-x86_64',
            'packaging_platform' => 'cisco-wrlinux-7-x86_64'
          },
          :vmpooler => {
            'template' => 'cisco-exr-9k-x86_64'
          }
        },
        'cumulus25-64' => {
          :general => {
            'platform'           => 'cumulus-2.5-x86_64',
            'packaging_platform' => 'cumulus-2.2-amd64'
          },
          :vmpooler => {
            'template' => 'cumulus-vx-25-x86_64'
          }
        },
        'debian6-32' => {
          :general => {
            'platform' => 'debian-6-i386'
          },
          :vmpooler => {
            'template' => 'debian-6-i386'
          }
        },
        'debian6-64' => {
          :general => {
            'platform' => 'debian-6-amd64'
          },
          :vmpooler => {
            'template' => 'debian-6-x86_64'
          }
        },
        'debian7-32' => {
          :general => {
            'platform'           => 'debian-7-i386',
            'packaging_platform' => 'debian-7-i386'
          },
          :vmpooler => {
            'template' => 'debian-7-i386'
          }
        },
        'debian7-64' => {
          :general => {
            'platform'           => 'debian-7-amd64',
            'packaging_platform' => 'debian-7-amd64'
          },
          :docker => {
            'docker_image_commands' => [
              'cp /bin/true /sbin/getty',
              'apt-get update && apt-get install -y cron locales-all net-tools wget'
            ],
          },
          :vagrant => {
            'box' => 'debian/wheezy64',
          },
          :vmpooler => {
            'template' => 'debian-7-x86_64'
          }
        },
        'debian8-32' => {
          :general => {
            'platform'           => 'debian-8-i386',
            'packaging_platform' => 'debian-8-i386'
          },
          :vmpooler => {
            'template' => 'debian-8-i386'
          }
        },
        'debian8-64' => {
          :general => {
            'platform'           => 'debian-8-amd64',
            'packaging_platform' => 'debian-8-amd64'
          },
          :docker => {
            'docker_image_commands' => [
              'cp /bin/true /sbin/agetty',
              'rm -f /usr/sbin/policy-rc.d',
              'apt-get update && apt-get install -y cron locales-all net-tools wget apt-transport-https'
            ]
          },
          :vagrant => {
            'box' => 'debian/jessie64',
          },
          :vmpooler => {
            'template' => 'debian-8-x86_64'
          }
        },
        'debian9-32' => {
          :general => {
            'platform'           => 'debian-9-i386',
            'packaging_platform' => 'debian-9-i386'
          },
          :vmpooler => {
            'template' => 'debian-9-i386'
          },
          :docker => {
            'docker_image_commands' => [
              'cp /bin/true /sbin/agetty',
              'rm -f /usr/sbin/policy-rc.d',
              'apt-get update && apt-get install -y cron locales-all net-tools wget apt-transport-https'
            ]
          }
        },
        'debian9-64' => {
          :general => {
            'platform'           => 'debian-9-amd64',
            'packaging_platform' => 'debian-9-amd64'
          },
          :docker => {
            'docker_image_commands' => [
              'cp /bin/true /sbin/agetty',
              'rm -f /usr/sbin/policy-rc.d',
              'apt-get update && apt-get install -y cron locales-all net-tools wget systemd-sysv gnupg apt-transport-https'
            ]
          },
          :vagrant => {
            'box' => 'debian/stretch64',
          },
          :vmpooler => {
            'template' => 'debian-9-x86_64'
          }
        },
        'debian10-64' => {
          :general => {
            'platform'           => 'debian-10-amd64',
            'packaging_platform' => 'debian-10-amd64'
          },
          :docker => {
            'docker_image_commands' => [
              'cp /bin/true /sbin/agetty',
              'rm -f /usr/sbin/policy-rc.d',
              'apt-get update && apt-get install -y cron locales-all net-tools wget gnupg'
            ]
          },
          :vagrant => {
            'box' => 'debian/buster64',
          },
          :vmpooler => {
            'template' => 'debian-10-x86_64'
          }
        },
        'debian10-32' => {
          :general => {
            'platform'           => 'debian-10-i386',
            'packaging_platform' => 'debian-10-i386'
          },
          :docker => {
            'docker_image_commands' => [
              'cp /bin/true /sbin/agetty',
              'rm -f /usr/sbin/policy-rc.d',
              'apt-get update && apt-get install -y cron locales-all net-tools wget gnupg'
            ]
          },
          :vmpooler => {
            'template' => 'debian-10-i386'
          }
        },
        'fedora14-32' => {
          :general => {
            'platform' => 'fedora-14-i386'
          }
        },
        'huaweios6-POWER' => {
          :general => {
            'platform' => 'huaweios-6-powerpc'
          },
          :abs => {
            'template' => 'huaweios-6-powerpc'
          }
        },
        'panos61-64' => {
          :general => {
            'platform' => 'palo-alto-6.1.0-x86_64'
          },
          :vmpooler => {
            'template' => 'palo-alto-6.1.0-x86_64'
          }
        },
        'panos71-64' => {
          :general => {
            'platform' => 'palo-alto-7.1.0-x86_64'
          },
          :vmpooler => {
            'template' => 'palo-alto-7.1.0-x86_64'
          }
        },
        'panos81-64' => {
          :general => {
            'platform' => 'palo-alto-8.1.0-x86_64'
          },
          :vmpooler => {
            'template' => 'palo-alto-8.1.0-x86_64'
          }
        },
        'opensuse11-32' => {
          :general => {
            'platform' => 'opensuse-11-i386'
          },
          :vmpooler => {
            'template' => 'opensuse-11-i386'
          }
        },
        'opensuse11-64' => {
          :general => {
            'platform' => 'opensuse-11-x86_64'
          },
          :vmpooler => {
            'template' => 'opensuse-11-x86_64'
          }
        },
        'opensuse15-32' => {
          :general => {
            'platform' => 'opensuse-15-i386'
          },
          :docker => {
            'docker_image_commands' => [
              'cp /bin/true /sbin/agetty',
              'zypper install -y cron iproute2 tar wget which'
            ]
          },
          :vmpooler => {
            'template' => 'opensuse-15-i386'
          }
        },
        'opensuse15-64' => {
          :general => {
            'platform' => 'opensuse-15-x86_64'
          },
          :docker => {
            'docker_image_commands' => [
              'cp /bin/true /sbin/agetty',
              'zypper install -y cron iproute2 tar wget which'
            ]
          },
          :vmpooler => {
            'template' => 'opensuse-15-x86_64'
          }
        },
        'opensuse42-32' => {
          :general => {
            'platform' => 'opensuse-42-i386'
          },
          :docker => {
            'docker_image_commands' => [
              'cp /bin/true /sbin/agetty',
              'zypper install -y cron iproute2 tar wget which'
            ]
          },
          :vmpooler => {
            'template' => 'opensuse-42-i386'
          }
        },
        'opensuse42-64' => {
          :general => {
            'platform' => 'opensuse-42-x86_64'
          },
          :docker => {
            'docker_image_commands' => [
              'cp /bin/true /sbin/agetty',
              'zypper install -y cron iproute2 tar wget which'
            ]
          },
          :vmpooler => {
            'template' => 'opensuse-42-x86_64'
          }
        },
        'oracle5-32' => {
          :general => {
            'platform'           => 'el-5-i386',
            'packaging_platform' => 'el-5-i386'
          },
          :vmpooler => {
            'template' => 'oracle-5-i386'
          }
        },
        'oracle5-64' => {
          :general => {
            'platform'           => 'el-5-x86_64',
            'packaging_platform' => 'el-5-x86_64'
          },
          :vmpooler => {
            'template' => 'oracle-5-x86_64'
          }
        },
        'oracle6-32' => {
          :general => {
            'platform'           => 'el-6-i386',
            'packaging_platform' => 'el-6-i386'
          },
          :vmpooler => {
            'template' => 'oracle-6-i386'
          }
        },
        'oracle6-64' => {
          :general => {
            'platform'           => 'el-6-x86_64',
            'packaging_platform' => 'el-6-x86_64'
          },
          :vmpooler => {
            'template' => 'oracle-6-x86_64'
          }
        },
        'oracle7-64' => {
          :general => {
            'platform'           => 'el-7-x86_64',
            'packaging_platform' => 'el-7-x86_64'
          },
          :vmpooler => {
            'template' => 'oracle-7-x86_64'
          }
        },
        'osx109-64' => {
          :general => {
            'platform' => 'osx-10.9-x86_64'
          },
          :vmpooler => {
            'template' => 'osx-109-x86_64'
          }
        },
        'osx1010-64' => {
          :general => {
            'platform'           => 'osx-10.10-x86_64',
            'packaging_platform' => 'osx-10.10-x86_64'
          },
          :vmpooler => {
            'template' => 'osx-1010-x86_64'
          }
        },
        'osx1011-64' => {
          :general => {
            'platform'           => 'osx-10.11-x86_64',
            'packaging_platform' => 'osx-10.11-x86_64'
          },
          :vmpooler => {
            'template' => 'osx-1011-x86_64'
          }
        },
        'osx1012-64' => {
          :general => {
            'platform'           => 'osx-10.12-x86_64',
            'packaging_platform' => 'osx-10.12-x86_64'
          },
          :vmpooler => {
            'template' => 'osx-1012-x86_64'
          }
        },
        'osx1013-64' => {
          :general => {
            'platform'           => 'osx-10.13-x86_64',
            'packaging_platform' => 'osx-10.13-x86_64'
          },
          :vmpooler => {
            'template' => 'osx-1013-x86_64'
          }
        },
        'osx1014-64' => {
          :general => {
            'platform'           => 'osx-10.14-x86_64',
            'packaging_platform' => 'osx-10.14-x86_64'
          },
          :vmpooler => {
            'template' => 'osx-1014-x86_64'
          }
        },
        'osx1015-64' => {
          :general => {
            'platform'           => 'osx-10.15-x86_64',
            'packaging_platform' => 'osx-10.15-x86_64'
          },
          :vmpooler => {
            'template' => 'osx-1015-x86_64'
          }
        },
        'redhat4-32' => {
          :general => {
            'platform' => 'el-4-i386'
          },
          :vmpooler => {
            'template' => 'redhat-4-i386'
          }
        },
        'redhat4-64' => {
          :general => {
            'platform' => 'el-4-x86_64'
          },
          :vmpooler => {
            'template' => 'redhat-4-x86_64'
          }
        },
        'redhat5-32' => {
          :general => {
            'platform'          => 'el-5-i386',
            'packaging_platform' => 'el-5-i386'
          },
          :vmpooler => {
            'template' => 'redhat-5-i386'
          }
        },
        'redhat5-64' => {
          :general => {
            'platform'          => 'el-5-x86_64',
            'packaging_platform' => 'el-5-x86_64'
          },
          :vmpooler => {
            'template' => 'redhat-5-x86_64'
          }
        },
        'redhat6-32' => {
          :general => {
            'platform'          => 'el-6-i386',
            'packaging_platform' => 'el-6-i386'
          },
          :vmpooler => {
            'template' => 'redhat-6-i386'
          }
        },
        'redhat6-64' => {
          :general => {
            'platform'           => 'el-6-x86_64',
            'packaging_platform' => 'el-6-x86_64'
          },
          :vmpooler => {
            'template' => 'redhat-6-x86_64'
          }
        },
        'redhat6-S390X' => {
          :general => {
            'platform'          => 'el-6-s390x',
            'packaging_platform' => 'el-6-s390x'
          },
        },
        'redhat7-64' => {
          :general => {
            'platform'           => 'el-7-x86_64',
            'packaging_platform' => 'el-7-x86_64'
          },
          :vmpooler => {
            'template' => 'redhat-7-x86_64'
          }
        },
        'redhatfips7-64' => {
          :general => {
            'platform'           => 'el-7-x86_64',
            'packaging_platform' => 'redhatfips-7-x86_64'
          },
          :vmpooler => {
            'template' => 'redhat-fips-7-x86_64'
          }
        },
        'redhat7-POWER' => {
          :general => {
            'platform'           => 'el-7-ppc64le',
            'packaging_platform' => 'el-7-ppc64le'
          },
          :abs => {
            'template' => 'redhat-7.3-power8'
          }
        },
        'redhat7-S390X' => {
          :general => {
            'platform'           => 'el-7-s390x',
            'packaging_platform' => 'el-7-s390x'
          },
        },
        'redhat7-AARCH64' => {
          :general => {
            'platform'           => 'el-7-aarch64',
            'packaging_platform' => 'el-7-aarch64'
          },
          :abs => {
            'template' => 'centos-7-arm64'
          },
          :vmpooler => {
            'template' => 'redhat-7-x86_64'
          }
        },
        'redhat8-64' => {
          :general => {
            'platform'           => 'el-8-x86_64',
            'packaging_platform' => 'el-8-x86_64'
          },
          :vmpooler => {
            'template' => 'redhat-8-x86_64'
          }
        },
        'redhat8-AARCH64' => {
          :general => {
            'platform'           => 'el-8-aarch64',
            'packaging_platform' => 'el-8-aarch64'
          },
          :abs => {
            'template' => 'redhat-8-arm64'
          },
          :vmpooler => {
            'template' => 'redhat-8-x86_64'
          }
        },
        'scientific5-32' => {
          :general => {
            'platform'           => 'el-5-i386',
            'packaging_platform' => 'el-5-i386'
          },
          :vmpooler => {
            'template' => 'scientific-5-i386'
          }
        },
        'scientific5-64' => {
          :general => {
            'platform'           => 'el-5-x86_64',
            'packaging_platform' => 'el-5-x86_64'
          },
          :vmpooler => {
            'template' => 'scientific-5-x86_64'
          }
        },
        'scientific6-32' => {
          :general => {
            'platform'          => 'el-6-i386',
            'packaging_platform' => 'el-6-i386'
          },
          :vmpooler => {
            'template' => 'scientific-6-i386'
          }
        },
        'scientific6-64' => {
          :general => {
            'platform'           => 'el-6-x86_64',
            'packaging_platform' => 'el-6-x86_64'
          },
          :vmpooler => {
            'template' => 'scientific-6-x86_64'
          }
        },
        'scientific7-64' => {
          :general => {
            'platform'          => 'el-7-x86_64',
            'packaging_platform' => 'el-7-x86_64'
          },
          :vmpooler => {
            'template' => 'scientific-7-x86_64'
          }
        },
        'sles10-32' => {
          :general => {
            'platform' => 'sles-10-i386'
          },
          :vmpooler => {
            'template' => 'sles-10-i386'
          }
        },
        'sles10-64' => {
          :general => {
            'platform' => 'sles-10-x86_64'
          },
          :vmpooler => {
            'template' => 'sles-10-x86_64'
          }
        },
        'sles11-32' => {
          :general => {
            'platform'           => 'sles-11-i386',
            'packaging_platform' => 'sles-11-i386'
          },
          :vmpooler => {
            'template' => 'sles-11-i386'
          }
        },
        'sles11-64' => {
          :general => {
            'platform'           => 'sles-11-x86_64',
            'packaging_platform' => 'sles-11-x86_64'
          },
          :vmpooler => {
            'template' => 'sles-11-x86_64'
          }
        },
        'sles11-S390X' => {
          :general => {
            'platform'           => 'sles-11-s390x',
            'packaging_platform' => 'sles-11-s390x'
          },
        },
        'sles12-64' => {
          :general => {
            'platform'           => 'sles-12-x86_64',
            'packaging_platform' => 'sles-12-x86_64'
          },
          :vmpooler => {
            'template' => 'sles-12-x86_64'
          }
        },
        'sles12-S390X' => {
          :general => {
            'platform'           => 'sles-12-s390x',
            'packaging_platform' => 'sles-12-s390x'
          }
        },
        'sles12-POWER' => {
          :general => {
            'platform'           => 'sles-12-ppc64le',
            'packaging_platform' => 'sles-12-ppc64le'
          },
          :abs => {
            'template' => 'sles-12-power8'
          }
        },
        'sles15-64' => {
          :general => {
            'platform'           => 'sles-15-x86_64',
            'packaging_platform' => 'sles-15-x86_64'
          },
          :vmpooler => {
            'template' => 'sles-15-x86_64'
          }
        },
        'solaris10-32' => {
          :general => {
            'platform'           => 'solaris-10-i386',
            'packaging_platform' => 'solaris-10-i386'
          },
          :vmpooler => {
            'template' => 'solaris-10-x86_64'
          }
        },
        'solaris10-64' => {
          :general => {
            'platform'           => 'solaris-10-i386',
            'packaging_platform' => 'solaris-10-i386'
          },
          :vmpooler => {
            'template' => 'solaris-10-x86_64'
          }
        },
        'solaris10-SPARC' => {
          :general => {
            'platform'           => 'solaris-10-sparc',
            'packaging_platform' => 'solaris-10-sparc'
          },
          :abs => {
            'template' => 'solaris-10-sparc'
          }
        },
        'solaris11-32' => {
          :general => {
            'platform'           => 'solaris-11-i386',
            'packaging_platform' => 'solaris-11-i386'
          },
          :vmpooler => {
            'template' => 'solaris-11-x86_64'
          }
        },
        'solaris11-64' => {
          :general => {
            'platform'           => 'solaris-11-i386',
            'packaging_platform' => 'solaris-11-i386'
          },
          :vmpooler => {
            'template' => 'solaris-11-x86_64'
          }
        },
        'solaris11-SPARC' => {
          :general => {
            'platform'           => 'solaris-11-sparc',
            'packaging_platform' => 'solaris-11-sparc'
          },
          :abs => {
            'template' => 'solaris-11-sparc'
          }
        },
        'solaris112-32' => {
          :general => {
            'platform'           => 'solaris-11.2-i386',
            'packaging_platform' => 'solaris-11-i386'
          },
          :vmpooler => {
            'template' => 'solaris-112-x86_64'
          }
        },
        'solaris112-64' => {
          :general => {
            'platform'           => 'solaris-11.2-i386',
            'packaging_platform' => 'solaris-11-i386'
          },
          :vmpooler => {
            'template' => 'solaris-112-x86_64'
          }
        },
        'solaris114-32' => {
          :general => {
            'platform'           => 'solaris-11.4-i386',
            'packaging_platform' => 'solaris-11-i386'
          },
          :vmpooler => {
            'template' => 'solaris-114-x86_64'
          }
        },
        'solaris114-64' => {
          :general => {
            'platform'           => 'solaris-11.4-i386',
            'packaging_platform' => 'solaris-11-i386'
          },
          :vmpooler => {
            'template' => 'solaris-114-x86_64'
          }
        },
        'ubuntu1004-32' => {
          :general => {
            'platform' => 'ubuntu-10.04-i386'
          },
          :vmpooler => {
            'template' => 'ubuntu-1004-i386'
          }
        },
        'ubuntu1004-64' => {
          :general => {
            'platform' => 'ubuntu-10.04-amd64'
          },
          :vmpooler => {
            'template' => 'ubuntu-1004-x86_64'
          }
        },
        'ubuntu1204-32' => {
          :general => {
            'platform' => 'ubuntu-12.04-i386'
          },
          :vmpooler => {
            'template' => 'ubuntu-1204-i386'
          }
        },
        'ubuntu1204-64' => {
          :general => {
            'platform' => 'ubuntu-12.04-amd64'
          },
          :docker => {
            'docker_image_commands' => [
              'cp /bin/true /sbin/agetty',
              'apt-get install -y net-tools wget',
              'locale-gen en_US.UTF-8'
            ]
          },
          :vmpooler => {
            'template' => 'ubuntu-1204-x86_64'
          }
        },
        'ubuntu1404-32' => {
          :general => {
            'platform'           => 'ubuntu-14.04-i386',
            'packaging_platform' => 'ubuntu-14.04-i386'
          },
          :vmpooler => {
            'template' => 'ubuntu-1404-i386'
          }
        },
        'ubuntu1404-64' => {
          :general => {
            'platform'           => 'ubuntu-14.04-amd64',
            'packaging_platform' => 'ubuntu-14.04-amd64'
          },
          :docker => {
            'docker_image_commands' => [
              'cp /bin/true /sbin/agetty',
              'rm /usr/sbin/policy-rc.d',
              'rm /sbin/initctl; dpkg-divert --rename --remove /sbin/initctl',
              'apt-get install -y net-tools wget apt-transport-https',
              'locale-gen en_US.UTF-8',
              'echo LANG=en_US.UTF-8 > /etc/default/locale'
            ]
          },
          :vmpooler => {
            'template' => 'ubuntu-1404-x86_64'
          }
        },
        'ubuntu1504-32' => {
          :general => {
            'platform' => 'ubuntu-15.04-i386'
          },
          :vmpooler => {
            'template' => 'ubuntu-1504-i386'
          }
        },
        'ubuntu1504-64' => {
          :general => {
            'platform' => 'ubuntu-15.04-amd64'
          },
          :vmpooler => {
            'template' => 'ubuntu-1504-x86_64'
          }
        },
        'ubuntu1510-32' => {
          :general => {
            'platform' => 'ubuntu-15.10-i386'
          },
          :vmpooler => {
            'template' => 'ubuntu-1510-i386'
          }
        },
        'ubuntu1510-64' => {
          :general => {
            'platform' => 'ubuntu-15.10-amd64'
          },
          :vmpooler => {
            'template' => 'ubuntu-1510-x86_64'
          }
        },
        'ubuntu1604-32' => {
          :general => {
            'platform'           => 'ubuntu-16.04-i386',
            'packaging_platform' => 'ubuntu-16.04-i386'
          },
          :vmpooler => {
            'template' => 'ubuntu-1604-i386'
          }
        },
        'ubuntu1604-64' => {
          :general => {
            'platform'           => 'ubuntu-16.04-amd64',
            'packaging_platform' => 'ubuntu-16.04-amd64'
          },
          :docker => {
            'docker_image_commands' => [
              'cp /bin/true /sbin/agetty',
              'apt-get install -y net-tools wget locales apt-transport-https',
              'locale-gen en_US.UTF-8',
              'echo LANG=en_US.UTF-8 > /etc/default/locale'
            ]
          },
          :vmpooler => {
            'template' => 'ubuntu-1604-x86_64'
          }
        },
        'ubuntu1604-POWER' => {
          :general => {
            'platform'           => 'ubuntu-16.04-ppc64el',
            'packaging_platform' => 'ubuntu-16.04-ppc64el'
          },
          :abs => {
            'template' => 'ubuntu-16.04-power8'
          }
        },
        'ubuntu1610-32' => {
          :general => {
            'platform' => 'ubuntu-16.10-i386'
          },
          :vmpooler => {
            'template' => 'ubuntu-1610-i386'
          }
        },
        'ubuntu1610-64' => {
          :general => {
            'platform' => 'ubuntu-16.10-amd64'
          },
          :vmpooler => {
            'template' => 'ubuntu-1610-x86_64'
          }
        },
        'ubuntu1804-64' => {
          :general => {
            'platform'           => 'ubuntu-18.04-amd64',
            'packaging_platform' => 'ubuntu-18.04-amd64'
          },
          :docker => {
            'docker_image_commands' => [
              'cp /bin/true /sbin/agetty',
              'apt-get install -y net-tools wget locales apt-transport-https iproute2 gnupg',
              'locale-gen en_US.UTF-8',
              'echo LANG=en_US.UTF-8 > /etc/default/locale'
            ]
          },
          :vmpooler => {
            'template' => 'ubuntu-1804-x86_64'
          }
        },
        'ubuntu1810-64' => {
          :general => {
            'platform'           => 'ubuntu-18.10-amd64',
            'packaging_platform' => 'ubuntu-18.10-amd64'
          },
          :docker => {
            'docker_image_commands' => [
              'cp /bin/true /sbin/agetty',
              'apt-get install -y net-tools wget locales apt-transport-https iproute2',
              'locale-gen en_US.UTF-8',
              'echo LANG=en_US.UTF-8 > /etc/default/locale'
            ]
          },
          :vmpooler => {
            'template' => 'ubuntu-1810-x86_64'
          }
        },
        'ubuntu2004-64' => {
          :general => {
            'platform'           => 'ubuntu-20.04-amd64',
            'packaging_platform' => 'ubuntu-20.04-amd64'
          },
          :docker => {
            'docker_image_commands' => [
              'cp /bin/true /sbin/agetty',
              'apt-get install -y net-tools wget locales apt-transport-https iproute2 gnupg',
              'locale-gen en_US.UTF-8',
              'echo LANG=en_US.UTF-8 > /etc/default/locale'
            ]
          },
          :vmpooler => {
            'template' => 'ubuntu-2004-x86_64'
          }
        },
        'ubuntu2004-AARCH64' => {
          :general => {
            'platform'           => 'ubuntu-20.04-aarch64',
            'packaging_platform' => 'ubuntu-20.04-aarch64'
          },
          :abs => {
            'template' => 'ubuntu-2004-arm64'
          },
        },
        'vro6-64' => {
          :general => {
            'platform'           => 'sles-11-x86_64',
            'packaging_platform' => 'sles-11-x86_64'
          },
          :vmpooler => {
            'template' => 'vro-6-x86_64'
          }
        },
        'vro7-64' => {
          :general => {
            'platform'           => 'sles-11-x86_64',
            'packaging_platform' => 'sles-11-x86_64'
          },
          :vmpooler => {
            'template' => 'vro-7-x86_64'
          }
        },
        'vro71-64' => {
          :general => {
            'platform'           => 'sles-11-x86_64',
            'packaging_platform' => 'sles-11-x86_64'
          },
          :vmpooler => {
            'template' => 'vro-71-x86_64'
          }
        },
        'vro73-64' => {
          :general => {
            'platform'           => 'sles-11-x86_64',
            'packaging_platform' => 'sles-11-x86_64'
          },
          :vmpooler => {
            'template' => 'vro-73-x86_64'
          }
        },
        'vro74-64' => {
          :general => {
            'platform'           => 'sles-11-x86_64',
            'packaging_platform' => 'sles-11-x86_64'
          },
          :vmpooler => {
            'template' => 'vro-74-x86_64'
          }
        },
        'windows2008-64' => {
          :general => {
            'platform'           => 'windows-2008-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-2008-x86_64'
          }
        },
        'windows2008-6432' => {
          :general => {
            'platform'           => 'windows-2008-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x86'
          },
          :vmpooler => {
            'template' => 'win-2008-x86_64'
          }
        },
        'windows2008r2-64' => {
          :general => {
            'platform'           => 'windows-2008r2-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-2008r2-x86_64'
          }
        },
        'windows2008r2-6432' => {
          :general => {
            'platform'           => 'windows-2008r2-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x86'
          },
          :vmpooler => {
            'template' => 'win-2008r2-x86_64'
          }
        },
        'windows2012-64' => {
          :general => {
            'platform'           => 'windows-2012-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-2012-x86_64'
          }
        },
        'windows2012-6432' => {
          :general => {
            'platform'           => 'windows-2012-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x86'
          },
          :vmpooler => {
            'template' => 'win-2012-x86_64'
          }
        },
        'windows2012r2-64' => {
          :general => {
            'platform'           => 'windows-2012r2-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-2012r2-x86_64'
          }
        },
        'windowsfips2012r2-64' => {
          :general => {
            'platform'           => 'windows-2012r2-64',
            'packaging_platform' => 'windowsfips-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-2012r2-fips-x86_64'
          }
        },
        'windowsfips2012r2-6432' => {
          :general => {
            'platform'           => 'windows-2012r2-64',
            'packaging_platform' => 'windowsfips-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-2012r2-fips-x86_64'
          }
        },
        'windows2012r2-6432' => {
          :general => {
            'platform'           => 'windows-2012r2-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x86'
          },
          :vmpooler => {
            'template' => 'win-2012r2-x86_64'
          }
        },
        'windows2012r2_wmf5-64' => {
          :general => {
            'platform'           => 'windows-2012r2-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-2012r2-wmf5-x86_64'
          }
        },
        'windows2012r2_ja-64' => {
          :general => {
            'platform'           => 'windows-2012r2-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-2012r2-ja-x86_64',
            'locale'   => 'ja'
          }
        },
        'windows2012r2_ja-6432' => {
          :general => {
            'platform'           => 'windows-2012r2-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x86'
          },
          :vmpooler => {
            'template' => 'win-2012r2-ja-x86_64',
            'locale'   => 'ja'
          }
        },
        'windows2012r2_fr-64' => {
          :general => {
            'platform'           => 'windows-2012r2-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-2012r2-fr-x86_64',
            'user'     => 'Administrateur',
            'locale'   => 'fr'
          }
        },
        'windows2012r2_fr-6432' => {
          :general => {
            'platform'           => 'windows-2012r2-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x86'
          },
          :vmpooler => {
            'template' => 'win-2012r2-fr-x86_64',
            'user'     => 'Administrateur',
            'locale'   => 'fr'
          }
        },
        'windows2012r2_core-64' => {
          :general => {
            'platform'           => 'windows-2012r2-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-2012r2-core-x86_64'
          }
        },
        'windows2012r2_core-6432' => {
          :general => {
            'platform'           => 'windows-2012r2-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x86'
          },
          :vmpooler => {
            'template' => 'win-2012r2-core-x86_64'
          }
        },
        'windows2016-64' => {
          :general => {
            'platform'           => 'windows-2016-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-2016-x86_64'
          }
        },
        'windows2016-6432' => {
          :general => {
            'platform'           => 'windows-2016-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x86'
          },
          :vmpooler => {
            'template' => 'win-2016-x86_64'
          }
        },
        'windows2016_core-64' => {
          :general => {
            'platform'           => 'windows-2016-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-2016-core-x86_64'
          }
        },
        'windows2016_core-6432' => {
          :general => {
            'platform'           => 'windows-2016-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x86'
          },
          :vmpooler => {
            'template' => 'win-2016-core-x86_64'
          }
        },
        'windows2016_fr-64' => {
          :general => {
            'platform'           => 'windows-2016-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-2016-fr-x86_64',
            'user'     => 'Administrateur',
            'locale'   => 'fr'
          }
        },
        'windows2016_fr-6432' => {
          :general => {
            'platform'           => 'windows-2016-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x86'
          },
          :vmpooler => {
            'template' => 'win-2016-fr-x86_64',
            'user'     => 'Administrateur',
            'locale'   => 'fr'
          }
        },
        'windows2019-64' => {
          :general => {
            'platform'           => 'windows-2019-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-2019-x86_64'
          }
        },
        'windows2019-6432' => {
          :general => {
            'platform'           => 'windows-2019-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x86'
          },
          :vmpooler => {
            'template' => 'win-2019-x86_64'
          }
        },
        'windows2019_ja-64' => {
          :general => {
            'platform'           => 'windows-2019-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-2019-ja-x86_64',
            'locale'   => 'ja'
          }
        },
        'windows2019_ja-6432' => {
          :general => {
            'platform'           => 'windows-2019-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x86'
          },
          :vmpooler => {
            'template' => 'win-2019-ja-x86_64',
            'locale'   => 'ja'
          }
        },
        'windows2019_fr-64' => {
          :general => {
            'platform'           => 'windows-2019-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-2019-fr-x86_64',
            'user'     => 'Administrateur',
            'locale'   => 'fr'
          }
        },
        'windows2019_fr-6432' => {
          :general => {
            'platform'           => 'windows-2019-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x86'
          },
          :vmpooler => {
            'template' => 'win-2019-fr-x86_64',
            'user'     => 'Administrateur',
            'locale'   => 'fr'
          }
        },
        'windows2019_core-64' => {
          :general => {
            'platform'           => 'windows-2019-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-2019-core-x86_64'
          }
        },
        'windows2019_core-6432' => {
          :general => {
            'platform'           => 'windows-2019-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x86'
          },
          :vmpooler => {
            'template' => 'win-2019-core-x86_64'
          }
        },
        'windows7-64' => {
          :general => {
            'platform'           => 'windows-7-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-7-x86_64'
          }
        },
        'windows81-64' => {
          :general => {
            'platform'           => 'windows-8.1-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-81-x86_64'
          }
        },
        'windows10ent-32' => {
          :general => {
            'platform'           => 'windows-10ent-32',
            'packaging_platform' => 'windows-2012-x86',
            'ruby_arch' => 'x86'
          },
          :vmpooler => {
            'template' => 'win-10-ent-i386'
          }
        },
        'windows10ent-64' => {
          :general => {
            'platform'           => 'windows-10ent-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-10-ent-x86_64'
          }
        },
        'windows10next-32' => {
          :general => {
            'platform'           => 'windows-10ent-32',
            'packaging_platform' => 'windows-2012-x86',
            'ruby_arch' => 'x86'
          },
          :vmpooler => {
            'template' => 'win-10-next-i386'
          }
        },
        'windows10next-64' => {
          :general => {
            'platform'           => 'windows-10ent-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-10-next-x86_64'
          }
        },
        'windows10pro-64' => {
          :general => {
            'platform'           => 'windows-10pro-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-10-pro-x86_64'
          }
        },
        'windows10_1511-64' => {
          :general => {
            'platform'           => 'windows-10ent-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-10-1511-x86_64'
          }
        },
        'windows10_1607-64' => {
          :general => {
            'platform'           => 'windows-10ent-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-10-1607-x86_64'
          }
        },
        'windows10_1809-64' => {
          :general => {
            'platform'           => 'windows-10ent-64',
            'packaging_platform' => 'windows-2012-x64',
            'ruby_arch' => 'x64'
          },
          :vmpooler => {
            'template' => 'win-10-1809-x86_64'
          }
        }
      })

      result
    end

    def osinfo_bhgv1
      {
        'centos4-32' => {
          :general => {
            'platform' => 'centos-4-i386'
          },
          :vmpooler => {
            'template' => 'centos-4-i386'
          }
        },
        'centos4-64' => {
          :general => {
            'platform' => 'centos-4-x86_64'
          },
          :vmpooler => {
            'template' => 'centos-4-x86_64'
          }
        },
        'centos5-32' => {
          :general => {
            'platform' => 'centos-5-i386'
          },
          :vmpooler => {
            'template' => 'centos-5-i386'
          }
        },
        'centos5-64' => {
          :general => {
            'platform' => 'centos-5-x86_64'
          },
          :vmpooler => {
            'template' => 'centos-5-x86_64'
          }
        },
        'centos6-32' => {
          :general => {
            'platform' => 'centos-6-i386'
          },
          :vmpooler => {
            'template' => 'centos-6-i386'
          }
        },
        'centos6-64' => {
          :general => {
            'platform' => 'centos-6-x86_64'
          },
          :vmpooler => {
            'template' => 'centos-6-x86_64'
          }
        },
        'centos7-64' => {
          :general => {
            'platform' => 'centos-7-x86_64'
          },
          :vmpooler => {
            'template' => 'centos-7-x86_64'
          }
        }
      }
    end

    # Returns the map of OS info for the given version of this library.
    # The current version is always available as version 0 (zero).
    # Throws an exception if the version number is unrecognized.
    #
    # This is intended to be the primary access point for the OS info maps
    # defined in `osinfo`, `osinfo_bhgv1`, etc.
    #
    # See also `get_platforms`, `get_platform_info`, for common operations on
    # this OS info map.
    def get_osinfo(bhg_version)
      case bhg_version
      when 0
        {}.deep_merge!(osinfo)
      when 1
        {}.deep_merge!(osinfo).deep_merge!(osinfo_bhgv1)
      else
        raise "Invalid beaker-hostgenerator version: #{bhg_version}"
      end
    end

    # Returns the list of platforms supported by the specified version of this
    # library. This list should be equal to the keys of the `get_osinfo` map
    # and is provided as a common convenience.
    def get_platforms(bhg_version)
      get_osinfo(bhg_version).keys
    end

    # Returns the fully parsed map of information of the specified OS platform
    # for the specified hypervisor. This map should be suitable for outputting
    # to the user as it will have the intermediate organizational branches of
    # the `get_osinfo` map removed.
    #
    # This is intended to be the primary way to access OS info from hypervisor
    # implementations when generating host definitions.
    #
    # @param [Integer] bhg_version The version of OS info to use.
    #
    # @param [String] platform The OS platform to access from the OS info map.
    #
    # @param [Symbol] hypervisor The symbol representing which hypervisor submap
    #                 to extract from the general OS info map.
    #
    # @example Getting CentOS 6 64-bit information for the VMPooler hypervisor
    #     Given the OS info map looks like:
    #         ...
    #         'centos6-64' => {
    #           :general => { 'platform' => 'el-6-x86_64' },
    #           :vmpooler => { 'template' => 'centos-6-x86_64' }
    #         }
    #         ...
    #
    #     Then get_platform_info(0, 'centos6-64', :vmpooler) returns:
    #         {
    #           'platform' => 'el-6-x86_64',
    #           'template' => 'centos-6-x86_64'
    #         }
    def get_platform_info(bhg_version, platform, hypervisor)
      info = get_osinfo(bhg_version)[platform]
      {}.deep_merge!(info[:general]).deep_merge!(info[hypervisor])
    end

    # Perform any adjustments or modifications necessary to the given node
    # configuration map, taking things like platform and PE version into
    # account.
    #
    # This is intended to capture any oddities that are necessary for a node
    # to be used in a particular context.
    def fixup_node(cfg)
      # PE 2.8 doesn't exist for EL 4. We use 2.0 instead.
      if cfg['platform'] =~ /el-4/ and pe_version =~ /2\.8/
        cfg['pe_ver'] = "2.0.3"
      end
    end

  end
end
