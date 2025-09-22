Цель домашнего задания:  
Научится самостоятельно устанавливать ZFS, настраивать пулы, изучить основные возможности ZFS.

Описание:  
- Определить алгоритм с наилучшим сжатием:
- Определить какие алгоритмы сжатия поддерживает zfs (gzip, zle, lzjb, lz4);
создать 4 файловых системы на каждой применить свой алгоритм сжатия;
- для сжатия использовать либо текстовый файл, либо группу файлов.
- Определить настройки пула. С помощью команды zfs import собрать pool ZFS.
  Командами zfs определить настройки:
    - размер хранилища;
    - тип pool;
    - значение recordsize;
    - какое сжатие используется;
    - какая контрольная сумма используется.
- Работа со снапшотами:
- скопировать файл из удаленной директории; 
- восстановить файл локально. zfs receive;
- найти зашифрованное сообщение в файле secret_message.


```bash
[root@OTUS ~]# sudo dnf install -y https://zfsonlinux.org/epel/zfs-release-2-2.el9.noarch.rpm
[root@OTUS ~]# dnf install -y zfs
[root@OTUS ~]# lsmod | grep zfs
[root@OTUS ~]# sudo modprobe zfs
[root@OTUS ~]# lsmod | grep zfs
zfs                  6619136  0
spl                   163840  1 zfs
[root@OTUS ~]# echo "zfs" | sudo tee /etc/modules-load.d/zfs.conf
[root@OTUS ~]# lsblk
NAME                 MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                    8:0    0   16G  0 disk
├─sda1                 8:1    0  512M  0 part /boot/efi
├─sda2                 8:2    0    1G  0 part /boot
└─sda3                 8:3    0 14.5G  0 part
  └─vg_rocky-lv_root 253:0    0    8G  0 lvm  /
sdb                    8:16   0  512M  0 disk
sdc                    8:32   0  512M  0 disk
sdd                    8:48   0  512M  0 disk
sde                    8:64   0  512M  0 disk
sdf                    8:80   0  512M  0 disk
sdg                    8:96   0  512M  0 disk
sdh                    8:112  0  512M  0 disk
sdi                    8:128  0  512M  0 disk

[root@OTUS ~]# zpool create otus4 mirror /dev/sdh /dev/sdi
[root@OTUS ~]# zpool create otus3 mirror /dev/sdf /dev/sdg
[root@OTUS ~]# zpool create otus2 mirror /dev/sdd /dev/sde
[root@OTUS ~]# zpool create otus1 mirror /dev/sdb /dev/sdc
[root@OTUS ~]# zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   480M   105K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus2   480M   106K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus3   480M   106K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus4   480M   102K   480M        -         -     0%     0%  1.00x    ONLINE  -
[root@OTUS ~]# zpool status
  pool: otus1
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        otus1       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdb     ONLINE       0     0     0
            sdc     ONLINE       0     0     0

errors: No known data errors

  pool: otus2
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        otus2       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdd     ONLINE       0     0     0
            sde     ONLINE       0     0     0

errors: No known data errors

  pool: otus3
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        otus3       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdf     ONLINE       0     0     0
            sdg     ONLINE       0     0     0

errors: No known data errors

  pool: otus4
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        otus4       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdh     ONLINE       0     0     0
            sdi     ONLINE       0     0     0

errors: No known data errors
[root@OTUS ~]# zfs set compression=lzjb otus1
[root@OTUS ~]# zfs set compression=lz4 otus2
[root@OTUS ~]# zfs set compression=gzip-9 otus3
[root@OTUS ~]# zfs set compression=zle otus4
[root@OTUS ~]# zfs get all | grep compression
otus1  compression           lzjb                   local
otus2  compression           lz4                    local
otus3  compression           gzip-9                 local
otus4  compression           zle                    local

[root@OTUS ~]# for i in {1..4}; do wget -P /otus$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done
--2025-09-22 14:48:12--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 41174169 (39M) [text/plain]
Saving to: ‘/otus1/pg2600.converter.log’

pg2600.converter.log                           100%[====================================================================================================>]  39.27M  10.8MB/s    in 3.6s

2025-09-22 14:48:17 (10.8 MB/s) - ‘/otus1/pg2600.converter.log’ saved [41174169/41174169]

--2025-09-22 14:48:17--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 41174169 (39M) [text/plain]
Saving to: ‘/otus2/pg2600.converter.log’

pg2600.converter.log                           100%[====================================================================================================>]  39.27M  9.47MB/s    in 4.6s

2025-09-22 14:48:23 (8.47 MB/s) - ‘/otus2/pg2600.converter.log’ saved [41174169/41174169]

--2025-09-22 14:48:23--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 41174169 (39M) [text/plain]
Saving to: ‘/otus3/pg2600.converter.log’

pg2600.converter.log                           100%[====================================================================================================>]  39.27M  5.44MB/s    in 7.2s

2025-09-22 14:48:31 (5.44 MB/s) - ‘/otus3/pg2600.converter.log’ saved [41174169/41174169]

--2025-09-22 14:48:31--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 41174169 (39M) [text/plain]
Saving to: ‘/otus4/pg2600.converter.log’

pg2600.converter.log                           100%[====================================================================================================>]  39.27M  11.0MB/s    in 3.6s

2025-09-22 14:48:36 (11.0 MB/s) - ‘/otus4/pg2600.converter.log’ saved [41174169/41174169]

[root@OTUS ~]# ls -l /otus*
/otus1:
total 22111
-rw-r--r-- 1 root root 41174169 Sep  2 07:31 pg2600.converter.log

/otus2:
total 18013
-rw-r--r-- 1 root root 41174169 Sep  2 07:31 pg2600.converter.log

/otus3:
total 10969
-rw-r--r-- 1 root root 41174169 Sep  2 07:31 pg2600.converter.log

/otus4:
total 40237
-rw-r--r-- 1 root root 41174169 Sep  2 07:31 pg2600.converter.log

[root@OTUS ~]# zfs list
NAME    USED  AVAIL  REFER  MOUNTPOINT
otus1  21.7M   330M  21.6M  /otus1
otus2  17.7M   334M  17.6M  /otus2
otus3  10.9M   341M  10.7M  /otus3
otus4  39.4M   313M  39.3M  /otus4

[root@OTUS ~]# zfs get all | grep compressratio | grep -v ref
otus1  compressratio         1.82x                  -
otus2  compressratio         2.23x                  -
otus3  compressratio         3.66x                  -
otus4  compressratio         1.00x                  -

[root@OTUS ~]# wget -O archive.tar.gz --no-check-certificate 'https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download'
--2025-09-22 14:49:42--  https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download
Resolving drive.usercontent.google.com (drive.usercontent.google.com)... 142.250.186.129, 2a00:1450:4001:82b::2001
Connecting to drive.usercontent.google.com (drive.usercontent.google.com)|142.250.186.129|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 7275140 (6.9M) [application/octet-stream]
Saving to: ‘archive.tar.gz’

archive.tar.gz                                 100%[====================================================================================================>]   6.94M  17.6MB/s    in 0.4s

2025-09-22 14:49:50 (17.6 MB/s) - ‘archive.tar.gz’ saved [7275140/7275140]

[root@OTUS ~]# tar -xzvf archive.tar.gz
zpoolexport/
zpoolexport/filea
zpoolexport/fileb

[root@OTUS ~]# zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
status: Some supported features are not enabled on the pool.
        (Note that they may be intentionally disabled if the
        'compatibility' property is set.)
 action: The pool can be imported using its name or numeric identifier, though
        some features will not be available without an explicit 'zpool upgrade'.
 config:

        otus                         ONLINE
          mirror-0                   ONLINE
            /root/zpoolexport/filea  ONLINE
            /root/zpoolexport/fileb  ONLINE

[root@OTUS ~]# zpool import -d zpoolexport/ otus

[root@OTUS ~]# zpool status
  pool: otus
 state: ONLINE
status: Some supported and requested features are not enabled on the pool.
        The pool can still be used, but some features are unavailable.
action: Enable all features using 'zpool upgrade'. Once this is done,
        the pool may no longer be accessible by software that does not support
        the features. See zpool-features(7) for details.
config:

        NAME                         STATE     READ WRITE CKSUM
        otus                         ONLINE       0     0     0
          mirror-0                   ONLINE       0     0     0
            /root/zpoolexport/filea  ONLINE       0     0     0
            /root/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors

  pool: otus1
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        otus1       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdb     ONLINE       0     0     0
            sdc     ONLINE       0     0     0

errors: No known data errors

  pool: otus2
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        otus2       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdd     ONLINE       0     0     0
            sde     ONLINE       0     0     0

errors: No known data errors

  pool: otus3
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        otus3       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdf     ONLINE       0     0     0
            sdg     ONLINE       0     0     0

errors: No known data errors

  pool: otus4
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        otus4       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdh     ONLINE       0     0     0
            sdi     ONLINE       0     0     0

errors: No known data errors

[root@OTUS ~]# zpool get all otus
NAME  PROPERTY                       VALUE                          SOURCE
otus  size                           480M                           -
otus  capacity                       0%                             -
otus  altroot                        -                              default
otus  health                         ONLINE                         -
otus  guid                           6554193320433390805            -
otus  version                        -                              default
otus  bootfs                         -                              default
otus  delegation                     on                             default
otus  autoreplace                    off                            default
otus  cachefile                      -                              default
otus  failmode                       wait                           default
otus  listsnapshots                  off                            default
otus  autoexpand                     off                            default
otus  dedupratio                     1.00x                          -
otus  free                           478M                           -
otus  allocated                      2.09M                          -
otus  readonly                       off                            -
otus  ashift                         0                              default
otus  comment                        -                              default
otus  expandsize                     -                              -
otus  freeing                        0                              -
otus  fragmentation                  0%                             -
otus  leaked                         0                              -
otus  multihost                      off                            default
otus  checkpoint                     -                              -
otus  load_guid                      9467850998749107305            -
otus  autotrim                       off                            default
otus  compatibility                  off                            default
otus  bcloneused                     0                              -
otus  bclonesaved                    0                              -
otus  bcloneratio                    1.00x                          -
otus  feature@async_destroy          enabled                        local
otus  feature@empty_bpobj            active                         local
otus  feature@lz4_compress           active                         local
otus  feature@multi_vdev_crash_dump  enabled                        local
otus  feature@spacemap_histogram     active                         local
otus  feature@enabled_txg            active                         local
otus  feature@hole_birth             active                         local
otus  feature@extensible_dataset     active                         local
otus  feature@embedded_data          active                         local
otus  feature@bookmarks              enabled                        local
otus  feature@filesystem_limits      enabled                        local
otus  feature@large_blocks           enabled                        local
otus  feature@large_dnode            enabled                        local
otus  feature@sha512                 enabled                        local
otus  feature@skein                  enabled                        local
otus  feature@edonr                  enabled                        local
otus  feature@userobj_accounting     active                         local
otus  feature@encryption             enabled                        local
otus  feature@project_quota          active                         local
otus  feature@device_removal         enabled                        local
otus  feature@obsolete_counts        enabled                        local
otus  feature@zpool_checkpoint       enabled                        local
otus  feature@spacemap_v2            active                         local
otus  feature@allocation_classes     enabled                        local
otus  feature@resilver_defer         enabled                        local
otus  feature@bookmark_v2            enabled                        local
otus  feature@redaction_bookmarks    disabled                       local
otus  feature@redacted_datasets      disabled                       local
otus  feature@bookmark_written       disabled                       local
otus  feature@log_spacemap           disabled                       local
otus  feature@livelist               disabled                       local
otus  feature@device_rebuild         disabled                       local
otus  feature@zstd_compress          disabled                       local
otus  feature@draid                  disabled                       local
otus  feature@zilsaxattr             disabled                       local
otus  feature@head_errlog            disabled                       local
otus  feature@blake3                 disabled                       local
otus  feature@block_cloning          disabled                       local
otus  feature@vdev_zaps_v2           disabled                       local

[root@OTUS ~]# zfs get all otus
NAME  PROPERTY              VALUE                  SOURCE
otus  type                  filesystem             -
otus  creation              Fri May 15  4:00 2020  -
otus  used                  2.04M                  -
otus  available             350M                   -
otus  referenced            24K                    -
otus  compressratio         1.00x                  -
otus  mounted               yes                    -
otus  quota                 none                   default
otus  reservation           none                   default
otus  recordsize            128K                   local
otus  mountpoint            /otus                  default
otus  sharenfs              off                    default
otus  checksum              sha256                 local
otus  compression           zle                    local
otus  atime                 on                     default
otus  devices               on                     default
otus  exec                  on                     default
otus  setuid                on                     default
otus  readonly              off                    default
otus  zoned                 off                    default
otus  snapdir               hidden                 default
otus  aclmode               discard                default
otus  aclinherit            restricted             default
otus  createtxg             1                      -
otus  canmount              on                     default
otus  xattr                 on                     default
otus  copies                1                      default
otus  version               5                      -
otus  utf8only              off                    -
otus  normalization         none                   -
otus  casesensitivity       sensitive              -
otus  vscan                 off                    default
otus  nbmand                off                    default
otus  sharesmb              off                    default
otus  refquota              none                   default
otus  refreservation        none                   default
otus  guid                  14592242904030363272   -
otus  primarycache          all                    default
otus  secondarycache        all                    default
otus  usedbysnapshots       0B                     -
otus  usedbydataset         24K                    -
otus  usedbychildren        2.01M                  -
otus  usedbyrefreservation  0B                     -
otus  logbias               latency                default
otus  objsetid              54                     -
otus  dedup                 off                    default
otus  mlslabel              none                   default
otus  sync                  standard               default
otus  dnodesize             legacy                 default
otus  refcompressratio      1.00x                  -
otus  written               24K                    -
otus  logicalused           1020K                  -
otus  logicalreferenced     12K                    -
otus  volmode               default                default
otus  filesystem_limit      none                   default
otus  snapshot_limit        none                   default
otus  filesystem_count      none                   default
otus  snapshot_count        none                   default
otus  snapdev               hidden                 default
otus  acltype               off                    default
otus  context               none                   default
otus  fscontext             none                   default
otus  defcontext            none                   default
otus  rootcontext           none                   default
otus  relatime              on                     default
otus  redundant_metadata    all                    default
otus  overlay               on                     default
otus  encryption            off                    default
otus  keylocation           none                   default
otus  keyformat             none                   default
otus  pbkdf2iters           0                      default
otus  special_small_blocks  0                      default
otus  prefetch              all                    default

[root@OTUS ~]# zfs get available otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -

[root@OTUS ~]# zfs get readonly otus
NAME  PROPERTY  VALUE   SOURCE
otus  readonly  off     default

[root@OTUS ~]# zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local

[root@OTUS ~]# zfs get compression otus
NAME  PROPERTY     VALUE           SOURCE
otus  compression  zle             local

[root@OTUS ~]# zfs get checksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local

[root@OTUS ~]# wget -O otus_task2.file --no-check-certificate https://drive.usercontent.google.com/download?id=1wgxjih8YZ-cqLqaZVa0lA3h3Y029c3oI&export=download
[1] 2512
[root@OTUS ~]#
Redirecting output to ‘wget-log’.
[root@OTUS ~]# zfs receive otus/test@today < otus_task2.file
[root@OTUS ~]# ls -la
total 12500
dr-xr-x---.  7 root root    4096 Sep 22 15:04 .
dr-xr-xr-x. 24 root root    4096 Sep 22 15:01 ..
-rw-------   1 root root   12107 Sep 22 14:32 .bash_history
-rw-r--r--.  1 root root      18 May 11  2022 .bash_logout
-rw-r--r--.  1 root root     141 May 11  2022 .bash_profile
-rw-r--r--.  1 root root     429 May 11  2022 .bashrc
drwx------   3 root root    4096 Sep 16 08:34 .cache
drwx------   3 root root    4096 Sep 16 08:34 .config
-rw-r--r--.  1 root root     100 May 11  2022 .cshrc
-rw-------   1 root root      20 Sep 22 15:04 .lesshst
drwx------   3 root root    4096 Sep 16 08:34 .local
drwx------   2 root root    4096 Sep 15 11:05 .ssh
-rw-r--r--.  1 root root     129 May 11  2022 .tcshrc
-rw-------   1 root root   11292 Sep 22 14:55 .viminfo
-rw-r--r--   1 root root 7275140 Dec  6  2023 archive.tar.gz
-rw-r--r--   1 root root    2808 Sep 17 15:22 installed.txt
-rw-r--r--   1 root root 5432736 Dec  6  2023 otus_task2.file
-rw-r--r--   1 root root       0 Sep 15 14:46 typescript
-rw-r--r--   1 root root    1110 Sep 22 14:55 wget-log
drwxr-xr-x   2 root root    4096 May 15  2020 zpoolexport

[root@OTUS ~]# find /otus/test -name "secret_message"
/otus/test/task1/file_mess/secret_message
[root@OTUS ~]# cat /otus/test/task1/file_mess/secret_message
https://otus.ru/lessons/linux-hl/

```