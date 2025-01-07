# 1. open [launchpad](http://localhost:3000/)

1. click the button, start the deposit process  
<img src="doc/deposit/images/image-0.png"  style="zoom: 10%;" />

2. read the deposit notice
<img src="doc/deposit/images/image-1.png"  style="zoom: 10%;" />

3. select cl client, need to use geth
<img src="doc/deposit/images/image-2.png"  style="zoom: 10%;" />

4. click continue
<img src="doc/deposit/images/image-3.png"  style="zoom: 10%;" />

5. select el client, need to use lighthouse
<img src="doc/deposit/images/image-4.png"  style="zoom: 10%;" />

6. click continue
<img src="doc/deposit/images/image-5.png"  style="zoom: 10%;" />

7. download [deposit cli](https://github.com/ethereum/staking-deposit-cli/releases)
<img src="doc/deposit/images/image-6.png"  style="zoom: 10%;" />

# 2. generate deposit data
1. run cli 
```
deposit new-mnemonic --num_validators 1
```
2. select the language you can understand
<img src="doc/deposit/images/image-7.png"  style="zoom: 30%;" />

3. select the mnemonic language
<img src="doc/deposit/images/image-8.png"  style="zoom: 30%;" />

4. select the network, only can select mainnet
<img src="doc/deposit/images/image-9.png"  style="zoom: 30%;" />

5. input the password for creating keystore
<img src="doc/deposit/images/image-10.png"  style="zoom: 30%;" />

6. input the password for creating keystore again
<img src="doc/deposit/images/image-11.png"  style="zoom: 30%;" />

7. save your mnemonic
<img src="doc/deposit/images/image-12.png"  style="zoom: 30%;" />

8. input your mnemonic again
<img src="doc/deposit/images/image-13.png"  style="zoom: 30%;" />

9. check the deposit data file
<img src="doc/deposit/images/image-14.png"  style="zoom: 30%;" />

10. upload the deposit data file to the launchpad
<img src="doc/deposit/images/image-15.png"  style="zoom: 10%;" />

11. connect metamask
<img src="doc/deposit/images/image-16.png"  style="zoom: 10%;" />

12. deposit
<img src="doc/deposit/images/image-17.png"  style="zoom: 10%;" />

# 3. start the node
1.run node
```
export EXP_NODE_DATA_DIR="${PWD}/data"
export EXP_NODE_BIN_E_CLIENT="${PWD}/exp-e-client"
export EXP_NODE_BIN_C_CLIENT="${PWD}/exp-c-client"
export EXP_NODE_BIN_SCD="${PWD}/scd"
export EXP_NODE_BIN_EXPANDER="${PWD}/expander-exec"
export EXP_NODE_GENESIS="${PWD}/genesis_testnet"
export EXP_NODE_PEER="10.128.15.210"
sudo apt install mpich
sudo cp ${EXP_NODE_BIN_EXPANDER} /usr/local/bin/

./join_node.sh
```

2. import validator
```
${PWD}/exp-c-client validator_manager import --keystore-file=keystore-m_12381_3600_0_0_0-1735093940.json --password='12345678' --vc-token=${EXP_NODE_DATA_DIR}/cl/vc/validators/api-token.txt --vc-url=http://127.0.0.1:5062
```

3. check the validator
```
${PWD}/exp-c-client validator_manager list --vc-token=${EXP_NODE_DATA_DIR}/cl/vc/validators/api-token.txt --vc-url=http://127.0.0.1:5062
```

# 4. exit validator
```
${PWD}/exp-c-client account validator exit --testnet-dir=${EXP_NODE_DATA_DIR}/genesis --datadir=${EXP_NODE_DATA_DIR}/cl/vc --keystore=keystore-m_12381_3600_0_0_0-1735093940.json --beacon-node=http://127.0.0.1:5052
```
1. input the password of keystore file
<img src="doc/deposit/images/image-18.png"  style="zoom: 20%;" />

2. input 'Exit my validator'
<img src="doc/deposit/images/image-19.png"  style="zoom: 15%;" />

3. wait for exit
<img src="doc/deposit/images/image-20.png"  style="zoom: 10%;" />
