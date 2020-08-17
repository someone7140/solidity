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
引数は`アドレス、ユーザ名、初期保有金額`になります。

```
instance._createUser(accounts[0], "HostUser", 10000)
instance._createUser(accounts[1], "GestUser", 10000)
```

## 3. ゲーム開始

ホストユーザがゲームを開始します。以下が作成例です。  
引数は`アドレス、じゃんけん の手、デポジット金額、暗号化用のキー`になります。  
じゃんけん の手は`rock：グー、paper：パー、scissors：チョキ`となります。

```
instance._gameStart(accounts[0], "rock", 100, "key")
```

## 4. ゲーム参加

オープン状態のゲームの一覧を取得します。
```
instance._getOpenGame()
```

以下でゲームに参加します。
引数は`アドレス、ゲームのID、じゃんけん の手、暗号化用のキー`になります。  

```
instance._joinGame(accounts[1], 1, "scissors", "key2")
```

## 5. 手の公開

手を公開します。引数は`アドレス、ゲームのID`になります。  

```
instance._reveal(accounts[0], 1)
instance._reveal(accounts[1], 1)
```

公開された手は以下で確認できます。`ゲームのID`を指定します。
```
instance._getRevealHands(1)
```

## 6.デポジットの引出し

デポジットを引出します。引数は`アドレス、ゲームのID`になります。 
```
instance._drawDeposit(accounts[0], 1)
```


なお、保有金額は以下で確認可能です。`アドレス`を指定します。
```
instance._showAmount(accounts[0]);
```
