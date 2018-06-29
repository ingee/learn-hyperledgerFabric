# run Node.js container
#
docker run -it \
  --network="my-net" \
  -p 3001:3001 \
  -v /home/ingee.kim/work/learn-hyperledgerFabric:/home/learn-hyperledgerFabric \
  node:8.11 \
  bash

# in container, do followings
# 1. cd /home/learn-hyperledgerFabric/app/store1
# 2. npm install
# 3. npm start
