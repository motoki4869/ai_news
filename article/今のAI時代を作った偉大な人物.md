# 今のAI時代を作った偉大な人物

ChatGPT・Claude・Stable Diffusionなどに代表される今の生成AIは、ある日突然できたものではなく、数十年にわたる基礎研究とここ10年強のブレークスルーが積み重なって生まれています。このドキュメントは、その積み重ねの中で特に大きな役割を果たした人物を分野別に整理し、それぞれの代表論文（発表年・一言でいうと何がすごいか）とセットでまとめたものです。

論文そのものの候補一覧は [`生成AIを形作った偉大な論文候補.md`](./生成AIを形作った偉大な論文候補.md) を参照してください。本ドキュメントはその論文を「誰が」書いたのかという人物側の視点から整理しています。すでに要約済みの論文にはリンクを付けています。

---

## 1. 深層学習の基礎を築いた人々

### ジェフリー・ヒントン（Geoffrey Hinton）
「AIのゴッドファーザー」と呼ばれる研究者。1980年代から誤差逆伝播法（バックプロパゲーション）の実用化に取り組み、2012年には教え子のアレックス・クリジェフスキー、イリヤ・サツケバーとともに画像認識コンペで圧勝したAlexNetを発表し、深層学習ブームの引き金を引きました。2018年チューリング賞、2024年ノーベル物理学賞を受賞。2023年にGoogleを退職し、AIのリスクについて警鐘を鳴らす発言でも知られています。

- **代表論文**：*ImageNet Classification with Deep Convolutional Neural Networks*（2012, AlexNet） — Krizhevsky, Sutskever, Hinton。GPUを使った大規模CNNで画像認識の常識を塗り替え、以降の深層学習ブームの起点となった。（未要約）
- **代表論文**：*Dropout: A Simple Way to Prevent Neural Networks from Overfitting*（2014） — 訓練中にニューロンをランダムに無効化して過学習を防ぐ手法。今もほぼ全てのニューラルネットで使われる基本技術。（未要約）

### ヤン・ルカン（Yann LeCun）
畳み込みニューラルネットワーク（CNN）の原型を1980〜90年代に確立した研究者。手書き数字認識（LeNet）で「画像の位置がずれても同じ特徴を検出できる」という発想を実用化し、後のAlexNetをはじめとする画像認識モデル全ての土台を作りました。Meta（旧Facebook）AI研究所（FAIR）の初代チーフAIサイエンティスト。2018年チューリング賞受賞。

### ヨシュア・ベンジオ（Yoshua Bengio）
ヒントン・ルカンと並ぶ深層学習研究の中心人物。教え子のバダナウ（Bahdanau）らと2014年に発表した論文でアテンション機構を機械翻訳に導入し、これがTransformerの自己注意機構の直接の祖先となりました。2018年チューリング賞受賞。近年はAIの安全性・リスク評価に関する国際的な取りまとめ役としても活動しています。

- **代表論文**：*Neural Machine Translation by Jointly Learning to Align and Translate*（2014） — Bahdanau, Cho, Bengio。アテンション機構を初めて導入し、Transformerの直接の祖先となった。（未要約）

> ヒントン・ルカン・ベンジオの3人は「深層学習の三賢人」と呼ばれ、2018年に3人揃ってチューリング賞（コンピュータ科学のノーベル賞と称される賞）を受賞しています。

---

## 2. Transformer／LLMの時代を作った人々

### アシシュ・ヴァスワニ（Ashish Vaswani）
2017年、Google Brainの研究チームを率いて「Attention Is All You Need」を発表。再帰構造（RNN）を捨て、自己注意機構だけで文章を処理するTransformerアーキテクチャを提案し、以降のほぼ全てのLLM（GPT、BERT、Claude等）の土台を作りました。後にTransformer共著者らとAdept AIを共同創業。

- **代表論文**：[Attention Is All You Need（2017）](<./Attention Is All You Need/Attention Is All You Need_要約.md>) — 要約済み。Transformerを提案した、生成AI史上最も影響力の大きい論文の一つ。

### イリヤ・サツケバー（Ilya Sutskever）
ヒントンの教え子で、AlexNet（2012）の共著者。2014年には「Sequence to Sequence Learning with Neural Networks」でエンコーダ・デコーダ構造による系列変換（seq2seq）を確立し、これがTransformerの基本設計にも受け継がれました。2015年にOpenAIを共同創業し、チーフサイエンティストとしてGPTシリーズの開発を主導。2024年に安全なAI開発を目指すSafe Superintelligence Inc.（SSI）を新たに設立しました。

- **代表論文**：[Sequence to Sequence Learning with Neural Networks（2014）](<./Sequence to Sequence Learning with Neural Networks/Sequence to Sequence Learning with Neural Networks_要約.md>) — Sutskever, Vinyals, Le。「文を固定長ベクトルに圧縮してから別の文に変換する」という設計を確立。要約済み。

### アレック・ラドフォード（Alec Radford）
OpenAIの研究者で、GPT-1（2018）・GPT-2（2019）・GPT-3（2020、共著）の筆頭著者、さらに画像とテキストを結びつけるCLIP（2021）の筆頭著者でもあります。「Transformerのデコーダ部分だけで次の単語を予測する事前学習」というGPTシリーズの基本方針を作り、さらに「言葉で画像を指示する」ことを可能にしたCLIPで画像生成AIにも決定的な貢献をしました。

- **代表論文**：*Improving Language Understanding by Generative Pre-Training*（2018, GPT-1） — GPTシリーズの原点。（未要約）
- **代表論文**：*Language Models are Few-Shot Learners*（2020, GPT-3） — 1750億パラメータの巨大モデルでプロンプトだけで新タスクをこなせることを実証。（未要約）
- **代表論文**：*Learning Transferable Visual Models From Natural Language Supervision*（2021, CLIP） — 画像とテキストを同じ空間で対応づけ、DALL-EやStable Diffusionの「言葉で画像を指示する」仕組みの鍵となった。（未要約）

---

## 3. 画像生成AIを作った人々

### イアン・グッドフェロー（Ian Goodfellow）
2014年、「偽物を作る生成器」と「本物か偽物か見破る識別器」を競わせて学習するGAN（敵対的生成ネットワーク）を発案。画像生成AIという分野そのものを切り開いた人物です。Google Brain、Apple、DeepMindなどで研究を続けました。

- **代表論文**：*Generative Adversarial Networks*（2014） — 画像生成AIの一つの源流。（未要約）

### ジョナサン・ホー（Jonathan Ho）
UC Berkeleyで拡散モデル（ディフュージョンモデル）を大きく前進させた研究者。2020年発表の「Denoising Diffusion Probabilistic Models（DDPM）」は、ノイズを少しずつ除去して画像を生成する手法を確立し、Stable Diffusion・DALL-E・Midjourneyなど現在の画像生成AIの直接の基盤となりました。

- **代表論文**：[Denoising Diffusion Probabilistic Models（2020）](<./Denoising Diffusion Probabilistic Models/Denoising Diffusion Probabilistic Models_要約.md>) — 要約済み。現在の画像生成AIのほぼ全てが依拠する拡散モデルの基礎を確立。

### ロビン・ロンバッハ（Robin Rombach）
2022年、拡散処理を圧縮した潜在空間（latent space）で行うことで計算コストを大幅に下げるLatent Diffusion Models（Stable Diffusionの原論文）を発表。これにより一般的なPCでも動く画像生成AIが実現しました。後にBlack Forest Labsを共同創業し、画像生成モデルFLUXを開発しています。

- **代表論文**：*High-Resolution Image Synthesis with Latent Diffusion Models*（2022） — 一般PCでも動く画像生成AIを実現。（未要約）

---

## 4. 「賢いだけ」のAIを「対話できる」AIに変えた人々

### ポール・クリスティアーノ（Paul Christiano）
2017年、「人間が2つの出力を比較してどちらが良いか教えるだけでAIを訓練できる」ことを示したRLHF（人間のフィードバックによる強化学習）の原型を発表。OpenAIで安全性研究を率いた後、AIの整合性（アライメント）研究に特化したAlignment Research Center（ARC）を設立しました。

- **代表論文**：*Deep Reinforcement Learning from Human Preferences*（2017） — RLHFの原型。（未要約）

### ロン・オウヤン（Long Ouyang）とOpenAIのRLHFチーム
2022年発表の「InstructGPT」論文で、RLHFを大規模言語モデルに本格適用し、「賢いだけ」のGPT-3を「指示に従い、人間にとって役立つ」モデルへと変えました。この技術がそのままChatGPT（2022年11月公開）に使われ、生成AIを一般社会に広めた直接のきっかけとなりました。

- **代表論文**：[Training language models to follow instructions with human feedback（2022, InstructGPT）](<./Training language models to follow instructions with human feedback/Training language models to follow instructions with human feedback_要約.md>) — 要約済み。ChatGPTが「会話できる」理由そのものを説明する論文。

### ジェイソン・ウェイ（Jason Wei）
Google Brainの研究者で、2022年に「途中式・思考過程を書かせてから答えさせるだけでモデルの推論能力が大きく向上する」というChain-of-Thought Promptingを発見。この考え方は、OpenAI o1やClaudeの拡張思考など、現在の「推論モデル」の直接の源流になっています。

- **代表論文**：*Chain-of-Thought Prompting Elicits Reasoning in Large Language Models*（2022） — 現在の推論モデルにつながる考え方の起点。（未要約）

---

## 5. 研究組織を率いて社会実装まで進めたキーパーソン

### デミス・ハサビス（Demis Hassabis）
元プロのチェスプレイヤーで、2010年にDeepMindを共同創業。2016年のAlphaGo（プロ棋士を破った囲碁AI）、2020年のAlphaFold（タンパク質の立体構造をほぼ完全に予測するAI）を主導しました。AlphaFoldの功績により2024年ノーベル化学賞を受賞。現在はGoogle DeepMindのCEOとして、Geminiシリーズなどの開発を率いています。

### サム・アルトマン（Sam Altman）
スタートアップ支援組織Y Combinatorの元社長で、2015年にイリヤ・サツケバーらとOpenAIを共同創業。CEOとして2022年11月のChatGPT公開を主導し、生成AIを一般消費者向け製品として世界に広めました。

### ダリオ・アモデイ（Dario Amodei）とダニエラ・アモデイ（Daniela Amodei）
兄妹でOpenAIの研究・組織運営を率いた後、2021年にAI安全性を重視する研究方針の違いからAnthropicを共同創業。ダリオはCEOとして、ダニエラは社長として、Claudeシリーズの開発を率いています。「役立つが、正直で、無害な」AIを掲げる方針は、RLHFやモデルの整合性研究の延長線上にあります。

### ジェンスン・フアン（Jensen Huang）
1993年にNVIDIAを共同創業したCEO。GPUという並列計算に特化したハードウェアと、それを使いやすくするCUDAというプラットフォームを普及させ続けたことが、2012年のAlexNet以降の深層学習の大規模化を計算資源の面から可能にしました。論文を書いた研究者ではありませんが、「今のAI時代」を計算基盤の面から作った人物として欠かせません。

### フェイフェイ・リー（Fei-Fei Li）
2009年、1400万枚以上の画像に人手でラベルを付けた大規模データセットImageNetを構築・公開。「大量の質の良い学習データがあれば深層学習は化ける」ことを証明する土台を作り、2012年のAlexNetの成功はこのデータセットなしにはあり得ませんでした。現在はスタンフォード大学人間中心AI研究所（HAI）の共同ディレクターを務め、2024年には空間知能（Spatial Intelligence）を研究するWorld Labsを創業しています。

---

## 6. 技術を広め、次の世代を育てた人物

### アンドレイ・カーパシー（Andrej Karpathy）
OpenAIの創業メンバーの一人で、後にTesla AIの責任者として自動運転技術を率いました。深層学習の仕組みをゼロから解説する教育動画・ブログで知られ、専門家でなくても理解できる形で深層学習の考え方を広めた功績が大きい人物です。2024年にAI教育に特化したEureka Labsを設立しました。

---

## まとめ表

| カテゴリ | 人物 | 代表論文 | 要約 |
|---|---|---|---|
| 深層学習の基礎 | ジェフリー・ヒントン | AlexNet (2012) | 未要約 |
| 深層学習の基礎 | ヤン・ルカン | CNN/LeNet (1990年代) | 未要約 |
| 深層学習の基礎 | ヨシュア・ベンジオ | アテンション機構の機械翻訳導入 (2014) | 未要約 |
| Transformer/LLM | アシシュ・ヴァスワニ | Attention Is All You Need (2017) | [要約済み](<./Attention Is All You Need/Attention Is All You Need_要約.md>) |
| Transformer/LLM | イリヤ・サツケバー | Sequence to Sequence Learning (2014) | [要約済み](<./Sequence to Sequence Learning with Neural Networks/Sequence to Sequence Learning with Neural Networks_要約.md>) |
| Transformer/LLM | アレック・ラドフォード | GPT-3 (2020) / CLIP (2021) | 未要約 |
| 画像生成AI | イアン・グッドフェロー | GAN (2014) | 未要約 |
| 画像生成AI | ジョナサン・ホー | DDPM (2020) | [要約済み](<./Denoising Diffusion Probabilistic Models/Denoising Diffusion Probabilistic Models_要約.md>) |
| 画像生成AI | ロビン・ロンバッハ | Latent Diffusion / Stable Diffusion (2022) | 未要約 |
| 対話できるAI | ポール・クリスティアーノ | Deep RL from Human Preferences (2017) | 未要約 |
| 対話できるAI | ロン・オウヤン | InstructGPT (2022) | [要約済み](<./Training language models to follow instructions with human feedback/Training language models to follow instructions with human feedback_要約.md>) |
| 対話できるAI | ジェイソン・ウェイ | Chain-of-Thought Prompting (2022) | 未要約 |
| 組織・実装 | デミス・ハサビス | AlphaGo/AlphaFold（DeepMind） | — |
| 組織・実装 | サム・アルトマン | ChatGPT公開（OpenAI） | — |
| 組織・実装 | ダリオ/ダニエラ・アモデイ | Claude（Anthropic） | — |
| 組織・実装 | ジェンスン・フアン | GPU/CUDA（NVIDIA） | — |
| 組織・実装 | フェイフェイ・リー | ImageNet (2009) | 未要約 |
| 教育・普及 | アンドレイ・カーパシー | 教育コンテンツ・OpenAI/Tesla | — |

*未要約の論文を要約したい場合は、`summarizing-papers`スキルの対象としてタイトルを指定してください。PDFの取得から要約・かんたん解説の作成まで行います。*
