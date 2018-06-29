# Hyperledger Fabric을 이용한 상품 거래 시스템 개발

> 개발환경은 우분투 16.04 기반으로 테스트하여 작성하였습니다.

## Fabric 네트워크 구축

### 사전 개발 환경 준비
* Docker
    * 17.06.2-ce 이상
* Docker-compose
    * 1.14.0 이상 버전
* Golang
    * 1.10.x 버전 이상
* Nodejs
    * 8.x 버전
* NPM
    * 5.6
* 우분투
    * g++ 설치


### VM 네트워크 설정

#### Docker swarm 네트워크 설정

* VM1

VM1에서 다음의 명령을 실행

```
$ docker swarm init
$ docker swarm join-token manager
```
위의 명령을 실행하면 아래와 같은 메시지를 확인 할 수 있으며 VM2에서 명령을 실행합니다.
```
docker swarm join --token SWMTKN-1-3uhjzu2hfh9x3yhwzleh326wud22yaee65kqb88pczx4m0uwij-40ksc4c7pnmj9b3okxdmc9wqp 10.142.0.3:2377
```

다음의 명령을 통해서 도커 네트워크를 생성합니다.
```
$ docker network create --attachable --driver overlay my-net
```

github repository를 clone 합니다.
```
$ git clone https://github.com/ingee/learn-hyperledgerFabric
$ cd mymarket
```

### Fabric 네트워크를 위한 아티팩트 생성

인증서 생성
```
$ cryptogen generate --config=./crypto-config.yaml
```

아티팩트 생성
```
$ mkdir channel-artifacts
$ export FABRIC_CFG_PATH=$PWD
$ export CHANNEL_NAME=mymarketchannel
$ configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block
$ configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
$ configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Store1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Store1MSP
$ configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Store2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Store2MSP
```

learn-hyperledgerFabric  프로젝트 디렉토리를 압축하여 VM2로 복사합니다.
```
$ cd ../
$ tar -cvf learn-hyperledgerFabric.tar learn-hyperledgerFabric
```

새로 생성된 인증서에서 CA Key파일의 정보를 YAML 파일에서 수정합니다.

* ca.store1.mymarket.com 를 위한 인증서 위치
```
~/mymarket/crypto-config/peerOrganizations/store1.mymarket.com/ca
$ ls
66c2bea4ef42056d1f1807c978c8ec783e403557e1311c8beb1118244092ac4f_sk  ca.store1.mymarket.com-cert.pem
```

Key 파일명(66c2bea4ef42056d1f1807c978c8ec783e403557e1311c8beb1118244092ac4f_sk)을 node1.yaml의 다음 위치에 적용합니다.
```
  ca.store1.mymarket.com:
    image: hyperledger/fabric-ca
    environment:
      ...
      - FABRIC_CA_SERVER_CA_CERTFILE=/etc/hyperledger/fabric-ca-server-config/ca.store1.mymarket.com-cert.pem
      - FABRIC_CA_SERVER_CA_KEYFILE=/etc/hyperledger/fabric-ca-server-config/66c2bea4ef42056d1f1807c978c8ec783e403557e1311c8beb1118244092ac4f_sk
    ports:
      ...
```
위와 같이 ```ca.mymarket.com```, node2.yaml에서 ```ca2.store2.mymarket.com``` 도 수정합니다.


### Fabric 네트워크 실행
각 VM에서 도커 컨테이너를 실행합니다.

* VM1
  mymarket 디렉토리로 이동합니다.
```
$ docker-compose -f node1.yaml up -d
```

* VM2
```
$ docker-compose -f node2.yaml up -d
```


## ChainCode 실행 테스트
### cli 컨테이너 접속 (@VM2)
```
$ docker exec -it cli bash
```

### chaincode 배포 (@VM2/cli)
```
# ./scripts/sript.sh mymarketchannel 10 60
```

### chaincode 실행 (@VM2/cli)
```
# peer chaincode query -n marketcc -C mymarketchannel -c '{"Args":["getProductList",""]}'
...
# peer chaincode invoke -n marketcc -C mymarketchannel -c '{"Args":["getProductList",""]}'
...
```


## WebApp 실행
### node.js 컨테이너 실행 (@VM1)
```
$ docker run -it \
    --network="my-net" \
    -p 3001:3001 \
    -v /home/ingee.kim/work/learn-hyperledgerFabric:/home/learn-hyperledgerFabric \
    node:8.11 \
    bash

... from now console is in container ...
# cd /home/learn-hyperledgerFabric/app/store1
# npm install
# node enrollAdmin.js
# node app.js
...
```

### web api 호출 (@VM1의 3001 포트에 접근 가능한 콘솔)
web api 정상 접속 확인
```
$ curl -X GET -H 'Content-Type: application/json' -i http://localhost:3001/
```

사용자 등록
```
$ curl -X POST -H 'Content-Type: application/json' -i http://localhost:3001/usermanage/user --data '{"userId":"store1_testuser_1"}'
```

제품 등록
```
curl -X POST -H 'Content-Type: application/json' -i http://localhost:3001/transaction/product --data '{"enrollmentID":"store1_testuser_1","productName":"testprod_1","qty":"10"}'
```

web api 호출시마다 node.js 컨테이너의 콘솔 출력 확인
(끝)