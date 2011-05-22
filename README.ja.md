Capistranoを使ってsymfonyアプリケーションをデプロイする
=======================================================

Capistranoは、複数のサーバーでスクリプトを実行するためのオープンソースのツールです。主に、アプリケーションを簡単にデプロイするために使います。もともとは、Railsアプリケーションをデプロイするために作られましたが、Rails以外のアプリケーションをデプロイするようにカスタマイズすることも簡単です。そこで、symfonyアプリケーションに対して動作するデプロイ「レシピ」を開発しました。

## 前提条件 ##

- Symfony 1.4以降、または Symfony2
- デプロイ先のサーバーへのSSHアクセス権
- 実行するコンピュータ上にRubyとRubyGemsがインストールされていること (デプロイ先のサーバーでは不要)

## Capifonyのインストール ##

### RubyGems.orgから ###

	sudo gem install capifony

### GitHubから ###

	git clone git://github.com/everzet/capifony.git
	cd capifony
	gem build capifony.gemspec
	sudo gem install capifony-{version}.gem

## Capifonyを使うようにプロジェクトを設定する ##

プロジェクトのルートディレクトリへ移動し、次のコマンドを実行します。

	capifony .

このコマンドを実行すると、プロジェクトのルートディレクトリに`Capfile`が作成され、symfony では`config`ディレクトリに、Symfony2では`app/config`ディレクトリに`deploy.rb`設定ファイルが作成されます。

`config/deploy.rb`ファイルに、デプロイ先サーバーへの接続情報などを設定してください。

## サーバーの設定 ##

これで、デプロイプロセスを開始できます。デプロイ先のサーバーでCapistrano用のファイル構成を初期化するには、次のコマンドを実行します。

	cap deploy:setup

このコマンドを実行すると、デプロイ先のサーバーに次のようなフォルダ構成が作られます。

	`-- /var/www/demo.everzet.com
	  |-- current → /var/www/demo.everzet.com/releases/20100512131539
	  |-- releases
	    |-- 20100512131539
	    |-- 20100509150741
	    `-- 20100509145325
	  `-- shared
	    |-- log
	    |-- config
	      `-- databases.yml
	    `-- web
	      `-- uploads

releaseディレクトリ以下のフォルダは、実際にデプロイされたプロジェクトのコードで、タイムスタンプごとのフォルダになります。Capistranoによって、sharedフォルダにあるlogディレクトリとweb/uploadsディレクトリへのシンボリックリンクが、アプリケーションディレクトリに作られます。ですので、新しいバージョンのコードをデプロイした時に、これらのディレクトリにあるファイルが消えてしまうということはありません。

アプリケーションをデプロイするには、単純に次のコマンドを実行します。

	cap deploy

## デプロイ ##

SSHの認証に使うユーザー名とパスワードを指定するには、`config/deploy.rb`ファイルに次の設定を追加します。

    set :user, 'username'
    set :password, 'password'

デプロイ先のサーバーのデータベース設定を行うには、次のコマンドを実行します。

	cap symfony:configure:database

初めてアプリケーションをデプロイする場合は、次のコマンドを実行します。

	cap deploy:cold

このコマンドを実行すると、アプリケーションのデプロイ、databases.ymlの設定（DSN、ユーザー名、パスワードのプロンプトが表示されます）、およびデータベース、モデル、フォーム、フィルターの作成とマイグレーションが実行されます。

これ以降、新しいバージョンのコードをデプロイする場合は、次のコマンドを実行します。

	cap deploy

## データベース ##

リモートサーバーのデータベースをダンプして、ローカル環境の`backups/`フォルダへダウンロードするには、次のコマンドを実行します。

	cap database:dump:remote

ローカル環境のデータベースをダンプして、ローカル環境の`backups/`フォルダへコピーするには、次のコマンドを実行します。

	cap database:dump:local

リモートサーバーのデータベースをダンプして、ダンプデータをローカル環境に投入するには、次のコマンドを実行します。

	cap database:move:to_local

ローカル環境のデータベースをダンプして、リモートサーバーのデータベースへダンプデータを投入するには、次のコマンドを実行します。

	cap database:move:to_remote

## 共有フォルダ ##

リモートサーバーから共有フォルダのデータをダウンロードするには、次のコマンドを実行します。

	cap shared:{databases OR log OR uploads]:to_local

ローカル環境の共有フォルダのデータをリモートサーバーへアップロードするには、次のコマンドを実行します。

	cap shared:{databases OR log OR uploads]:to_remote

## リモートホスト上のパーミッション ##

リモートホスト上でsudoが許可されていない場合は、`config/deploy.rb`ファイルに次の設定を追加してください。

    set :use_sudo, false

リモートホスト上で、プロジェクトのコード全体をグループで書き込み可能なパーミッションに設定したくない場合は、`config/deploy.rb`ファイルに次の設定を追加してください。

    set :group_writable, false

## Git向けの設定 ##

Gitサブモジュールを使っている場合、リモートサーバーでサブモジュールを取得するには、`config/deploy.rb`ファイルに次の設定を追加します。

    set :git_enable_submodules, 1

## その他のタスク ##

デプロイ後にマイグレーションを実行する場合は、次のコマンドを実行します。

	cap deploy:migrations

運用サーバーでテストを実行するカスタムタスクも追加してあります。次のコマンドを実行します。

	cap deploy:tests:all

このコマンドを実行すると、アプリケーションのデプロイと、テスト用のデータベースのリビルドが行われ、すべてのテストが実行されます。

また、カスタムsymfonyタスクを実行することもできます。次のようにcap symfonyに続けてタスク名を指定します。

	cap symfony

利用可能なすべてのCapistranoタスクを確認するには、次のコマンドを実行します。

	cap -T

これらのコマンドを使うと、開発しているサイトの変更を運用サーバーへ適用する作業に必要な時間を、大幅に短縮できます。

## 貢献者 ##

* everzet (owner): [http://github.com/everzet](http://github.com/everzet)
* Arlo (contributor): [http://github.com/arlo](http://github.com/arlo)
* Xavier Gorse (contributor): [http://github.com/xgorse](http://github.com/xgorse)
* Travis Roberts (creator of improved version): [http://blog.centresource.com/author/troberts/](http://blog.centresource.com/author/troberts/)
* Brent Shaffer (contributor): [http://github.com/bshaffer](http://github.com/bshaffer)
