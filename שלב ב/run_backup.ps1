docker exec -t postgres_db pg_dump -U admin -d routes_db -F c -f /tmp/backup2.dump
docker cp postgres_db:/tmp/backup2.dump "שלב ב\backup2.dump"
