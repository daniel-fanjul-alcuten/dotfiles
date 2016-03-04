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

class root ($user = 'dfanjul') {

  if $operatingsystem == 'Debian' {

    # wdrive apt repository
    file { '/etc/apt/sources.list.d/wdrive.list':
      tag     => 'apt-list',
      content => '# wdrive
deb file:///wdrive/downloads/software/apt/mirror/ftp.es.debian.org/debian/ wheezy main contrib non-free
deb file:///wdrive/downloads/software/apt/mirror/ftp.es.debian.org/debian/ wheezy-proposed-updates main contrib non-free
deb file:///wdrive/downloads/software/apt/mirror/security.debian.org/ wheezy/updates main contrib non-free
',
    }

    # ldrive apt repository
    file { '/etc/apt/sources.list.d/ldrive.list':
      tag     => 'apt-list',
      content => '# ldrive
deb file:///ldrive/downloads/software/apt/mirror/ftp.es.debian.org/debian/ wheezy main contrib non-free
deb file:///ldrive/downloads/software/apt/mirror/ftp.es.debian.org/debian/ wheezy-proposed-updates main contrib non-free
deb file:///ldrive/downloads/software/apt/mirror/security.debian.org/ wheezy/updates main contrib non-free
',
    }
  }

  if $lsbdistcodename == 'trusty' {
    file { '/etc/apt/sources.list.d/canonical.list':
      tag     => 'apt-list',
      content => '# canonical
deb http://archive.canonical.com/ trusty partner
deb-src http://archive.canonical.com/ trusty partner
',
    }
  }

  # hipchat
  file { '/etc/apt/sources.list.d/atlassian-hipchat.list':
    tag     => 'apt-list',
    content => '# hipchat
deb http://downloads.hipchat.com/linux/apt stable main
',
  }
  exec { '/usr/bin/wget -O - https://www.hipchat.com/keys/hipchat-linux.key | /usr/bin/apt-key add -':
    tag     => 'apt-key',
  }

  # docker
  package { 'apt-transport-https':
    ensure => 'present',
  }
  package { 'ca-certificates':
    ensure => 'present',
  }
  exec { '/usr/bin/apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D':
    tag     => 'apt-key',
    require => [ Package['apt-transport-https'], Package['ca-certificates'], ]
  }
  file { '/etc/apt/sources.list.d/docker.list':
    tag     => 'apt-list',
    content => '# docker
deb https://apt.dockerproject.org/repo ubuntu-trusty main
',
  }

  # aptitude
  exec { '/usr/bin/aptitude update':
    refreshonly => true,
    require     => Package['aptitude'],
  }
  File<| tag == 'apt-list' |> ~> Exec['/usr/bin/aptitude update']
  Exec<| tag == 'apt-key' |>  ~> Exec['/usr/bin/aptitude update']
  Exec['/usr/bin/aptitude update'] -> Package<| title != 'aptitude' and title != 'apt-transport-https' and title != 'ca-certificates' |>

  # packages
  package { 'lxc-docker':
    ensure => 'purged',
  }
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
              'at',
              'attr',
              'avfs',
              'awesome',
              'azureus',
              'bar',
              'bc',
              'beep',
              'biabam',
              'blueman',
              'bsdiff',
              'buffer',
              'bugs-everywhere',
              'bup',
              'burn',
              'bzip2',
              'cadaver',
              'capistrano',
              'cfget',
              'cfv',
              'cifs-utils',
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
              'docker-engine',
              'dstat',
              'dvdisaster',
              'e2fsprogs',
              'etckeeper',
              'evince',
              'fbreader',
              'feh',
              'flac',
              'fonts-inconsolata',
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
              'gnome-control-center',
              'gnome-terminal',
              'gnupg',
              'gnupg-agent',
              'gource',
              'graphviz',
              'graphviz-doc',
              'hardinfo',
              'hgview',
              'hipchat',
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
              'lynx',
              'mail-notification',
              'mailutils',
              'make',
              'markdown',
              'maven',
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
              'mplayer2',
              'mtools',
              'mtp-tools',
              'mtpfs',
              'mutt',
              'netpipes',
              'network-manager',
              'network-manager-gnome',
              'network-manager-vpnc',
              'nilfs-tools',
              'ntfs-3g',
              'ntp',
              'obnam',
              'openjdk-6-jdk',
              'openjdk-6-jre',
              'openjdk-6-jre-headless',
              'openjdk-6-jre-lib',
              'openjdk-6-source',
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
              'reptyr',
              'rpl',
              'rsync',
              's3cmd',
              's3ql',
              'saidar',
              'sc',
              'schedtool',
              'screen',
              'shellcheck',
              'simhash',
              'skype',
              'smem',
              'smplayer',
              'sshfs',
              'sshpass',
              'stgit',
              'subversion',
              'taggrepper',
              'tagtool',
              'task',
              'task-spooler',
              'telnet-ssl',
              'tidy',
              'tig',
              'timelimit',
              'tinycdb',
              'tmux',
              'tor',
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
              'unrtf',
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

  package { [
              'maven2',
            ]:
    ensure => 'purged',
  }

  # sudoers
  file { "/etc/sudoers.d/$root::user":
    mode    => '0440',
    content => "
Defaults:$root::user !tty_tickets, timestamp_timeout=-1
",
  }
}

class dfanjul ($user = 'dfanjul') {

  # git submodules
  exec { '/usr/bin/git submodule update --init --recursive':
    user    => $dfanjul::user,
    group   => $dfanjul::user,
    cwd     => "/home/$dfanjul::user/",
    require => Package['git'],
  }

  # crontabs
  define crontab () {
    cron { $title:
      user    => $dfanjul::user,
      ensure  => 'present',
      command => "~/bin/run-parts-cron $title",
      special => $title,
      require => Package['cron'],
    }
  }
  crontab { [ 'reboot', 'hourly', 'daily', 'monthly', 'weekly', 'yearly', ]:
  }
}

node example {

  class { ['root', 'dfanjul']:
    user => 'dfanjul',
  }
}
