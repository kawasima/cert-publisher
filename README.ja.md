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
		AuthDBDUserPWQuery "SELECT 'xxj31ZMTZzkVA' FROM users WHERE dn=%s"
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

### 端末認証のセットアップ

端末ごとに認証コードを発行し、保護領域にアクセスするときにその事由を入力させるようにするためには、mod_device_trace モジュールが必要です。

    % git clone https://github.com/kawasima/mod_device_trace.git
	% cd mod_device_trace
	% make
	% sudo make install

そしてApacheのconfigでモジュールをロードしてください。

    LoadModule dir_module /usr/lib/apache2/modules/mod_device_trace.so

保護領域の設定は以下のようにします。

    <Location /secret>
        SSLRequire %{SSL_CLIENT_VERIFY} eq "SUCCESS"
        DeviceTrace On
        DeviceTraceSetTokenUrl     https://domain/cert-publisher/user/
        DeviceTraceStartSessionUrl https://domain/cert-publisher/user/start_session
        Require valid-user
    </Location>

### 認可の設定

これはCert Publisherの機能ではありませんが、Cert Publisherで管理されたグループを使って認可する設定の方法です。

mod_authz_dbdが必要です。Apache2.4からは標準モジュールに入っていますが、2.2では付属していないので、自分でビルドしてください。

http://people.apache.org/~niq/dbd.html

モジュールインストールし有効にしたら、以下の設定をコンフィグに書き加えてください。

    AuthzDBDQuery "SELECT G.name AS `group` FROM users AS U JOIN group_users AS GU ON GU.user_id=U.id JOIN groups AS G ON GU.group_id=G.id WHERE U.dn=%s"

Cert Publisherでグループ作り(ここでは例としてmygroupを作ったとする)、保護領域に、以下のような設定を加えると、mygroupに属しているもののみアクセスできるようになります。

    Require dbd-group mygroup

利用方法
-----------

### Cert Publisher管理のユーザをLDAPで検索する

Cert Publisherで保護された領域にredmineやjenkinsなど、既成のアプリケーションをおきたい場合があります。この場合、Cert Publisherの登録内容をldapインタフェースで提供することができるので、既成アプリケーションの認証方式をLDAPに設定すると連携が可能になります。

Cert Publisherではパスワードという概念は存在しないので、LDAP認証のためにワンタイムパスワードを自動発行する機能があります。
ユーザはクライアント認証でダッシュボードを開き、ワンタイムパスワードを取得します。ここで取得したパスワードを元に、redmineやjenkinsにログインすることができます。

LDAPによるシングルサインオンは、パスワードが漏れると全部のサービスにアクセスされてしまう危険性がありますが、このCertPulisherのワンタイムパスワードLDAPを使えば、LDAPの利便性を保ちつつその危険性を最小限にすることができます。

LDAPサーバを立ち上げるには、以下のコマンドを実行してください。

    % padrino rake cert_publisher:ldap

ポート番号は1389で起動します。ユーザのディレクトリは、ou=users,dc=cert-publisher になるので、これをBASE DNに設定してください。

