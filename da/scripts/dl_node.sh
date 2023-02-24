#!/bin/sh

mkdir -p /data/kzg/SRSTables

if [ ! -f "/data/kzg/g1.point" ]; then
  wget --no-check-certificate https://datalayr-testnet.s3.amazonaws.com/g1.point.3000 -O /data/kzg/g1.point
  echo 'download g1.point success'
fi

if [ ! -f "/data/kzg/g2.point" ]; then
   wget --no-check-certificate https://datalayr-testnet.s3.amazonaws.com/g2.point.3000 -O /data/kzg/g2.point
   echo 'download g2.point success'
fi

if [ ! -f "/data/kzg/SRSTables/dimE4.coset8" ]; then
   wget --no-check-certificate https://datalayr-testnet.s3.amazonaws.com/SRSTables/dimE4.coset8 -O /data/kzg/SRSTables/dimE4.coset8
   echo 'download coset8 success'
fi

if [ ! -f "/data/kzg/SRSTables/dimE4.coset32" ]; then
   wget --no-check-certificate https://datalayr-testnet.s3.amazonaws.com/SRSTables/dimE4.coset32 -O /data/kzg/SRSTables/dimE4.coset32
   echo 'download coset32 success'
fi

dl-node
