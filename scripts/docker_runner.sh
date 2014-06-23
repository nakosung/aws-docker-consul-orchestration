#include worker.sh

mkdir -p /home/ubuntu
cd /home/ubuntu

#embed run_aliased.sh utils/run_aliased.sh +x
#embed poll_run.sh utils/poll_run.sh +x
#embed poll_kill.sh utils/poll_kill.sh +x

sudo mv run_aliased.sh /usr/local/bin

#embed restart_containers.sh utils/restart_containers.sh +x
#embed loop.sh utils/loop_runner.sh +x
#embed /etc/init/docker-runner.conf utils/docker-runner.conf

start docker-runner

expose.sh worker 22