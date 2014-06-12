aws-docker-consul-orchestration
===============================

* amazon ec2에 docker, consul을 이용한 cluster를 구축/관리하는 것을 목적으로 합니다.
* cluster config은 cson으로 작성하며, 이 설정이 유효하도록 관리합니다.

* bundled config을 실행하기 위해서는 .elastic_ip/ssh,http와 .ssh/id_rsa,id_rsa.pub이 필요합니다.
* id_rsa*는 cluster 내에서 사용할 credential입니다.

Roadmap
-------
 * docker+consul-service 등 instance 내부 setup의 incremental한 관리 추가

Setup
-----
 * ~/.aws/credentials
 * mkdir .ssh && ssh-keygen -f .ssh/id_rsa -P ''
 