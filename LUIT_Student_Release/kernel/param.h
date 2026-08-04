/* Implementation note. */

#ifndef LUIT_PARAM_H
#define LUIT_PARAM_H

#define NCPU        8    /* maximum harts we will manage                    */
#define NPROC      64    /* maximum simultaneous processes                  */
#define NOFILE     16    /* open files per process (fd table size)          */
#define NFILE     100    /* open files in the whole system                  */
#define NINODE     50    /* in-core inode cache size                        */
#define NDEV       10    /* device-switch table size                        */
#define NBUF       30    /* Implementation note. */
#define MAXARG     16    /* max exec() arguments                            */
#define MAXPATH   128    /* longest path name                               */
#define ROOTDEV     0    /* device number of the root LuitFS disk           */
#define PIPESIZE  512    /* bytes buffered in a pipe                        */

#endif
