install_haproxy:
  pkg.installed:
    - name: haproxy

haproxy_config:
  file.managed:
    - source: salt://haproxy/config/haproxy.cfg
    - name: /etc/haproxy/haproxy.cfg
    - mode: 0640
    - user: root
    - group: haproxy
    - template: jinja
    - create: True
    - makedirs: True

start_service:
  service.running:
    - name: haproxy
    - enable: True
    - reload: True
    - watch: 
        - file: haproxy_config
    - require:
        - pkg: haproxy
