# srs-rik-clients
RIK Clients for the Shared Registry System by NZRS

To install:

curl https://apt.nzrs.net.nz/packages.asc | sudo apt-key add -
echo 'deb https://apt.nzrs.net.nz/ trusty main' | sudo tee /etc/apt/sources.list.d/srs.list
sudo apt-get update 1>/dev/null

Install NZRS build dependencies:
sudo apt-get install libencoding-fixlatin-perl libcrypt-gpgme-perl

Install SRS RIK client:
sudo apt-get install srs-rik-clients


To build your own package:

apt-get install devscripts libassuan0 libfile-slurp-perl libgpgme11 libjson-any-perl
git clone xxx
cd xxx ; debuild
