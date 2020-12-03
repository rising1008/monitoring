# monitoring

Skywalker の monitoring プロジェクトです。

ユーザ登録を行うための Cloud9 に関連するソースコードもこのリポジトリに含まれます。

## プロジェクト構造

```
.
├─cloud9: Cloud9 に関連するソースを格納するディレクトリ
│   ├─assets: README で使用する画像などを格納するディレクトリ
│   ├─user-registration: ユーザ登録に関連するソースを格納するディレクトリ
│   │       ├─scripts: ユーザを自動登録するための shell スクリプトを格納するディレクトリ
│   │       └─README.md: ユーザ登録方法に関するREADME
│   ├─sensor-data-converter: センサーデータ変換に関連するソースを格納するディレクトリ
│   │       ├─scripts: センサーデータ変換するための python スクリプトを格納するディレクトリ
│   │       └─README.md: センサーデータ変換に関するREADME
│   └─README.md: Cloud9の設定に関するREADME
├─scripts:
├─src
│   ├─cfn: CFnテンプレートを格納するディレクトリ
│   └─lambda: 外形監視のためのソースコードを格納するディレクトリ
└─README.md: 本ドキュメント
```
