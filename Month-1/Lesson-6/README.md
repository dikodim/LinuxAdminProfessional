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
[root@OTUS ~]# yum install -y wget rpmdevtools rpm-build createrepo \
 yum-utils cmake gcc git nano
Rocky Linux 9 - Extras                                                                                                                                      5.5 kB/s | 2.9 kB     00:00
Package rpm-build-4.16.1.3-37.el9.x86_64 is already installed.
Package gcc-11.5.0-5.el9_5.x86_64 is already installed.
Package git-2.47.3-1.el9_6.x86_64 is already installed.
Dependencies resolved.
============================================================================================================================================================================================
 Package                                            Architecture                          Version                                            Repository                                Size
============================================================================================================================================================================================
Installing:
 cmake                                              x86_64                                3.26.5-2.el9                                       appstream                                8.7 M
 createrepo_c                                       x86_64                                0.20.1-2.el9                                       appstream                                 73 k
 nano                                               x86_64                                5.6.1-7.el9                                        baseos                                   691 k
 rpmdevtools                                        noarch                                9.5-1.el9                                          appstream                                 75 k
 wget                                               x86_64                                1.21.1-8.el9_4                                     appstream                                768 k
 yum-utils                                          noarch                                4.3.0-20.el9                                       baseos                                    35 k
Installing dependencies:
 cmake-data                                         noarch                                3.26.5-2.el9                                       appstream                                1.7 M
 cmake-filesystem                                   x86_64                                3.26.5-2.el9                                       appstream                                 11 k
 cmake-rpm-macros                                   noarch                                3.26.5-2.el9                                       appstream                                 10 k
 createrepo_c-libs                                  x86_64                                0.20.1-2.el9                                       appstream                                 99 k
 dnf                                                noarch                                4.14.0-25.el9                                      baseos                                   466 k
 python3-argcomplete                                noarch                                1.12.0-5.el9                                       appstream                                 61 k
 python3-chardet                                    noarch                                4.0.0-5.el9                                        baseos                                   209 k
 python3-idna                                       noarch                                2.10-7.el9_4.1                                     baseos                                    97 k
 python3-pysocks                                    noarch                                1.7.1-12.el9                                       baseos                                    34 k
 python3-requests                                   noarch                                2.25.1-10.el9_6                                    baseos                                   115 k
 python3-urllib3                                    noarch                                1.26.5-6.el9                                       baseos                                   187 k
 vim-filesystem                                     noarch                                2:8.2.2637-22.el9_6                                baseos                                   9.3 k

Transaction Summary
============================================================================================================================================================================================
Install  18 Packages

Total download size: 13 M
Installed size: 50 M
Downloading Packages:
(1/18): vim-filesystem-8.2.2637-22.el9_6.noarch.rpm                                                                                                         112 kB/s | 9.3 kB     00:00
(2/18): yum-utils-4.3.0-20.el9.noarch.rpm                                                                                                                    25 kB/s |  35 kB     00:01
(3/18): python3-idna-2.10-7.el9_4.1.noarch.rpm                                                                                                               67 kB/s |  97 kB     00:01
(4/18): python3-pysocks-1.7.1-12.el9.noarch.rpm                                                                                                             1.4 MB/s |  34 kB     00:00
(5/18): python3-chardet-4.0.0-5.el9.noarch.rpm                                                                                                              153 kB/s | 209 kB     00:01
(6/18): python3-urllib3-1.26.5-6.el9.noarch.rpm                                                                                                              12 MB/s | 187 kB     00:00
(7/18): python3-requests-2.25.1-10.el9_6.noarch.rpm                                                                                                         7.9 MB/s | 115 kB     00:00
(8/18): nano-5.6.1-7.el9.x86_64.rpm                                                                                                                          15 MB/s | 691 kB     00:00
(9/18): dnf-4.14.0-25.el9.noarch.rpm                                                                                                                         14 MB/s | 466 kB     00:00
(10/18): python3-argcomplete-1.12.0-5.el9.noarch.rpm                                                                                                        6.0 MB/s |  61 kB     00:00
(11/18): createrepo_c-0.20.1-2.el9.x86_64.rpm                                                                                                                13 MB/s |  73 kB     00:00
(12/18): createrepo_c-libs-0.20.1-2.el9.x86_64.rpm                                                                                                           15 MB/s |  99 kB     00:00
(13/18): cmake-filesystem-3.26.5-2.el9.x86_64.rpm                                                                                                           1.9 MB/s |  11 kB     00:00
(14/18): cmake-rpm-macros-3.26.5-2.el9.noarch.rpm                                                                                                           2.5 MB/s |  10 kB     00:00
(15/18): cmake-data-3.26.5-2.el9.noarch.rpm                                                                                                                  22 MB/s | 1.7 MB     00:00
(16/18): rpmdevtools-9.5-1.el9.noarch.rpm                                                                                                                   2.1 MB/s |  75 kB     00:00
(17/18): wget-1.21.1-8.el9_4.x86_64.rpm                                                                                                                      13 MB/s | 768 kB     00:00
(18/18): cmake-3.26.5-2.el9.x86_64.rpm                                                                                                                       65 MB/s | 8.7 MB     00:00
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                       5.9 MB/s |  13 MB     00:02
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                                                                                                                                    1/1
  Installing       : cmake-rpm-macros-3.26.5-2.el9.noarch                                                                                                                              1/18
  Installing       : cmake-filesystem-3.26.5-2.el9.x86_64                                                                                                                              2/18
  Installing       : python3-idna-2.10-7.el9_4.1.noarch                                                                                                                                3/18
  Installing       : createrepo_c-libs-0.20.1-2.el9.x86_64                                                                                                                             4/18
  Installing       : python3-argcomplete-1.12.0-5.el9.noarch                                                                                                                           5/18
  Installing       : dnf-4.14.0-25.el9.noarch                                                                                                                                          6/18
  Running scriptlet: dnf-4.14.0-25.el9.noarch                                                                                                                                          6/18
  Installing       : python3-pysocks-1.7.1-12.el9.noarch                                                                                                                               7/18
  Installing       : python3-urllib3-1.26.5-6.el9.noarch                                                                                                                               8/18
  Installing       : python3-chardet-4.0.0-5.el9.noarch                                                                                                                                9/18
  Installing       : python3-requests-2.25.1-10.el9_6.noarch                                                                                                                          10/18
  Installing       : vim-filesystem-2:8.2.2637-22.el9_6.noarch                                                                                                                        11/18
  Installing       : cmake-3.26.5-2.el9.x86_64                                                                                                                                        12/18
  Installing       : cmake-data-3.26.5-2.el9.noarch                                                                                                                                   13/18
  Installing       : rpmdevtools-9.5-1.el9.noarch                                                                                                                                     14/18
  Installing       : yum-utils-4.3.0-20.el9.noarch                                                                                                                                    15/18
  Installing       : createrepo_c-0.20.1-2.el9.x86_64                                                                                                                                 16/18
  Installing       : wget-1.21.1-8.el9_4.x86_64                                                                                                                                       17/18
  Installing       : nano-5.6.1-7.el9.x86_64                                                                                                                                          18/18
  Running scriptlet: nano-5.6.1-7.el9.x86_64                                                                                                                                          18/18
  Verifying        : yum-utils-4.3.0-20.el9.noarch                                                                                                                                     1/18
  Verifying        : python3-idna-2.10-7.el9_4.1.noarch                                                                                                                                2/18
  Verifying        : vim-filesystem-2:8.2.2637-22.el9_6.noarch                                                                                                                         3/18
  Verifying        : python3-chardet-4.0.0-5.el9.noarch                                                                                                                                4/18
  Verifying        : python3-pysocks-1.7.1-12.el9.noarch                                                                                                                               5/18
  Verifying        : nano-5.6.1-7.el9.x86_64                                                                                                                                           6/18
  Verifying        : python3-urllib3-1.26.5-6.el9.noarch                                                                                                                               7/18
  Verifying        : python3-requests-2.25.1-10.el9_6.noarch                                                                                                                           8/18
  Verifying        : dnf-4.14.0-25.el9.noarch                                                                                                                                          9/18
  Verifying        : cmake-data-3.26.5-2.el9.noarch                                                                                                                                   10/18
  Verifying        : python3-argcomplete-1.12.0-5.el9.noarch                                                                                                                          11/18
  Verifying        : createrepo_c-0.20.1-2.el9.x86_64                                                                                                                                 12/18
  Verifying        : createrepo_c-libs-0.20.1-2.el9.x86_64                                                                                                                            13/18
  Verifying        : cmake-filesystem-3.26.5-2.el9.x86_64                                                                                                                             14/18
  Verifying        : wget-1.21.1-8.el9_4.x86_64                                                                                                                                       15/18
  Verifying        : cmake-rpm-macros-3.26.5-2.el9.noarch                                                                                                                             16/18
  Verifying        : rpmdevtools-9.5-1.el9.noarch                                                                                                                                     17/18
  Verifying        : cmake-3.26.5-2.el9.x86_64                                                                                                                                        18/18

Installed:
  cmake-3.26.5-2.el9.x86_64                      cmake-data-3.26.5-2.el9.noarch               cmake-filesystem-3.26.5-2.el9.x86_64        cmake-rpm-macros-3.26.5-2.el9.noarch
  createrepo_c-0.20.1-2.el9.x86_64               createrepo_c-libs-0.20.1-2.el9.x86_64        dnf-4.14.0-25.el9.noarch                    nano-5.6.1-7.el9.x86_64
  python3-argcomplete-1.12.0-5.el9.noarch        python3-chardet-4.0.0-5.el9.noarch           python3-idna-2.10-7.el9_4.1.noarch          python3-pysocks-1.7.1-12.el9.noarch
  python3-requests-2.25.1-10.el9_6.noarch        python3-urllib3-1.26.5-6.el9.noarch          rpmdevtools-9.5-1.el9.noarch                vim-filesystem-2:8.2.2637-22.el9_6.noarch
  wget-1.21.1-8.el9_4.x86_64                     yum-utils-4.3.0-20.el9.noarch

Complete!
```