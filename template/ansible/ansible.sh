#!/bin/bash
ansible-playbook -v -i <inventory_path> --config ansible_dev.cfg playbook.yml --limit <host> --tags <tag> --skip-tags <tag>

# [Dev]
ansible-playbook -v -i inventories/prd --config ansible_prd.cfg playbook.yml

# [Prd]
ansible-playbook -v -i inventories/prd --config ansible_prd.cfg playbook.yml
