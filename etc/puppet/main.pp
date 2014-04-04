# puppet

# default values
File {
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
}

Exec {
  user      => 'root',
  group     => 'root',
  logoutput => 'on_failure',
}

# packages
package { [
           'abcde',
           'abook',
           'ack-grep',
           'aegis',
           'anacron',
           'ant',
           'aptitude',
           'apvlv',
           'aria2',
           'attr',
           'avfs',
           'awesome',
           'azureus',
           'bar',
           'bc',
           'biabam',
           'bsdiff',
           'buffer',
           'bugs-everywhere',
           'bup',
           'burn',
           'bzip2',
           'capistrano',
           'cfget',
           'cfv',
           'clusterssh',
           'cmatrix',
           'cmatrix-xfont',
           'crawl',
           'cron',
           'curl',
           'cwcp',
           'dc',
           'dctrl-tools',
           'debsums',
           'dict',
           'dict-freedict-eng-spa',
           'dict-freedict-spa-eng',
           'dict-jargon',
           'dictd',
           'disper',
           'dstat',
           'dvdisaster',
           'e2fsprogs',
           'electricsheep',
           'etckeeper',
           'evince',
           'fbreader',
           'feh',
           'flac',
           'freecdb',
           'gawk',
           'genders',
           'genisoimage',
           'gimp',
           'git',
           'git-annex',
           'git-doc',
           'git-flow',
           'git-svn',
           'git2cl',
           'gitstats',
           'gmrun',
           'gnome-terminal',
           'gnupg',
           'gnupg-agent',
           'google-chrome-stable',
           'gource',
           'hardinfo',
           'hgview',
           'htop',
           'httpcode',
           'hwdata',
           'id3',
           'id3ren',
           'id3v2',
           'iftop',
           'inotail',
           'inotify-tools',
           'ioping',
           'iotop',
           'irssi',
           'ispanish',
           'ispell',
           'iwatch',
           'lftp',
           'libreoffice',
           'links',
           'lltag',
           'loadwatch',
           'lockout',
           'lrzip',
           'lsyncd',
           'mail-notification',
           'mailutils',
           'make',
           'markdown',
           'maven2',
           'mbuffer',
           'md5deep',
           'mdadm',
           'meld',
           'mercurial',
           'mercurial-git',
           'mlocate',
           'moosic',
           'mp3gain',
           'mp3info',
           'mp3splt',
           'mpg321',
           'mplayer',
           'mtools',
           'mutt',
           'netpipes',
           'network-manager',
           'network-manager-gnome',
           'nilfs-tools',
           'ntfs-3g',
           'ntfsprogs',
           'ntp',
           'obnam',
           'openjdk-6-jdk',
           'openjdk-6-jre',
           'openjdk-6-jre-headless',
           'openjdk-6-jre-lib',
           'openjdk-6-source',
           'openoffice.org',
           'openssh-client',
           'openssh-server',
           'orpie',
           'pal',
           'par2',
           'parted',
           'pexec',
           'pinpoint',
           'pipebench',
           'postpone',
           'privbind',
           'pv',
           'pwgen',
           'pydf',
           'qdbm-util',
           'qiv',
           'ranger',
           'razzle',
           'reptyr',
           'rpl',
           'rsync',
           's3cmd',
           's3ql',
           'saidar',
           'sc',
           'schedtool',
           'screen',
           'simhash',
           'smem',
           'spotify-client-qt',
           'sshfs',
           'sshpass',
           'stgit',
           'subversion',
           'taggrepper',
           'tagtool',
           'task-spooler',
           'telnet-ssl',
           'tig',
           'timelimit',
           'tinycdb',
           'tmux',
           'topgit',
           'totem',
           'tree',
           'trend',
           'trickle',
           'ttyload',
           'ttyrec',
           'ucspi-proxy',
           'ucspi-tcp',
           'ucspi-unix',
           'udpcast',
           'unrar',
           'unzip',
           'uptimed',
           'uuid',
           'vdmfec',
           'vim',
           'vim-doc',
           'vim-gnome',
           'vim-puppet',
           'vim-syntax-go',
           'w3m',
           'wamerican',
           'wbritish',
           'wcd',
           'wipe',
           'wodim',
           'wspanish',
           'xclip',
           'xdu',
           'xsel',
           'zip',
          ]:
  ensure => 'present',
}

# git submodules
exec { '/usr/bin/git submodule update --init --recursive':
  user      => 'dfanjul',
  group     => 'dfanjul',
  cwd       => '/home/dfanjul/',
  require   => Package['git'],
}

# sudoers
file { '/etc/sudoers.d/dfanjul':
  mode    => '0440',
  content => '
Defaults:dfanjul !tty_tickets, timestamp_timeout=-1
',
}

# crontabs
cron { 'uprecords':
  user    => 'dfanjul',
  ensure  => 'present',
  command => 'uprecords -M | mail -s uprecords dfanjul',
  minute  => 0,
  require => Package['cron'],
}
define crontab () {
  cron { $title:
    user    => 'dfanjul',
    ensure  => 'present',
    command => "d=~/etc/cron.$title && mkdir -p \"\$d\" && run-parts \"\$d\"",
    special => $title,
    require => Package['cron'],
  }
  cron { "local $title":
    user    => 'dfanjul',
    ensure  => 'present',
    command => "d=~/etc/cron.$title/\$(hostname) && mkdir -p \"\$d\" && run-parts \"\$d\"",
    special => $title,
    require => Package['cron'],
  }
}
crontab { [ 'reboot', 'hourly', 'daily', 'monthly', 'weekly', 'yearly', ]:
}

# # wdrive apt repository
# file { '/etc/apt/sources.list.d/wdrive.list':
#   content => '# wdrive
# deb file:///wdrive/downloads/software/apt/mirror/ftp.es.debian.org/debian/ wheezy main contrib non-free
# deb file:///wdrive/downloads/software/apt/mirror/ftp.es.debian.org/debian/ wheezy-proposed-updates main contrib non-free
# deb file:///wdrive/downloads/software/apt/mirror/security.debian.org/ wheezy/updates main contrib non-free
# deb file:///wdrive/downloads/software/apt/mirror/repository.spotify.com stable non-free
# ',
# }
#
# # ldrive apt repository
# file { '/etc/apt/sources.list.d/ldrive.list':
#   content => '# ldrive
# deb file:///ldrive/downloads/software/apt/mirror/ftp.es.debian.org/debian/ wheezy main contrib non-free
# deb file:///ldrive/downloads/software/apt/mirror/ftp.es.debian.org/debian/ wheezy-proposed-updates main contrib non-free
# deb file:///ldrive/downloads/software/apt/mirror/security.debian.org/ wheezy/updates main contrib non-free
# deb file:///ldrive/downloads/software/apt/mirror/repository.spotify.com stable non-free
# ',
# }
#
# exec { '/usr/bin/aptitude update':
#   require     => Package['aptitude'],
#   refreshonly => true,
#   subscribe   => [
#                   File['/etc/apt/sources.list.d/wdrive.list'],
#                   File['/etc/apt/sources.list.d/ldrive.list'],
#                  ],
# }
#
# 'gem update'
