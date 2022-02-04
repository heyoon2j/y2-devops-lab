sudo -i


lsblk
fdisk /dev/nvme1n1
mkfs.ext4 /dev/nvme1n1

vi /etc/fstab
UUID=abc    /data   ext4    defaults    0   0
10.1.1.1:/  /shared nfs4    nfsvers=4.1,rsize= ,wsize= ,hard,timeo= ,retrans=2,noresvpor    0   0

mount -a


useradd matrix
passwd matrix

mkdir /data
mkdir /log
mkdir /app
mkdir /app/matrix