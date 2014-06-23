while [[ true ]]; do
	./poll_kill.sh kill || ./poll_run.sh run || sleep 5 && ./poll_run.sh failed
    ./restart_containers.sh
done