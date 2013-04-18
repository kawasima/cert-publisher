CertPublisher
=============

クライアント証明書をセキュアに発行・管理するためのツールです。

エンタープライズの用途でも個人の認証にパスワード方式がよく用いられますが、往々にして個人のセキュリティ意識が低く、
パスワードは簡単に破られそうなものが設定されたり、いくつかのシステムで使いまわしにされていたりする現状があります。
このためパスワードの数ヶ月に一回パスワードを強制的に変更させたりといった工夫がなされる運用がありすが、
到底記憶しきれないのでパスワードをポストイットに書いて机に貼ったり余計にパスワードを盗まれやすくしてしまいます。

CertPublisherでは、こうした企業内システムなどの限られた用途向けにパスワード認証ではなく、クライアント証明書を
利用した認証で、証明書の管理の手間や紛失・盗難への対策を施しています。

特徴
----

パスワードなしでセキュアにアクセスするために、以下のような機能をもっています。

### パスフレーズ

クライアント証明書にはパスフレーズを設定して、利用時に毎回入力させることができますが、
これではパスワードの運用と同じ問題を抱えてしまいます。

そこでCertPublisherでは独自に、ユーザごとに秘密の質問を設定できるようにしています。


### 端末認証

証明書を盗まれると、第三者による不正アクセスの危険性がありますが、端末のIDが設定されていないと
証明書を持っていてもアクセスできないように制御されます。
端末IDの設定には「秘密の質問」に正しく答える必要があるので、証明書を盗まれてから無効にするまでの
時間を稼ぐことできます。


注意事項
--------
不特定多数向けのパブリックな環境においては、自己証明書でなく正規の証明書を必ず使うようにしてください。

セットアップ
------------

### 前提条件

* Apache 2.2.x
* Ruby 1.9.3 + OpenSSL
* MySQL

### Cert Publisherのソースを取得し、ライブラリをインストールする。

    % git clone https://github.com/kawasima/cert-publisher.git
    % bundle install

### Cert Publisherの設定ファイルを書く

    % cp config/settings.yml config/settings.yml.example
    % vi config/settings.yml
	
### ApacheのSSL自己証明局をセットアップする。

    % padrino rake cert-publisher:ca:generate

上記コマンドで、settings.ymlで指定したCA秘密鍵とCA証明書のパスに、それらが生成されます。

ApacheのSSL設定として以下の項目を書き換えてください

    # SSLCACertificatePath /etc/ssl/certs/  # 必ずコメントアウトする
    SSLCACertificateFile /etc/apache2/ssl.crt/cacert.pem  # CA証明書

    SSLVerifyClient optional
    SSLVerifyDepth  1

### ApacheのBASIC認証をセットアップする

CertPublisherは、ApacheのFakeBasicAuth機能と連携するので、この設定を書きます。
まず、mod_authn_dbdを有効にします。

    % sudo a2enmod authn_dbd

次にServerまたはVirtualHostのディレクティブに以下の設定を書き加えます。

    DBDriver        mysql
    DBDParams       host=127.0.0.1,port=3306,user=cert,pass=xxx,dbname=cert_publisher,charset=utf8
    DBDMin  5
    DBDKeep 5
    DBDMax  5
    DBDPersist      Off

    <Location />
        SSLOptions +StdEnvVars +OptRenegotiate +FakeBasicAuth
        AuthType Basic
        AuthName "Your Realm"
        AuthBasicProvider dbd
		AuthDBDUserPWQuery "SELECT '$apr1$E8MmZwFZ$k3gNG2FSX7TQodKLeRwoA0' FROM users WHERE dn=%s"
        AuthzDBDQuery "SELECT G.name AS `group` FROM users AS U JOIN group_users AS GU ON GU.user_id=U.id JOIN groups AS G ON GU.group_id=G.id WHERE U.dn=%s"
    </Location>

DBDxxxの設定項目は、Apacheからデータベース接続するための設定です。Cert Publisherで管理されているユーザ、グループの情報を参照し認証・認可を行います。

SSLOptions +FakeBasicAuth は、クライアント認証されたユーザのDNをユーザ名、"password"固定文字列をパスワードとしてWWW-Authorizationヘッダに認証コードを設定するオプションです。これを使って後ろで動作するアプリケーションは特別なコードを書くことなく、BASIC認証されたかのように取り扱うことができます。

AuthDBDUserPWQueryはDBDを使ったBASIC認証のためのSQLです。パスワードはpasswordをハッシュ化した値になっているので、DNがusersテーブルに見つかれば認証が通るようになっています。

AuthzDBDQueryはDBDを使った認可のためのSQLです。


### Cert Publisherの認証認可を設定する

passengerを使ってCertPublisherを/cert-publisherにマウントした場合の設定です。

Cert Publisherではクライアント証明書が必要なパスは/userと/adminに限っているので、そこをSSLRequireで保護します。さらにクライアント証明書のユーザを使ってCert Publisherの認証を行うので、Require valid-user も書いておきます。

    RackBaseURI /cert-publisher
    <Location /cert-publisher/(user|admin)/>
        SSLRequire %{SSL_CLIENT_VERIFY} eq "SUCCESS"
        Require valid-user
    </Location>
														
### Cert PublisherのDBセットアップ

cert-publisherデータベースを作り、migrateでテーブルを作ってください。

    % mysqladmin -u root -p create cert-publisher
    % padrino rake dm:auto:migrate
