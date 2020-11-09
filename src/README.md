# monitoring CloudFormation

Skywalker の monitoring 用 CloudFormation に関するドキュメントです。


## 監視項目
本CloudFormationをデプロイすることにより、以下の項目の監視設定を行います。
 - 死活監視（外形監視）
   - フロントエンドへのアクセス
   - バックエンドへのアクセス
 - クラウドサービスのメトリクス監視
   - API Gateway 5xxエラー
   - API Gateway 4xxエラー
   - API Gateway レイテンシ
   - DynamoDB キャパシティユニット消費
   - DynamoDB スロットリング
 - クラウドサービス操作ログの監視
   - AWSコンソールログインユーザ
   - インポータ用S3へのアクセス情報
   - インポータpipelineの実行

## 前提条件
- cognito の アプリクライアントの設定で、「ADMIN_USER_PASSWORD_AUTH」が有効になっていること。



## デプロイ手順

1. S3バケットの作成

    - monitoringのCFnテンプレートはネスト構成のためStackをデプロイする際に利用するCFnテンプレート格納用のS3バケットを作成します。

    - 作成したS3バケットの名称は、「手順: 2.CloudFormation のコンフィグレーションの作成」で利用します。

2. CloudFormation のコンフィグレーションの作成

    - scripts/env.templateをscripts/.envにコピーします。

|  設定項目              |  設定内容                                                                                         |
| ---------------------- | ------------------------------------------------------------------------------------------------- |
|  SYSTEM_ID             |  skywalker                                                                                        |
|  COMPONENT_ID          |  monitoring                                                                                 |
|  S3_BUCKET_NAME        |  「手順: 2. S3バケットの作成」で作成したS3バケット名                                              |
|  AWS_PROFILE           |  AWS CLIのプロファイル名(defaultコンフィグレーションを利用する場合は、指定する必要はありません。) |
|  TABLE_NAME     |  監視対象の DynamoDB テーブル名                                                                                     |
|  API_NAME |  監視対象の API Gateway 名                                             |
|  IMPORTER_REPOSITORY_ARN    |  監視対象のインポータ用S3バケットのArn                                                                            |
|  IMPORTER_PIPELINE_NAME |  監視対象のインポータ用パイプライン名                                              |
|  FRONTEND_URL |  外形監視のフロントエンドURL                                              |
|  BACKEND_URL |  外形監視のバックエンドURL                                               |
|  USER_POOL_ID |  バックエンド認証のCognitoのユーザプールID                                              |
|  CLIENT_ID |  バックエンド認証のCognitoのクライアントID                                              |
|  COGNITO_USERNAME |  バックエンド認証のユーザ名                                              |
|  COGNITO_PASSWORD |  バックエンド認証のパスワード                                              |

4. デプロイスクリプトの実行

    - 以下の通りスクリプトを実行しパイプラインをデプロイします。

    ```
     $ bash scripts/deploy-pipeline.sh
    ```

## パイプラインの削除

monitoring の削除は、CloudFormationのManagement ConsoleからStackを削除することで行います。Stackの削除は、依存関係の逆順に行う必要があります。
