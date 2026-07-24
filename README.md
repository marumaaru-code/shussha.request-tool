# 別曜日 出社依頼 — セットアップ手順

インターン生が「いつもと違う平日に出社したい」ときに、所属unit名・名前・出社したい日付・理由を提出できるツールです。提出内容は確認者が承認でき、各月の出社回数も管理できます。

このツール**専用の Supabase プロジェクト**を作って進めます。所要時間はだいたい10分。

---

## 全体の流れ

1. Supabaseプロジェクトを作る
2. テーブルを作る（SQLを1回貼るだけ）
3. アプリにキーを貼り付ける
4. Vercelに公開して、URLをメンバーに配る

---

## 1. Supabaseプロジェクトを作る

1. https://supabase.com/ を開いて「Start your project」からサインアップ（GitHubアカウントかメールでOK・無料）
2. ログイン後「New project」をクリック
3. 次を入力して作成：
   - **Name**: `shussha-irai`（なんでもOK）
   - **Database Password**: 適当に強めのものを設定（メモしておく／このアプリでは直接は使いません）
   - **Region**: `Northeast Asia (Tokyo)` を選ぶと速い
4. プロジェクト作成に1〜2分待つ

---

## 2. テーブルを作る（SQLを貼るだけ）

1. Supabaseの左メニュー **SQL Editor** を開く
2. このリポジトリの [`unit-shussha-irai.sql`](unit-shussha-irai.sql) の中身をすべてコピーして貼り付ける
3. 右下の **Run** を押す

`Success. No rows returned` と出れば成功です。これで `office_requests` テーブル・権限（RLS）・リアルタイム設定がまとめて作られます。

> 貼り付ける内容（`unit-shussha-irai.sql` と同じもの）：
>
> ```sql
> create table if not exists office_requests (
>   id             uuid primary key default gen_random_uuid(),
>   unit_name      text not null,
>   person_name    text not null,
>   requested_date date not null,
>   reason         text,
>   status         text default 'pending',
>   client_id      text,
>   created_at     timestamptz default now()
> );
> alter table office_requests enable row level security;
> create policy "anyone read reqs"   on office_requests for select using (true);
> create policy "anyone write reqs"  on office_requests for insert with check (true);
> create policy "anyone update reqs" on office_requests for update using (true) with check (true);
> create policy "anyone delete reqs" on office_requests for delete using (true);
> alter publication supabase_realtime add table office_requests;
> ```

---

## 3. アプリにキーを貼り付ける

`unit-shussha-irai.html` をエディタで開き、上のほうの `CONFIG` を書き換えます。Supabaseの **Project Settings → API** にある **Project URL** と **anon public** キーを貼ります。

```js
const CONFIG = {
  SUPABASE_URL: "https://xxxxx.supabase.co",   // ← Project URL を貼る
  SUPABASE_ANON_KEY: "eyJhbG...",              // ← anon public key を貼る
};
```

> 💡 `anon public` キーは公開されても大丈夫な種類のキーです（`service_role` キーは絶対に貼らないでください）。

---

## 4. Vercelに公開する

このリポジトリごとVercelに繋いでいる場合は、プッシュするだけで公開されます。

配るURLは、デプロイ後のURLの末尾に `/unit-shussha-irai.html` を付けたものです。
- 例：`https://あなたのプロジェクト.vercel.app/unit-shussha-irai.html`

---

## 5.（任意）Slack通知を付ける

インターンが依頼を提出したら、確認者（社員）のSlackチャンネルに通知が飛ぶようにできます。使わない場合はこの手順を飛ばしてOKです（`SLACK_WEBHOOK_URL` を空のままにしておけば通知しません）。

### 5-1. SlackでIncoming Webhookを作る

1. https://api.slack.com/apps → **Create New App** →「From scratch」
2. アプリ名（例：`出社依頼通知`）とワークスペースを選んで作成
3. 左メニュー **Incoming Webhooks** を開き、スイッチを **On**
4. 下の **Add New Webhook to Workspace** を押し、**通知を送りたいチャンネル**（確認者がいるチャンネル）を選んで許可
5. 発行された **Webhook URL**（`https://hooks.slack.com/services/...`）をコピー

> ⚠️ このURLを知っている人はそのチャンネルに投稿できます。取り扱いは社内限定にしてください。

### 5-2. アプリに貼る

`unit-shussha-irai.html` の `CONFIG` に貼ります：

```js
const CONFIG = {
  SUPABASE_URL: "...",
  SUPABASE_ANON_KEY: "...",
  SLACK_WEBHOOK_URL: "https://hooks.slack.com/services/T000/B000/xxxx",  // ← ここに貼る
};
```

これで提出が成功するたびに、所属・名前・希望日・理由＋このツールのURLがSlackに届きます。

> 💡 通知は「ブラウザから直接」送る方式です。手軽ですが、Webhook URL が公開HTMLに載ります（`anon public` キーと同じ考え方で、社内利用なら実用上問題ありません）。URLを見せたくない場合は、Supabase の Edge Function 経由に切り替える方法もあります（相談ください）。

---

## 使い方

- **インターン生**：所属（SNS / LINE / AI / 広告 / 制作）を選び、SNSならunit A〜H・広告ならunit A〜Cを選択（LINE・AI・制作はunitの選択なし）。あとは名前・出社したい日付・（任意で）理由を入れて「提出する」を押すだけ。
- **確認する人（承認側）**：ヘッダー右上の「確認者」を押して**確認者モード**をONにします。**パスワード**（`CONFIG.REVIEWER_PASSWORD`）を求められ、合致するとONになります（その端末では記憶。OFF→再ONで再度要求）。ONにすると：
  - **座席残数の目安**（曜日別）が表示されます。各依頼カードにも「その曜日の2F残席」が出るので、空きを見ながら承認できます。
  - 各依頼に「**承認する / 却下**」ボタンが出ます。基本は空きがあれば承認（不足時も3F利用で対応可）。もう一度同じボタンを押すと「承認待ち」に戻せます。
  - 各依頼に「**🗑 この依頼を削除**」ボタンも出ます。押すと確認ダイアログ → OKで完全に削除されます（元に戻せません）。
  - 「承認待ち / 承認済み / すべて」で絞り込めます。
- インターン生側は、自分の依頼に「承認待ち・承認済み・却下」のバッジが付くので、結果がひと目で分かります（確認者モードのボタンや座席パネルは、モードOFFのときは出ません）。
- 提出・承認はリアルタイムで全員に反映されます。

### 出社管理タブ（各月の出社回数を確認）

- 確認者モードをONにすると、上部に「**依頼 / 出社管理**」のタブが出ます（出社管理タブは管理者＝確認者モードのときだけ表示）。
- 「出社管理」では、**承認済みの別曜日出社**を**月ごと・人ごとに集計**して表示します。各人の「◯回」と、実際の出社日（日付＋曜日）が並びます。月ごとに「◯人 / のべ◯回」も出ます。
- 上の検索ボックスに**名前や unit名を入れると絞り込み**できます（空欄で全員）。
- ※承認待ち・却下の依頼はここには出ません（「出社した履歴」＝承認済みを対象にしています）。

---

## 注意点

- ログイン認証は今はありません（ボタンで入るだけ）。**URLを知っている人は誰でも提出・閲覧できます**。社内での共有前提の設計です。
- 提出フォームは誰が提出したかを名前で記録します（`unit-tsubuyaki` の匿名投稿とは別の考え方です）。
- 過去日は選べないよう、日付は今日以降だけ選択できるようにしています。「平日を選んでください」という案内は出しますが、土日を選んでも提出自体はできます（運用でカバー）。
- **所属・unitの選択肢を変えたいとき**：`unit-shussha-irai.html` の `DIVISIONS` を書き換えるだけです（配下のunitがない事業部は空配列 `[]`）。
  ```js
  const DIVISIONS = {
    "SNS":  ["A", "B", "C", "D", "E", "F", "G", "H"],
    "LINE": [],
    "AI":   [],
    "広告": ["A", "B", "C"],
    "制作": [],
  };
  ```
- **座席残数の目安を変えたいとき**：同じく `unit-shussha-irai.html` の `WEEKDAY_REMAINING`（月〜金の残席数）を書き換えます。マイナスは超過を表し、赤字で表示されます。
  ```js
  const WEEKDAY_REMAINING = { 1: 6, 2: -1, 3: -1, 4: -2, 5: 11 }; // 月〜金
  const SEAT_NOTE = "※2Fメイン（50席）基準の残席数。不足していても基本は3F利用で対応できます。";
  ```
- **確認者モードには簡易パスワードが必要です**（`CONFIG.REVIEWER_PASSWORD`）。ただしこれは公開HTMLに載る「軽い鍵」で、ソースを見れば分かる仕組みです。インターンが気軽に承認・削除するのを防ぐ抑止としては十分ですが、本格的な認証ではありません。厳密に守りたい場合は Supabase ログイン方式への切り替えが必要です。
- パスワードを変えたいときは `CONFIG.REVIEWER_PASSWORD` の値を書き換えて再デプロイしてください（空文字にするとパスワードなしになります）。

---

## こまったとき

- **提出しても保存されない / 一覧に出ない** → CONFIGのキーが正しいか、手順2のSQLがエラーなく実行できたか確認
- **「読み込みに失敗しました」と出る** → URL/キーの貼り間違い、またはポリシー設定が抜けている
- **他の人の提出がリアルタイムで出てこない** → 手順2の `alter publication ...` が通っているか確認
