# Copyright © 2019 The Trustees of Indiana University
# SPDX-License-Identifier: BSD-3-Clause
#
# @summary This class will configure PAM to require Duo
#
# This class sets up the appropriate file in the PAM stack to require Duo 2fa
# to successfully authenticate.
#
# @example
#   include duo_unix::pam_config
class duo_unix::pam_config inherits duo_unix::params {
  $aug_pam_path      = "/files${duo_unix::params::pam_file}"
  $aug_pam_ssh_path  = "/files${duo_unix::params::pam_ssh_file}"
  $aug_pam_match     = "${aug_pam_path}/*/module[. = '${duo_unix::params::pam_module}']"
  $aug_pam_ssh_match = "${aug_pam_ssh_path}/*/module[. ='${$duo_unix::params::pam_module}']"

  case $facts['os']['family'] {
    'Debian': {
      augeas { 'Duo Security PAM Configuration':
        context => $duo_unix::params::pam_file,
        changes => [
          "set ${aug_pam_path}/1/control ${duo_unix::params::pam_unix_control}",
          "ins 100 after ${aug_pam_path}/1",
          "set ${aug_pam_path}/100/type auth",
          "set ${aug_pam_path}/100/control '[success=1 default=ignore]'",
          "set ${aug_pam_path}/100/module ${duo_unix::params::pam_module}",
        ],
        require => Package[$duo_unix::params::duo_package],
        onlyif  => "match ${aug_pam_match} size == 0";
      }
      # Configure PAM SSHD module in line with Duo recommendations
      augeas { 'Duo Security PAM SSH Configuration':
        context => $duo_unix::params::pam_ssh_file,
        changes => [
          "rm ${aug_pam_ssh_path}/include[1]",
          "ins 100 before ${aug_pam_ssh_path}/1",
          "set ${aug_pam_ssh_path}/100/type auth",
          "set ${aug_pam_ssh_path}/100/control '[success=1 default=ignore]'",
          "set ${aug_pam_ssh_path}/100/module ${duo_unix::params::pam_module}",
          "ins 101 after ${aug_pam_ssh_path}/100",
          "set ${aug_pam_ssh_path}/101/type auth",
          "set ${aug_pam_ssh_path}/101/control requisite",
          "set ${aug_pam_ssh_path}/101/module pam_deny.so",
          "ins 102 after ${aug_pam_ssh_path}/101",
          "set ${aug_pam_ssh_path}/102/type auth",
          "set ${aug_pam_ssh_path}/102/control required",
          "set ${aug_pam_ssh_path}/102/module pam_permit.so",
        ],
        require => Package[$duo_unix::params::duo_package],
        onlyif  => "match ${aug_pam_ssh_match} size == 0",
      }
    }
    'RedHat': {
      augeas { 'Duo Security PAM Configuration':
        changes => [
          "set ${aug_pam_path}/2/control ${duo_unix::params::pam_unix_control}",
          "ins 100 after ${aug_pam_path}/2",
          "set ${aug_pam_path}/100/type auth",
          "set ${aug_pam_path}/100/control sufficient",
          "set ${aug_pam_path}/100/module ${duo_unix::params::pam_module}",
        ],
        require => Package[$duo_unix::params::duo_package],
        onlyif  => "match ${aug_pam_match} size == 0";
      }
    }
    default: {
      fail("Module ${module_name} does not support ${facts['os']['release']['full']}")
    }
  }
}
