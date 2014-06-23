while [[ true ]]; do
	(sudo -u ubuntu bash ./poll_update.sh) || (sudo -u ubuntu bash ./poll_client.sh) || sleep 5
done