# sensor-data-converter

センサーデータ変換処理を実行する script に関するプロジェクトです。

## 注意事項

- 変換後に出力される json ファイル名は、`12c62cfb-1d46-4efe-89f3-afb617611856.json` から変更しないでください。

## センサーデータ変換方法

以下の手順は [Cloud9 設定](../README.md#Cloud9-設定) が全て完了している想定で書かれています。

1. センサーデータのテキストファイルを Cloud9 にアップロードする

    - Cloud9 IDE 上で左に表示されているディレクトリツリーから `monitoring/cloud9/sensor-data-converter/input-files` ディレクトリにセンサーデータを Drag and Drop でアップロードしてください。

1. センサーデータ変換スクリプトを実行する

    - 下記の表に従って実行対象の環境用のスクリプトを実行してください。
    - スクリプトの実行は以下のいずれかの方法があります。
      + Cloud9 で実行対象のスクリプトをダブルクリックで開いた状態で、画面上部の `Run` というボタンを押す。
      + Terminal で該当スクリプトを実行する。

    ■ 実行するスクリプト  
    `monitoring/cloud9/sensor-data-converter/scripts/sensor-data-converter.py`

## センサーデータをWebアプリで確認する

1. 変換後のセンサーデータを Cloud9 からダウンロードする

    - 手順 [センサーデータ変換方法](#センサーデータ変換方法) が完了すると `monitoring/cloud9/sensor-data-converter/output-file` に変換後のセンサーデータ( json ファイル)が作成されています。
    - [json ファイル名](#注意事項)は、変更しないでください。
    - Cloud9 IDE 上で左に表示されているディレクトリツリーで 上記 json ファイルを選択した状態で右クリックして、Download を選択してください。

1. S3 へ json ファイルをアップロードする

    - [S3 バケット](https://s3.console.aws.amazon.com/s3/buckets/skywalker-3d-model-importer-3dmodeldatarepository-1gltwr8olsws7?region=ap-northeast-1&tab=objects) に json ファイルをアップロードします。
    - S3 バケットの直下にある sensor-data フォルダの直下に、json ファイルを格納してください。  
    ※ sensor-data/12c62cfb-1d46-4efe-89f3-afb617611856.json

1. インポーターパイプラインをを実行する

    - [インポーターパイプライン](https://ap-northeast-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/skywalker-3d-model-importer-pipeline-PipelineStack-POQEO91TDXEH-Pipeline-1G59GCH61IKD3/view?region=ap-northeast-1)を実行して、テスト環境および、デモ環境へのデプロイを行います。  
    ※ここでは、インポーターパイプラインの操作方法は記載しません。
    - 各環境へのデプロイ完了後に、Web アプリからセンサーデータを確認してください。