#!/bin/bash

set -e 

OPT=${1:-"online"}
CFGFILES=(ansible.cfg hosts vars.yml)

if [ x"$OPT" = x"offline" ]; then
  ./scripts/offline_services.sh --up
  sudo dnf -y install python39
  python3.9 -m venv ~/.envs/burrito
  . ~/.envs/burrito/bin/activate
  pip install --no-index --find-links /mnt/pypi /mnt/pypi/{pip,wheel}-*
  pip install --no-index --find-links /mnt/pypi \
               --requirement requirements.txt
  pushd /mnt/ansible_collections
    ansible-galaxy install --force -r requirements.yml
  popd
else
  sudo dnf -y install git python3 python39 python3-cryptography epel-release
  python3.9 -m venv ~/.envs/burrito
  . ~/.envs/burrito/bin/activate
  python -m pip install -U pip
  python -m pip install wheel
  python -m pip install -r requirements.txt
  ansible-galaxy install -r ceph-ansible/requirements.yml
fi

for CFG in ${CFGFILES[@]}; do
  if [ -f "${CFG}" ]; then
    mv ${CFG} ${CFG}.$(date --iso-8601='seconds')
  fi
  cp ${CFG}.sample ${CFG}
done

if [ -d "group_vars" ]; then
  mv group_vars group_vars.$(date --iso-8601='seconds')
fi
mkdir -p group_vars/all
cp ceph_vars.yml.tpl group_vars/all/ceph_vars.yml
cp netapp_vars.yml.tpl group_vars/all/netapp_vars.yml

./scripts/patch.sh
