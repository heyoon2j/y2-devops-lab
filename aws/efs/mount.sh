# Make Directory
sudo -i
mkdir /shared


# Modify fstab
# mount -t [F_SYS] -o [OPTION] [NFS_IP]:[NFS_Dir] [Shared_DIR]
vi /etc/fstab
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport [NFS_IP]:[NFS_Dir] [Shared_DIR]


# Mount
mount -a
