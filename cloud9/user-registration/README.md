# user-registration

ユーザ登録処理を実行する script に関するプロジェクトです。

## 注意事項

- Cloud9 上で CSV を管理して編集する場合、正しい形式の CSV で保存してください。CSV の仕様については下記、Project の Confluence を参照してください。

    https://ty-skywalker.atlassian.net/wiki/spaces/SKYWALKER/pages/16711712


## ユーザ登録方法

以下の手順は [Cloud9 設定](../README.md#Cloud9-設定) が全て完了している想定で書かれています。

1. CSV ファイルに登録するユーザの一覧を作成する

    - CSV のファイル名は下記の表に従い、登録対象の環境により名前を変更してください。

    ■ CSV ファイルの名前
    | 環境  | ファイル名      |
    |------|----------------|
    | Demo | users-Demo.csv |
    | Test | users-Test.csv |
    | Dev  | users-Dev.csv  |

    ■ CSV で必要なパラメータ
    | 項目名    | 説明 |
    |----------|-----|
    | Email    | ユーザのメールアドレス。App にサインインする際に使われます。 |
    | Password | サインインする際に使われるパスワードです。 |
    | Language | 多言語対応のための項目です。設定可能値は以下の表を参照。 |


    ■ Language の値
    | 値 | 説明 |
    |----|------|
    | ja | 日本語で UI を表示するユーザに設定する値。 |
    | en | 英語で UI を表示するユーザに設定する値。 |

    ■ CSV の例
    ```
    "sample-ja@example.com","some-password","ja"
    "sample-en@example.com","some-password","en"
    ```

1. CSV ファイルを Cloud9 にアップロードする

    - Cloud9 IDE 上で左に表示されているディレクトリツリーから `monitoring/cloud9/user-registration/scripts` ディレクトリに作成した CSV ファイルを Drag and Drop でアップロードしてください。

1. ユーザ登録スクリプトを実行する

    - 下記の表に従って実行対象の環境用のスクリプトを実行してください。
    - スクリプトの実行は以下のいずれかの方法があります
      + Cloud9 で実行対象のスクリプトをダブルクリックで開いた状態で、画面上部の `Run` というボタンを押す
      + Terminal で該当スクリプトを実行する

    ■ 実行するスクリプト
    | 環境  | ファイル名                   |
    |------|-----------------------------|
    | Demo | `register-user-for-demo.sh` |
    | Test | `register-user-for-test.sh` |
    | Dev  | `register-user-for-dev.sh`  |
