#! /bin/bash

# show the Debian RSA and EC-DSA host key fingerprints as MD5 and SHA256 each

ssh-keygen -l -E md5 -f /etc/ssh/ssh_host_rsa_key.pub
awk '{print $2}' /etc/ssh/ssh_host_rsa_key.pub | base64 -d | sha256sum -b | awk '{print $1}' | xxd -r -p | base64
ssh-keygen -l -E md5 -f /etc/ssh/ssh_host_ecdsa_key.pub
awk '{print $2}' /etc/ssh/ssh_host_ecdsa_key.pub | base64 -d | sha256sum -b | awk '{print $1}' | xxd -r -p | base64
