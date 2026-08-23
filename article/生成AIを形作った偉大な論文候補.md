# 今の生成AIを形作った偉大な論文候補

生成AI（ChatGPT・Claude・Stable Diffusionなど）の土台となった重要論文の候補リスト。`attention_is_all_you_need`と同じ要領で、要約ファイルを作る際の選定用メモとして作成。

カテゴリごとに「論文名 / 発表年 / 一言でいうと何がすごいか」をまとめている。★は特に影響が大きく、優先的に読む価値が高いと考えられるもの。

---

## 1. 言語モデルの基礎を作った論文

### ★ Attention Is All You Need（2017）
- Vaswani et al. (Google)
- Transformerを提案。再帰を捨てて自己注意だけで系列を扱う発想が、以降のほぼ全てのLLMの土台になった。
- **要約済み**（同フォルダの`attention_is_all_you_need`参照）

### Sequence to Sequence Learning with Neural Networks（2014）
- Sutskever, Vinyals, Le (Google)
- エンコーダ・デコーダ構造による系列変換（seq2seq）を確立。「文を固定長ベクトルに圧縮してから別の文に変換する」という、後のTransformerにも受け継がれる基本設計を提示。

### Neural Machine Translation by Jointly Learning to Align and Translate（2014）
- Bahdanau, Cho, Bengio
- 「アテンション機構」を機械翻訳に初めて導入した論文。Transformerの自己注意の直接の祖先にあたる。

### Efficient Estimation of Word Representations in Vector Space（2013, Word2Vec）
- Mikolov et al. (Google)
- 単語を意味を持つベクトルに変換する手法を確立。「王様 − 男 + 女 = 女王」のようなベクトル演算が成立することを示し、以降の全ての言語処理モデルの基礎（埋め込み表現）を作った。

### ★ BERT: Pre-training of Deep Bidirectional Transformers（2018）
- Devlin et al. (Google)
- Transformerのエンコーダ部分だけを使い、文章の前後両方向を見て言葉を予測する事前学習を提案。「大量の文章で事前学習してから個別タスクに微調整する」という今のLLMの基本戦略を定着させた。

### ★ Improving Language Understanding by Generative Pre-Training（2018, GPT-1）
- Radford et al. (OpenAI)
- Transformerのデコーダ部分だけを使い、「次の単語を予測する」ことだけで大量の文章から学習する方式（GPTシリーズの原点）。

### Language Models are Unsupervised Multitask Learners（2019, GPT-2）
- Radford et al. (OpenAI)
- モデルを大きくし訓練データを増やすだけで、翻訳や要約など個別に教えていないタスクまでできるようになることを示した。「スケールが能力を生む」ことの初期の実証例。

### ★ Language Models are Few-Shot Learners（2020, GPT-3）
- Brown et al. (OpenAI)
- パラメータ数1750億という当時桁違いの巨大モデル。プロンプトに数例示すだけ（few-shot）で新しいタスクをこなせることを示し、「プロンプトエンジニアリング」という考え方の出発点になった。

### Exploring the Limits of Transfer Learning with a Unified Text-to-Text Transformer（2019, T5）
- Raffel et al. (Google)
- あらゆる言語タスクを「テキストを入れたらテキストが出てくる」という統一形式で扱えることを示した。

### Scaling Laws for Neural Language Models（2020）
- Kaplan et al. (OpenAI)
- モデルサイズ・データ量・計算量を増やすと性能がどう向上するかを法則としてまとめた。「大きくすればするほど賢くなる」を定量的に裏付け、GPT-3以降の巨大化競争の理論的根拠になった。

---

## 2. 学習を安定させた／可能にした基礎技術

### Long Short-Term Memory（1997, LSTM）
- Hochreiter, Schmidhuber
- RNNが長い文章を覚えられない問題（勾配消失）を解決。Transformer以前の系列モデリングの主役だった。

### Dropout: A Simple Way to Prevent Neural Networks from Overfitting（2014）
- Srivastava, Hinton et al.
- 訓練中にランダムにニューロンを無効化することで過学習を防ぐ手法。現在もほぼ全てのニューラルネットで使われる基本技術。

### Adam: A Method for Stochastic Optimization（2014）
- Kingma, Ba
- 深層学習の学習率調整を効率化した最適化アルゴリズム。ほぼ全ての大規模モデルの訓練で今も標準的に使われている。

### Deep Residual Learning for Image Recognition（2015, ResNet）
- He et al. (Microsoft)
- 「残差接続（Residual Connection）」を提案し、非常に深いネットワークでも学習が破綻しないようにした。Transformerの各層にも同じ仕組みが使われている。

### Layer Normalization（2016）
- Ba, Kiros, Hinton
- 層の出力を正規化して学習を安定させる手法。Transformerの各サブ層に組み込まれている基礎技術。

---

## 3. 画像・マルチモーダル生成の基礎を作った論文

### ★ Generative Adversarial Networks（2014, GAN）
- Goodfellow et al.
- 「偽物を作る生成器」と「本物か偽物か見破る識別器」を競わせて学習する枠組み。画像生成AIの一つの源流。

### Auto-Encoding Variational Bayes（2013, VAE）
- Kingma, Welling
- データを確率分布として圧縮・復元する生成モデルの基礎。拡散モデルの理論的な土台の一部にもなっている。

### ★ Denoising Diffusion Probabilistic Models（2020, DDPM）
- Ho, Jain, Abbeel
- ノイズを少しずつ除去していくことで画像を生成する「拡散モデル」を確立。Stable Diffusion・DALL-E・Midjourney等、現在の画像生成AIの直接の基盤。

### High-Resolution Image Synthesis with Latent Diffusion Models（2022, Stable Diffusion）
- Rombach et al.
- 拡散処理を圧縮した潜在空間で行うことで計算コストを大幅に下げ、一般PCでも動く画像生成AIを実現した。

### ★ Learning Transferable Visual Models From Natural Language Supervision（2021, CLIP）
- Radford et al. (OpenAI)
- 画像とテキストを同じ空間で対応づける学習方法。「猫の画像」と「cat という言葉」を結びつけられるようになり、DALL-EやStable Diffusionが「言葉で画像を指示する」ことを可能にした鍵となる技術。

### An Image is Worth 16x16 Words: Transformers for Image Recognition at Scale（2020, ViT）
- Dosovitskiy et al. (Google)
- Transformerを画像にも応用できることを示した。テキスト・画像を同じアーキテクチャで扱う流れを作った。

---

## 4. 「賢く・言うことを聞く」AIにした学習手法

### ★ Training language models to follow instructions with human feedback（2022, InstructGPT / RLHF）
- Ouyang et al. (OpenAI)
- 人間のフィードバックをもとに強化学習でモデルを調整する手法（RLHF）を確立。「賢いだけ」のGPT-3を「指示に従い、人間にとって役立つ」ChatGPTに変えた直接の技術。

### Deep Reinforcement Learning from Human Preferences（2017）
- Christiano et al. (OpenAI/DeepMind)
- RLHFの原型となった論文。人間が2つの出力を比較して「どちらが良いか」を教えるだけでAIを訓練できることを示した。

### ★ Chain-of-Thought Prompting Elicits Reasoning in Large Language Models（2022）
- Wei et al. (Google)
- 「途中式・思考過程を書かせてから答えさせる」だけでモデルの推論能力が大きく向上することを発見。現在の推論モデル（o1など）にもつながる考え方。

### Training Compute-Optimal Large Language Models（2022, Chinchilla）
- Hoffmann et al. (DeepMind)
- 「モデルを大きくする」より「データ量とモデルサイズのバランスを取る」方が効率的だと示し、以降のLLM設計方針に影響を与えた。

---

## おすすめの読む順（候補）

1. **Attention Is All You Need**（済）— 全ての土台
2. **GPT-3 (Language Models are Few-Shot Learners)** — 「大きくすればできることが増える」を体感する
3. **BERT** — Transformerのもう一つの使い方（双方向理解）を知る
4. **Training language models to follow instructions with human feedback (InstructGPT)** — なぜChatGPTが「会話できる」のかの直接の答え
5. **Denoising Diffusion Probabilistic Models** — 画像生成AI側の土台
6. **Learning Transferable Visual Models From Natural Language Supervision (CLIP)** — 言葉と画像をつなぐ仕組み

---

*このリストは要約対象を選ぶための候補メモであり、各論文の内容はまだ要約していません。要約が必要な論文があれば個別に指示してください。*
