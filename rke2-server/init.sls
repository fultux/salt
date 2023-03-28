{%- set rke2_version = salt['pillar.get']('rke2-server:rke2_version') -%}
{%- set use_proxy = salt['pillar.get']('rke2-server:proxy:enabled') -%}

config_forwarding:
  file.managed:
    - name: /etc/sysctl.d/90-rke2.conf
    - contents: |
        net.ipv4.conf.all.forwarding=1
        net.ipv6.conf.all.forwarding=1
    - user: root
    - group: root
    - mode: 0600

reload_sysctl:
  cmd.run:
    - name: sysctl --system
    - onchanges:
      - file: /etc/sysctl.d/90-rke2.conf


rke2_conf:
  file.managed:
    - source: salt://rke2-server/files/config.j2
    - name: /etc/rancher/rke2/config.yaml
    - mode: 0640
    - user: root
    - group: root
    - template: jinja
    - create: True
    - makedirs: True

{% if use_proxy == True %}
{% set proxy_http = salt['pillar.get']('rke2-server:proxy:proxy_http') %}
{% set proxy_https = salt['pillar.get']('rke2-server:proxy:proxy_https') %}
{% set no_proxy = salt['pillar.get']('rke2-server:proxy:no_proxy') %}
create_proxy_config:
  file.managed:
    - name: /etc/default/rke2-server
    - contents: |
        HTTP_PROXY={{ proxy_http }}
        HTTPS_PROXY={{ proxy_https }}
        NO_PROXY={{ no_proxy }}
    - require: 
      - cmd: rke2_install
      - file: rke2_conf
{% endif %}

get_installer:
  file.managed:
    - source: https://get.rke2.io
    - name: /tmp/rke2_install.sh
    - mode: 0755
    - user: root
    - group: users
    - create: True
    - skip_verify: True

rke2_install:
  cmd.run:
    - name: /tmp/rke2_install.sh
    - runas: root
    - unless: systemctl status rke2-server
    - env:
      - INSTALL_RKE2_VERSION: '{{ rke2_version }}'



rke2_service:
  service.running:
    - name: rke2-server
    - enable: True
    - watch:
      - cmd: rke2_install
      - file: rke2_conf
