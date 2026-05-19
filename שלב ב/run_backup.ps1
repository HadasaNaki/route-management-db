# run_backup.ps1 (Stage B)
# Wrapper to run backup inside docker and copy to host
docker exec -t postgres_db pg_dump -U admin -d routes_db -F c -f /tmp/backup2.dump
docker cp postgres_db:/tmp/backup2.dump "stage_b\backup2.dump"
