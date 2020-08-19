## 1. 前準備

`npx truffle develop`を実行した後に、migrate します。

```
migrate
```

コントラクトのインスタンスを作成します。

```
const instance = await GameFactory.deployed()
```

アカウントの一覧を取得します。

```
const accounts = await web3.eth.getAccounts()
```

## 2. ユーザ作成

使用するアカウントでユーザを作成します。以下が作成例です。  
引数は`アドレス、ユーザ名`になります。

```
instance._createUser(accounts[1], "HostUser")
instance._createUser(accounts[2], "GestUser")
```

## 3. ゲーム開始

ホストユーザがゲームを開始します。以下が作成例です。  
引数は`暗号化済の手+暗号化キー、アドレス、デポジット金額`になります。  
じゃんけん の手は`rock：グー、paper：パー、scissors：チョキ`となります。

```
instance._gameStart(web3.utils.keccak256("rock" + "key"), {from: accounts[1], value: web3.utils.toWei("1", "ether")})
```

なお、保有 ether の確認は以下の通りで行えます。

```
web3.eth.getBalance(accounts[1])
```

## 4. ゲーム参加

オープン状態のゲームの一覧を取得します。

```
instance._getOpenGame()
```

以下でゲームに参加します。
引数は`ゲームのID、暗号化済の手+暗号化キー、アドレス、送信金額`になります。
送信金額はホストが設定されたものと同値を設定します。

```
instance._joinGame(1, web3.utils.keccak256("scissors" + "key2"), {from: accounts[2], value: web3.utils.toWei("1", "ether")})
```

## 5. 手の公開

手を公開します。引数は`アドレス、ゲームのID、暗号化に使用したキー`になります。

```
instance._reveal(accounts[1], 1, "key")
instance._reveal(accounts[2], 1, "key2")
```

公開された手は以下で確認できます。`ゲームのID`を指定します。

```
instance._getRevealHands(1)
```

## 6.デポジットの引出し

デポジットを引出します。引数は`アドレス、ゲームのID`になります。

```
instance._drawDeposit(accounts[1], 1)
```
