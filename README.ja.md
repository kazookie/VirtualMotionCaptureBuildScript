# VirtualMotionCaptureBuildScript
(バーチャルモーションキャプチャービルドスクリプト)

バーチャルモーションキャプチャーのビルドを自動で実施します。

## テスト環境
- Windows 10 バージョン 22H2
- PowerShell 5.1
- Unity Hub 3.4.1
- Unity Editor 2019.4.8f1
- Visual Studio Community 2019

## 使い方
1. このリポジトリをダウンロードする
2. build.bat を実行する

## 説明
- build.bat
PKGBUILD.ps1 を実行するバッチファイルです。
PowerShellの実行ポリシーを回避するため、バッチファイルからps1ファイルを呼び出します。

- PKGBUILD.ps1
メインのスクリプトファイルです。
ビルド環境の確認、ソースコード・アセットのダウンロード、展開、配置などのビルド手順を実施します。

- BuildAssistant
Unityエディタの操作(依存パッケージのインポート、ビルド)を自動化するために追加するアセットです。

## リファレンス
- [VirtualMotionCapture](https://github.com/sh-akira/VirtualMotionCapture)
- *1 [Unity CommandLine Arguments](https://docs.unity3d.com/ja/2019.4/Manual/CommandLineArguments.html)
- *2 [Execute editor script on project load before engine script compile errors](https://forum.unity.com/threads/execute-editor-script-on-project-load-before-engine-script-compile-errors.512977/)
- *3 [Assembly Definitions](https://docs.unity3d.com/ja/2019.4/Manual/ScriptCompilationAssemblyDefinitionFiles.html)