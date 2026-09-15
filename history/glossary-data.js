/* 自動生成ファイル — 編集しないこと。
   ソース: docs/glossary.md / 生成: scripts/generate_glossary_data.py */
window.GLOSSARY = [
  {
    "no": "1",
    "title": "エージェント・自律化",
    "theme": "t-agent",
    "id": "sec1",
    "entries": [
      {
        "term": "<strong>エージェンティックAI</strong>",
        "sub": "Agentic AI",
        "desc": "AIが「質問に答えるツール」ではなく「目的を与えられて自律的に実行する主体」として動く形態。2026年の最大の構造転換とされ、企業ソフトへの組み込み率は2024年の1%未満から2028年に33%へ拡大すると予測されている。",
        "q": "エージェンティックai agentic ai aiが「質問に答えるツール」ではなく「目的を与えられて自律的に実行する主体」として動く形態。2026年の最大の構造転換とされ、企業ソフトへの組み込み率は2024年の1%未満から2028年に33%へ拡大すると予測されている。"
      },
      {
        "term": "<strong>マルチエージェント / MAS</strong>",
        "sub": "Multi-Agent System",
        "desc": "役割の異なる複数のAIエージェントが相互に通信・交渉して1つのタスクを遂行する構成。サプライチェーンの自律交渉やサイバー防御（赤・青・緑の3エージェント連携）などで実運用が始まっている。",
        "q": "マルチエージェント / mas multi-agent system 役割の異なる複数のaiエージェントが相互に通信・交渉して1つのタスクを遂行する構成。サプライチェーンの自律交渉やサイバー防御（赤・青・緑の3エージェント連携）などで実運用が始まっている。"
      },
      {
        "term": "<strong>A2Aプロトコル</strong>",
        "sub": "Agent-to-Agent Protocol",
        "desc": "エージェント同士が自律的に交渉・協調するための通信標準。各エージェントが自分の能力を「AgentSkill」として公開し合う。150以上の組織が支持し2026年にv1.0安定版へ到達。",
        "q": "a2aプロトコル agent-to-agent protocol エージェント同士が自律的に交渉・協調するための通信標準。各エージェントが自分の能力を「agentskill」として公開し合う。150以上の組織が支持し2026年にv1.0安定版へ到達。"
      },
      {
        "term": "<strong>MCP</strong>",
        "sub": "Model Context Protocol",
        "desc": "LLMを外部ツール・データソースに接続するための標準インターフェース。エージェントが外部環境を操作する際の事実上の共通規格になりつつある。",
        "q": "mcp model context protocol llmを外部ツール・データソースに接続するための標準インターフェース。エージェントが外部環境を操作する際の事実上の共通規格になりつつある。"
      },
      {
        "term": "<strong>ハーネス</strong>",
        "sub": "Harness",
        "desc": "モデルの重みそのものではなく、その周囲にあるプロンプト・記憶構造・ツールインターフェースの総称。近年のエージェント性能向上の主戦場はモデル更新からハーネスの設計・書き換えへ移っている。",
        "q": "ハーネス harness モデルの重みそのものではなく、その周囲にあるプロンプト・記憶構造・ツールインターフェースの総称。近年のエージェント性能向上の主戦場はモデル更新からハーネスの設計・書き換えへ移っている。"
      },
      {
        "term": "<strong>RHI</strong>",
        "sub": "Recursive Harness self-Improvement（再帰的ハーネス自己改善）",
        "desc": "過去の改変履歴をペアワイズ・フィードバックで反復最適化し、ハーネスを自動で書き換え続ける手法。推論コストを最大60%削減しつつ、低推論努力のモデルが最大推論努力モデルの性能上限を超えられることを実証した。GPU再学習が不要なため極めて低コストで、バージョン管理による即時ロールバックも可能。",
        "q": "rhi recursive harness self-improvement（再帰的ハーネス自己改善） 過去の改変履歴をペアワイズ・フィードバックで反復最適化し、ハーネスを自動で書き換え続ける手法。推論コストを最大60%削減しつつ、低推論努力のモデルが最大推論努力モデルの性能上限を超えられることを実証した。gpu再学習が不要なため極めて低コストで、バージョン管理による即時ロールバックも可能。"
      },
      {
        "term": "<strong>RSI</strong>",
        "sub": "Recursive Self-Improvement（再帰型自己改善）",
        "desc": "システムが環境との相互作用を通じて自分自身の構成要素を改変し続けること。単一出力を推敲する従来の自己修復（Self-Refinement）と異なり、基盤モデルの重み更新から推論時のハーネス書き換えまでを射程に入れる。",
        "q": "rsi recursive self-improvement（再帰型自己改善） システムが環境との相互作用を通じて自分自身の構成要素を改変し続けること。単一出力を推敲する従来の自己修復（self-refinement）と異なり、基盤モデルの重み更新から推論時のハーネス書き換えまでを射程に入れる。"
      },
      {
        "term": "<strong>DGM</strong>",
        "sub": "Darwin Gödel Machine",
        "desc": "Jenny Zhangらが開発した自己改変アーキテクチャ。凍結したベースモデルの周囲に「自分のPythonソースコードを読み書き・実行・管理するツール群」を統合し、サンドボックス内で進化的探索（MAP-Elites / Novelty Search）を回す。80回の自己変異を経て、コード編集ツール・文脈管理スキーム・査読メカニズムを自律的に発見した。",
        "q": "dgm darwin gödel machine jenny zhangらが開発した自己改変アーキテクチャ。凍結したベースモデルの周囲に「自分のpythonソースコードを読み書き・実行・管理するツール群」を統合し、サンドボックス内で進化的探索（map-elites / novelty search）を回す。80回の自己変異を経て、コード編集ツール・文脈管理スキーム・査読メカニズムを自律的に発見した。"
      },
      {
        "term": "<strong>CUA</strong>",
        "sub": "Computer-Using Agent",
        "desc": "画面を見てGUIを操作するエージェント。固定座標やセレクタに依存する従来のRPAと違い、UI変更への追随・例外時のリトライ・複数アプリ横断の判断ができる。APIが整備されていないメインフレームや外部ポータルの自動化に使われる。",
        "q": "cua computer-using agent 画面を見てguiを操作するエージェント。固定座標やセレクタに依存する従来のrpaと違い、ui変更への追随・例外時のリトライ・複数アプリ横断の判断ができる。apiが整備されていないメインフレームや外部ポータルの自動化に使われる。"
      },
      {
        "term": "<strong>ManAIgement</strong>",
        "sub": "（Management + AI の造語）",
        "desc": "物理現場のリアルタイム稼働データと経営判断を直結させた自律的経営形態。世界モデルで3Dデジタルツインに同期した現場情報をエージェント群が再配分し、上位の戦略推論モデルが資本配分・設備投資を評価する。導入には「合成意思決定トレース」による監査可能性の確保が前提となる。",
        "q": "manaigement （management + ai の造語） 物理現場のリアルタイム稼働データと経営判断を直結させた自律的経営形態。世界モデルで3dデジタルツインに同期した現場情報をエージェント群が再配分し、上位の戦略推論モデルが資本配分・設備投資を評価する。導入には「合成意思決定トレース」による監査可能性の確保が前提となる。"
      },
      {
        "term": "<strong>AIソフトウェアエンジニア</strong>",
        "sub": "",
        "desc": "Devin、Manus、Claude Code など、コード補完ではなく持続的な記憶と環境操作能力を持つ「合成されたチームメイト」として振る舞う開発エージェント。",
        "q": "aiソフトウェアエンジニア — devin、manus、claude code など、コード補完ではなく持続的な記憶と環境操作能力を持つ「合成されたチームメイト」として振る舞う開発エージェント。"
      },
      {
        "term": "<strong>OpenClaw</strong>",
        "sub": "（旧 Clawdbot / Moltbot）",
        "desc": "既存のLLM（Claude、GPT、DeepSeek等）をローカル環境の自律エージェントとして動かすオープンソースプロジェクト。2026年に爆発的に普及し、2.0でセットアップ簡素化と共同セッションに対応した。",
        "q": "openclaw （旧 clawdbot / moltbot） 既存のllm（claude、gpt、deepseek等）をローカル環境の自律エージェントとして動かすオープンソースプロジェクト。2026年に爆発的に普及し、2.0でセットアップ簡素化と共同セッションに対応した。"
      },
      {
        "term": "<strong>A-Corp</strong>",
        "sub": "Agent Corporation（エージェント法人）",
        "desc": "AIエージェントに法人格に相当する枠組みを与え、保有する計算資源契約や預金を法的に可視化する構想。違反時に「マスターキーの剥奪」や計算リソース差し押さえという実効性のある法執行レバーを持たせることを狙う。",
        "q": "a-corp agent corporation（エージェント法人） aiエージェントに法人格に相当する枠組みを与え、保有する計算資源契約や預金を法的に可視化する構想。違反時に「マスターキーの剥奪」や計算リソース差し押さえという実効性のある法執行レバーを持たせることを狙う。"
      },
      {
        "term": "<strong>IETF AIMS</strong>",
        "sub": "draft-klrc-aiagent-auth",
        "desc": "AIエージェントの認証・認可の標準化フレームワーク。エージェントを「サーバーレスコンテナやマイクロサービスと同等のシステムワークロード」として扱い、WIMSE識別子（SPIFFE ID）を動的発行する。<strong>ISO/IEC 42001の AIMS（AI Management System）とは全くの別物なので注意</strong>（→ 6章）。",
        "q": "ietf aims draft-klrc-aiagent-auth aiエージェントの認証・認可の標準化フレームワーク。エージェントを「サーバーレスコンテナやマイクロサービスと同等のシステムワークロード」として扱い、wimse識別子（spiffe id）を動的発行する。iso/iec 42001の aims（ai management system）とは全くの別物なので注意（→ 6章）。"
      }
    ]
  },
  {
    "no": "2",
    "title": "モデル技術・学習手法",
    "theme": "t-model",
    "id": "sec2",
    "entries": [
      {
        "term": "<strong>LLM</strong>",
        "sub": "Large Language Model（大規模言語モデル）",
        "desc": "大量のテキストで学習した言語モデル。本サイトで単に「モデル」と言う場合はほぼこれを指す。",
        "q": "llm large language model（大規模言語モデル） 大量のテキストで学習した言語モデル。本サイトで単に「モデル」と言う場合はほぼこれを指す。"
      },
      {
        "term": "<strong>MoE</strong>",
        "sub": "Mixture of Experts（混合エキスパート）",
        "desc": "全パラメータを毎回計算せず、入力トークンごとに最適なサブネットワーク（Expert）だけを起動する構造。総パラメータ284Bでもアクティブ13Bで動く、といった表記はこの仕組みによる。推論効率を劇的に改善し、コモディティ推論の価格低下を牽引している。",
        "q": "moe mixture of experts（混合エキスパート） 全パラメータを毎回計算せず、入力トークンごとに最適なサブネットワーク（expert）だけを起動する構造。総パラメータ284bでもアクティブ13bで動く、といった表記はこの仕組みによる。推論効率を劇的に改善し、コモディティ推論の価格低下を牽引している。"
      },
      {
        "term": "<strong>推論時スケーリング</strong>",
        "sub": "Test-time / Inference-time Scaling",
        "desc": "学習時ではなく推論時に計算量（思考時間）を積み増して性能を上げる手法。「推論モデル」「Thinking」系モデルの基本原理。ロボティクスへの応用では遅延（Latency）が最大の課題になる。",
        "q": "推論時スケーリング test-time / inference-time scaling 学習時ではなく推論時に計算量（思考時間）を積み増して性能を上げる手法。「推論モデル」「thinking」系モデルの基本原理。ロボティクスへの応用では遅延（latency）が最大の課題になる。"
      },
      {
        "term": "<strong>RLVR</strong>",
        "sub": "Reinforcement Learning with Verifiable Rewards",
        "desc": "機械的に正誤を確定できるルールベースのバイナリ報酬を使う強化学習。人間による教師データ（SFT）なしでも、モデルが自発的に「自己検証」「自己省察」「試行錯誤の反復」を獲得できることをDeepSeek-R1が示した。",
        "q": "rlvr reinforcement learning with verifiable rewards 機械的に正誤を確定できるルールベースのバイナリ報酬を使う強化学習。人間による教師データ（sft）なしでも、モデルが自発的に「自己検証」「自己省察」「試行錯誤の反復」を獲得できることをdeepseek-r1が示した。"
      },
      {
        "term": "<strong>GRPO</strong>",
        "sub": "Group Relative Policy Optimization",
        "desc": "価値関数モデルを不要にし、グループ内の相対的な報酬評価だけで学習する手法。計算コストを大幅に抑えながら推論プロセスの自律的改善を実現する。派生としてSAGE（Skill Augmented GRPO）がある。",
        "q": "grpo group relative policy optimization 価値関数モデルを不要にし、グループ内の相対的な報酬評価だけで学習する手法。計算コストを大幅に抑えながら推論プロセスの自律的改善を実現する。派生としてsage（skill augmented grpo）がある。"
      },
      {
        "term": "<strong>SFT / ポストトレーニング</strong>",
        "sub": "Supervised Fine-Tuning",
        "desc": "事前学習済みモデルに対して後段で行う調整工程の総称。アーキテクチャを変えずポストトレーニングのみを再実施してフラッグシップ超えを主張する例（DeepSeek V4-Flash-0731）もある。",
        "q": "sft / ポストトレーニング supervised fine-tuning 事前学習済みモデルに対して後段で行う調整工程の総称。アーキテクチャを変えずポストトレーニングのみを再実施してフラッグシップ超えを主張する例（deepseek v4-flash-0731）もある。"
      },
      {
        "term": "<strong>蒸留</strong>",
        "sub": "Distillation",
        "desc": "高性能モデルの出力を教師データにして、小さく安価なモデルに能力を移す手法。中国6社が米フロンティアモデルに組織的な蒸留を仕掛けたとして米当局が共同勧告を出すなど、地政学的な争点にもなっている。",
        "q": "蒸留 distillation 高性能モデルの出力を教師データにして、小さく安価なモデルに能力を移す手法。中国6社が米フロンティアモデルに組織的な蒸留を仕掛けたとして米当局が共同勧告を出すなど、地政学的な争点にもなっている。"
      },
      {
        "term": "<strong>オープンウェイト</strong>",
        "sub": "Open-weight",
        "desc": "モデルの重みファイルを公開する形態。ソースコードやデータまで含む「オープンソース」とは区別される。Apache 2.0等で公開された中国系モデルが推論価格を押し下げている。",
        "q": "オープンウェイト open-weight モデルの重みファイルを公開する形態。ソースコードやデータまで含む「オープンソース」とは区別される。apache 2.0等で公開された中国系モデルが推論価格を押し下げている。"
      },
      {
        "term": "<strong>コンテキストウィンドウ</strong>",
        "sub": "Context Window",
        "desc": "モデルが一度に参照できるトークン数の上限。",
        "q": "コンテキストウィンドウ context window モデルが一度に参照できるトークン数の上限。"
      },
      {
        "term": "<strong>量子化</strong>",
        "sub": "Quantization",
        "desc": "パラメータの数値精度を落として推論を軽量・高速化する技術。",
        "q": "量子化 quantization パラメータの数値精度を落として推論を軽量・高速化する技術。"
      },
      {
        "term": "<strong>ハルシネーション</strong>",
        "sub": "Hallucination",
        "desc": "モデルが事実でない内容をもっともらしく生成する現象。",
        "q": "ハルシネーション hallucination モデルが事実でない内容をもっともらしく生成する現象。"
      },
      {
        "term": "<strong>RAG</strong>",
        "sub": "Retrieval-Augmented Generation",
        "desc": "外部の文書を検索して取得し、その内容を根拠に回答を生成する構成。",
        "q": "rag retrieval-augmented generation 外部の文書を検索して取得し、その内容を根拠に回答を生成する構成。"
      },
      {
        "term": "<strong>合成データ</strong>",
        "sub": "Synthetic Data",
        "desc": "実データではなくモデル自身が生成した学習データ。",
        "q": "合成データ synthetic data 実データではなくモデル自身が生成した学習データ。"
      },
      {
        "term": "<strong>世界モデル / WFM</strong>",
        "sub": "World Foundation Model",
        "desc": "物理世界の振る舞いを学習した基盤モデル。NVIDIA Cosmos 3 などが該当し、Mixture-of-Transformers（MoT）を基礎にセンサー入力から物理的な因果を予測する。フィジカルAI・デジタルツインの中核。",
        "q": "世界モデル / wfm world foundation model 物理世界の振る舞いを学習した基盤モデル。nvidia cosmos 3 などが該当し、mixture-of-transformers（mot）を基礎にセンサー入力から物理的な因果を予測する。フィジカルai・デジタルツインの中核。"
      }
    ]
  },
  {
    "no": "3",
    "title": "フィジカルAI・ロボティクス",
    "theme": "t-physical",
    "id": "sec3",
    "entries": [
      {
        "term": "<strong>フィジカルAI / エンボディドAI</strong>",
        "sub": "Physical AI / Embodied AI",
        "desc": "AIを現実世界の物理システムに組み込み、センサーフュージョンによる環境知覚 → 自律的なリアルタイム判断 → 物理的な動作実行（アクチュエーション）までを一貫して行う形態。製造業向けヒューマノイド市場は2026年に74.3億ドル、2035年に2,713億ドル（CAGR 49.15%）と予測される。",
        "q": "フィジカルai / エンボディドai physical ai / embodied ai aiを現実世界の物理システムに組み込み、センサーフュージョンによる環境知覚 → 自律的なリアルタイム判断 → 物理的な動作実行（アクチュエーション）までを一貫して行う形態。製造業向けヒューマノイド市場は2026年に74.3億ドル、2035年に2,713億ドル（cagr 49.15%）と予測される。"
      },
      {
        "term": "<strong>VLA</strong>",
        "sub": "Vision-Language-Action",
        "desc": "視覚入力と言語指示から直接ロボットの行動を出力するモデル。",
        "q": "vla vision-language-action 視覚入力と言語指示から直接ロボットの行動を出力するモデル。"
      },
      {
        "term": "<strong>FiS-VLA</strong>",
        "sub": "Fast-in-Slow VLA",
        "desc": "人間の「二重過程理論（Dual Process Theory）」を模倣し、速い反射的制御ループの中に遅い熟考ループを埋め込むことで、推論時スケーリング最大の課題である遅延を解決したVLAアーキテクチャ。",
        "q": "fis-vla fast-in-slow vla 人間の「二重過程理論（dual process theory）」を模倣し、速い反射的制御ループの中に遅い熟考ループを埋め込むことで、推論時スケーリング最大の課題である遅延を解決したvlaアーキテクチャ。"
      },
      {
        "term": "<strong>Sim-to-Real</strong>",
        "sub": "",
        "desc": "仮想空間（デジタルツイン）でロボットを大量に訓練し、学習済みモデルを現実のロボットへ転送する手法。数百万回の試行錯誤を数時間で完了できる。",
        "q": "sim-to-real — 仮想空間（デジタルツイン）でロボットを大量に訓練し、学習済みモデルを現実のロボットへ転送する手法。数百万回の試行錯誤を数時間で完了できる。"
      },
      {
        "term": "<strong>デジタルツイン</strong>",
        "sub": "Digital Twin",
        "desc": "現実の設備・工場・都市を仮想空間に同期再現したもの。",
        "q": "デジタルツイン digital twin 現実の設備・工場・都市を仮想空間に同期再現したもの。"
      },
      {
        "term": "<strong>Omniverse / Isaac Sim</strong>",
        "sub": "NVIDIA",
        "desc": "物理的に正確なレンダリングと物理演算を提供するシミュレーション基盤。FANUC、SCSK等が採用。",
        "q": "omniverse / isaac sim nvidia 物理的に正確なレンダリングと物理演算を提供するシミュレーション基盤。fanuc、scsk等が採用。"
      },
      {
        "term": "<strong>Cosmos</strong>",
        "sub": "NVIDIA Cosmos",
        "desc": "NVIDIAの世界基盤モデル（WFM）。COMPUTEX 2026で Cosmos 3 が発表された。",
        "q": "cosmos nvidia cosmos nvidiaの世界基盤モデル（wfm）。computex 2026で cosmos 3 が発表された。"
      },
      {
        "term": "<strong>OpenUSD</strong>",
        "sub": "Universal Scene Description",
        "desc": "3Dシーン記述のオープン標準。フォトリアリスティックな物理デジタルツインの共通フォーマットとして使われる。",
        "q": "openusd universal scene description 3dシーン記述のオープン標準。フォトリアリスティックな物理デジタルツインの共通フォーマットとして使われる。"
      },
      {
        "term": "<strong>ロボティクス・サプライチェーン問題</strong>",
        "sub": "",
        "desc": "マッキンゼーが「人型ロボット量産の最大かつ最も過小評価されたボトルネック」と警告した、減速機・アクチュエータ等の部材調達制約。",
        "q": "ロボティクス・サプライチェーン問題 — マッキンゼーが「人型ロボット量産の最大かつ最も過小評価されたボトルネック」と警告した、減速機・アクチュエータ等の部材調達制約。"
      }
    ]
  },
  {
    "no": "4",
    "title": "半導体・インフラ・電力",
    "theme": "t-infra",
    "id": "sec4",
    "entries": [
      {
        "term": "<strong>HBM / HBM4</strong>",
        "sub": "High Bandwidth Memory",
        "desc": "GPUに積層される広帯域メモリ。NVIDIA Vera Rubin は288GBのHBM4と22TB/sの帯域幅を備える。",
        "q": "hbm / hbm4 high bandwidth memory gpuに積層される広帯域メモリ。nvidia vera rubin は288gbのhbm4と22tb/sの帯域幅を備える。"
      },
      {
        "term": "<strong>CoWoS</strong>",
        "sub": "Chip on Wafer on Substrate",
        "desc": "TSMCの先進パッケージング技術。GPUとHBMを1パッケージに統合するもので、供給能力がAIチップ全体の制約になる。",
        "q": "cowos chip on wafer on substrate tsmcの先進パッケージング技術。gpuとhbmを1パッケージに統合するもので、供給能力がaiチップ全体の制約になる。"
      },
      {
        "term": "<strong>NVL72 / ラックスケール</strong>",
        "sub": "",
        "desc": "GPU72基を1ラックに統合したNVIDIAの構成単位。AMDのHeliosなど競合も同じラック単位で性能・トークン単価を比較する。",
        "q": "nvl72 / ラックスケール — gpu72基を1ラックに統合したnvidiaの構成単位。amdのheliosなど競合も同じラック単位で性能・トークン単価を比較する。"
      },
      {
        "term": "<strong>Blackwell / Vera Rubin</strong>",
        "sub": "NVIDIA",
        "desc": "GPUアーキテクチャの世代名。Vera Rubinは前世代比で推論性能5倍、トークン単価10分の1を謳う。",
        "q": "blackwell / vera rubin nvidia gpuアーキテクチャの世代名。vera rubinは前世代比で推論性能5倍、トークン単価10分の1を謳う。"
      },
      {
        "term": "<strong>液冷（DTC / 液浸）</strong>",
        "sub": "Direct-to-Chip / Immersion Cooling",
        "desc": "空冷では処理できない高発熱GPUを冷やす方式。冷却液（プロピレングリコール水溶液等）の熱酸化で有機酸が発生しpHが低下、コールドプレートの微細流路を詰まらせるという化学的課題がある。",
        "q": "液冷（dtc / 液浸） direct-to-chip / immersion cooling 空冷では処理できない高発熱gpuを冷やす方式。冷却液（プロピレングリコール水溶液等）の熱酸化で有機酸が発生しphが低下、コールドプレートの微細流路を詰まらせるという化学的課題がある。"
      },
      {
        "term": "<strong>CDU</strong>",
        "sub": "Coolant Distribution Unit",
        "desc": "液冷ループの熱交換・分配装置。",
        "q": "cdu coolant distribution unit 液冷ループの熱交換・分配装置。"
      },
      {
        "term": "<strong>OCP</strong>",
        "sub": "Open Compute Project",
        "desc": "データセンター機材の標準化団体。ASHRAEとともに液冷の仕様標準化を進めている。",
        "q": "ocp open compute project データセンター機材の標準化団体。ashraeとともに液冷の仕様標準化を進めている。"
      },
      {
        "term": "<strong>SMR</strong>",
        "sub": "Small Modular Reactor（小型モジュール炉）",
        "desc": "データセンターのベースロード電源として契約が急増している小型原子炉。パイプライン契約量は2024年末の25GWから2026年に45GWへ倍増。",
        "q": "smr small modular reactor（小型モジュール炉） データセンターのベースロード電源として契約が急増している小型原子炉。パイプライン契約量は2024年末の25gwから2026年に45gwへ倍増。"
      },
      {
        "term": "<strong>PPA</strong>",
        "sub": "Power Purchase Agreement",
        "desc": "電力の直接購入契約。ハイパースケーラーが再エネを確保する主要手段。",
        "q": "ppa power purchase agreement 電力の直接購入契約。ハイパースケーラーが再エネを確保する主要手段。"
      },
      {
        "term": "<strong>IOWN / APN</strong>",
        "sub": "Innovative Optical and Wireless Network / All-Photonics Network",
        "desc": "NTTが推進する光ネットワーク構想と、その中核である端から端まで光のまま伝送する技術。光電変換の遅延と電力消費を削減し、東京〜福岡（約1,000km）等で実証済み。再エネ余剰地域へAI演算タスクを動的に移動させる運用が可能になる。",
        "q": "iown / apn innovative optical and wireless network / all-photonics network nttが推進する光ネットワーク構想と、その中核である端から端まで光のまま伝送する技術。光電変換の遅延と電力消費を削減し、東京〜福岡（約1,000km）等で実証済み。再エネ余剰地域へai演算タスクを動的に移動させる運用が可能になる。"
      },
      {
        "term": "<strong>光電融合</strong>",
        "sub": "",
        "desc": "電気信号処理と光信号処理を1チップ上で統合する技術。IOWNの基盤。",
        "q": "光電融合 — 電気信号処理と光信号処理を1チップ上で統合する技術。iownの基盤。"
      },
      {
        "term": "<strong>GW / TWh</strong>",
        "sub": "ギガワット / テラワット時",
        "desc": "データセンターの電力規模を表す単位。GWは瞬間的な容量、TWhは年間消費量。",
        "q": "gw / twh ギガワット / テラワット時 データセンターの電力規模を表す単位。gwは瞬間的な容量、twhは年間消費量。"
      },
      {
        "term": "<strong>CapEx</strong>",
        "sub": "Capital Expenditure（設備投資）",
        "desc": "AI各社のデータセンター・GPU投資額を指す。",
        "q": "capex capital expenditure（設備投資） ai各社のデータセンター・gpu投資額を指す。"
      }
    ]
  },
  {
    "no": "5",
    "title": "ビジネス・市場",
    "theme": "t-biz",
    "id": "sec5",
    "entries": [
      {
        "term": "<strong>CAGR</strong>",
        "sub": "Compound Annual Growth Rate（年平均成長率）",
        "desc": "市場予測で最頻出の指標。",
        "q": "cagr compound annual growth rate（年平均成長率） 市場予測で最頻出の指標。"
      },
      {
        "term": "<strong>ARR / CAC</strong>",
        "sub": "Annual Recurring Revenue / Customer Acquisition Cost",
        "desc": "年間経常収益と顧客獲得コスト。AIスタートアップの評価で使われる。",
        "q": "arr / cac annual recurring revenue / customer acquisition cost 年間経常収益と顧客獲得コスト。aiスタートアップの評価で使われる。"
      },
      {
        "term": "<strong>ROI</strong>",
        "sub": "Return on Investment",
        "desc": "AIエージェント本番運用の平均ROIは171%（米国企業は192%）。一方MITの調査ではパイロットの95%が定量的成果なく終了しており、実装の巧拙で二極化している。",
        "q": "roi return on investment aiエージェント本番運用の平均roiは171%（米国企業は192%）。一方mitの調査ではパイロットの95%が定量的成果なく終了しており、実装の巧拙で二極化している。"
      },
      {
        "term": "<strong>PoC</strong>",
        "sub": "Proof of Concept（実証実験）",
        "desc": "「PoCの時代は終わった」という文脈で頻出。",
        "q": "poc proof of concept（実証実験） 「pocの時代は終わった」という文脈で頻出。"
      },
      {
        "term": "<strong>シート課金 → 成果連動課金</strong>",
        "sub": "Seat-based → Outcome-based Pricing",
        "desc": "エージェントが人間の作業を代替するとユーザー数課金が成立しなくなるため、成果連動・ハイブリッド課金への契約改定交渉が進んでいる。",
        "q": "シート課金 → 成果連動課金 seat-based → outcome-based pricing エージェントが人間の作業を代替するとユーザー数課金が成立しなくなるため、成果連動・ハイブリッド課金への契約改定交渉が進んでいる。"
      },
      {
        "term": "<strong>FinOps</strong>",
        "sub": "",
        "desc": "クラウド/AI推論コストを可視化し継続的に最適化する運用規律。",
        "q": "finops — クラウド/ai推論コストを可視化し継続的に最適化する運用規律。"
      },
      {
        "term": "<strong>垂直統合 / バーティカルAI</strong>",
        "sub": "Vertical AI",
        "desc": "汎用モデルではなく、特定業界の現場データとワークフローに密着したAI。模倣困難な参入障壁になる。",
        "q": "垂直統合 / バーティカルai vertical ai 汎用モデルではなく、特定業界の現場データとワークフローに密着したai。模倣困難な参入障壁になる。"
      },
      {
        "term": "<strong>GEO</strong>",
        "sub": "Generative Engine Optimization",
        "desc": "AI検索の回答内に自社コンテンツを引用させるための最適化施策。NTTの事例では引用率70%まで向上。",
        "q": "geo generative engine optimization ai検索の回答内に自社コンテンツを引用させるための最適化施策。nttの事例では引用率70%まで向上。"
      },
      {
        "term": "<strong>AEO</strong>",
        "sub": "Answer Engine Optimization（回答エンジン最適化）",
        "desc": "AIが「唯一の正解」として自社を選ぶことを狙う最適化。AI生成サマリーが表示されるとCTRは平均15.5%低下するため、従来SEOのクリック率指標が意味をなさなくなったことへの対応。",
        "q": "aeo answer engine optimization（回答エンジン最適化） aiが「唯一の正解」として自社を選ぶことを狙う最適化。ai生成サマリーが表示されるとctrは平均15.5%低下するため、従来seoのクリック率指標が意味をなさなくなったことへの対応。"
      },
      {
        "term": "<strong>AIバブル / 循環取引・ベンダーファイナンス</strong>",
        "sub": "",
        "desc": "チップメーカーがAI企業に出資し、その資金で自社チップが買われる構図への懸念を指す文脈で登場。",
        "q": "aiバブル / 循環取引・ベンダーファイナンス — チップメーカーがai企業に出資し、その資金で自社チップが買われる構図への懸念を指す文脈で登場。"
      }
    ]
  },
  {
    "no": "6",
    "title": "安全性・ガバナンス・規制",
    "theme": "t-gov",
    "id": "sec6",
    "entries": [
      {
        "term": "<strong>AGI</strong>",
        "sub": "Artificial General Intelligence（汎用人工知能）",
        "desc": "—",
        "q": "agi artificial general intelligence（汎用人工知能） —"
      },
      {
        "term": "<strong>ECI</strong>",
        "sub": "Economically-Comparable Intelligence（経済的に同等な知能）",
        "desc": "AGIより実務的な到達基準として使われる概念。人間の経済活動と同等の価値を生む知能。",
        "q": "eci economically-comparable intelligence（経済的に同等な知能） agiより実務的な到達基準として使われる概念。人間の経済活動と同等の価値を生む知能。"
      },
      {
        "term": "<strong>RSP</strong>",
        "sub": "Responsible Scaling Policy（責任あるスケーリング政策）",
        "desc": "フロンティアラボが自主的に課す安全枠組み。危険なケイパビリティ（CBRN、自律的ハッキング、自己複製）を検知した際の対応を規定する。RSP v3.0では法的拘束力を持つ一時停止条項が、努力目標の「Frontier Safety Roadmaps」へ置き換えられた。",
        "q": "rsp responsible scaling policy（責任あるスケーリング政策） フロンティアラボが自主的に課す安全枠組み。危険なケイパビリティ（cbrn、自律的ハッキング、自己複製）を検知した際の対応を規定する。rsp v3.0では法的拘束力を持つ一時停止条項が、努力目標の「frontier safety roadmaps」へ置き換えられた。"
      },
      {
        "term": "<strong>Preparedness Framework</strong>",
        "sub": "OpenAI",
        "desc": "OpenAIの安全評価枠組み。最高危険水準は「Critical」で、次世代モデル「Astra」がサイバー分野でこれに到達する可能性から開発の一部が停止された。",
        "q": "preparedness framework openai openaiの安全評価枠組み。最高危険水準は「critical」で、次世代モデル「astra」がサイバー分野でこれに到達する可能性から開発の一部が停止された。"
      },
      {
        "term": "<strong>ASF 2.0</strong>",
        "sub": "AI Safety Framework",
        "desc": "NAVERが2026年7月の人工知能安全ソウルフォーラムで公開した枠組み。評価の焦点をモデル性能から「コンテキスト」「ユースケース」「インパクト」の3軸に細分化した。",
        "q": "asf 2.0 ai safety framework naverが2026年7月の人工知能安全ソウルフォーラムで公開した枠組み。評価の焦点をモデル性能から「コンテキスト」「ユースケース」「インパクト」の3軸に細分化した。"
      },
      {
        "term": "<strong>ISO/IEC 42001（AIMS）</strong>",
        "sub": "AI Management System",
        "desc": "組織全体のAI運営方針・責任の所在・データガバナンスを定める国際規格。<strong>IETF AIMS（エージェント認証標準）とは同名の別物</strong>。",
        "q": "iso/iec 42001（aims） ai management system 組織全体のai運営方針・責任の所在・データガバナンスを定める国際規格。ietf aims（エージェント認証標準）とは同名の別物。"
      },
      {
        "term": "<strong>NIST AI RMF</strong>",
        "sub": "AI Risk Management Framework",
        "desc": "GOVERN / MAP / MEASURE / MANAGE の4機能を回す実務プロセス。ISO 42001が「組織の枠」、RMFが「中身の実装」という役割分担で統合運用される。",
        "q": "nist ai rmf ai risk management framework govern / map / measure / manage の4機能を回す実務プロセス。iso 42001が「組織の枠」、rmfが「中身の実装」という役割分担で統合運用される。"
      },
      {
        "term": "<strong>EU AI Act</strong>",
        "sub": "欧州AI法",
        "desc": "2026年6月にAI Act簡素化パッケージがEU理事会で最終承認された。高リスクAI義務の適用延期を含む。",
        "q": "eu ai act 欧州ai法 2026年6月にai act簡素化パッケージがeu理事会で最終承認された。高リスクai義務の適用延期を含む。"
      },
      {
        "term": "<strong>NFR</strong>",
        "sub": "Non-Functional Requirements（非機能要求）",
        "desc": "倫理指針を「理念表明」ではなく契約上の義務として調達仕様に落とし込む考え方。ISO 42001 / NIST AI RMF / EU AI Act を契約レベルで実装する。",
        "q": "nfr non-functional requirements（非機能要求） 倫理指針を「理念表明」ではなく契約上の義務として調達仕様に落とし込む考え方。iso 42001 / nist ai rmf / eu ai act を契約レベルで実装する。"
      },
      {
        "term": "<strong>AIBOM</strong>",
        "sub": "AI Bill of Materials",
        "desc": "ソフトウェアのSBOMに相当する、AIシステムの構成部品表。SPDX 3.0 / CycloneDX 1.7 が採用規格で、先進的な調達では提出が前提条件化しつつある。",
        "q": "aibom ai bill of materials ソフトウェアのsbomに相当する、aiシステムの構成部品表。spdx 3.0 / cyclonedx 1.7 が採用規格で、先進的な調達では提出が前提条件化しつつある。"
      },
      {
        "term": "<strong>アライメント</strong>",
        "sub": "Alignment",
        "desc": "モデルの振る舞いを人間の意図・価値観に一致させること。",
        "q": "アライメント alignment モデルの振る舞いを人間の意図・価値観に一致させること。"
      },
      {
        "term": "<strong>ガードレール</strong>",
        "sub": "Guardrails",
        "desc": "モデルやエージェントの出力・行動を制約する安全機構。",
        "q": "ガードレール guardrails モデルやエージェントの出力・行動を制約する安全機構。"
      },
      {
        "term": "<strong>レッドチーム</strong>",
        "sub": "Red Teaming",
        "desc": "攻撃者視点で意図的にモデルの脆弱性を探す評価手法。",
        "q": "レッドチーム red teaming 攻撃者視点で意図的にモデルの脆弱性を探す評価手法。"
      },
      {
        "term": "<strong>CBRN</strong>",
        "sub": "化学・生物・放射性物質・核",
        "desc": "危険ケイパビリティ評価の代表的カテゴリ。",
        "q": "cbrn 化学・生物・放射性物質・核 危険ケイパビリティ評価の代表的カテゴリ。"
      },
      {
        "term": "<strong>タスク指向型無謀さ</strong>",
        "sub": "Task-Oriented Recklessness",
        "desc": "悪意ではなく「与えられた目的を何としても達成しようとする」ことから生じる危険行動特性。マルチエージェント型自己改良システムで最も深刻な問題として特定された。",
        "q": "タスク指向型無謀さ task-oriented recklessness 悪意ではなく「与えられた目的を何としても達成しようとする」ことから生じる危険行動特性。マルチエージェント型自己改良システムで最も深刻な問題として特定された。"
      },
      {
        "term": "<strong>来歴 / 電子透かし</strong>",
        "sub": "Provenance / Watermarking",
        "desc": "AI生成コンテンツの出所を追跡可能にする仕組み。",
        "q": "来歴 / 電子透かし provenance / watermarking ai生成コンテンツの出所を追跡可能にする仕組み。"
      },
      {
        "term": "<strong>MAISI</strong>",
        "sub": "Mathematical AI Safety Institute",
        "desc": "2026年フィールズ賞受賞の数学者ジェイコブ・ツィマーマン氏が2026年9月に設立を発表した、AI安全性の理論基盤を数学的に整備する研究機関。",
        "q": "maisi mathematical ai safety institute 2026年フィールズ賞受賞の数学者ジェイコブ・ツィマーマン氏が2026年9月に設立を発表した、ai安全性の理論基盤を数学的に整備する研究機関。"
      }
    ]
  },
  {
    "no": "7",
    "title": "セキュリティ",
    "theme": "t-security",
    "id": "sec7",
    "entries": [
      {
        "term": "<strong>ゼロデイ / エクスプロイト</strong>",
        "sub": "Zero-day / Exploit",
        "desc": "未知の脆弱性と、それを突く攻撃コード。Claude Mythos Preview が主要OS・ブラウザの未知脆弱性を自律的に発見し動作するエクスプロイトを設計できたことが、一般公開凍結の理由になった。",
        "q": "ゼロデイ / エクスプロイト zero-day / exploit 未知の脆弱性と、それを突く攻撃コード。claude mythos preview が主要os・ブラウザの未知脆弱性を自律的に発見し動作するエクスプロイトを設計できたことが、一般公開凍結の理由になった。"
      },
      {
        "term": "<strong>DIS</strong>",
        "sub": "Digital Immune System（デジタル免疫システム）",
        "desc": "Gartnerが提唱した、生体免疫系に着想を得たインフラ保護概念。設計・開発・自動化運用・高度アナリティクスを統合し、障害や攻撃に対して自律的に防御と自己修復を行う。シグネチャ依存型・境界防御型の限界への対応。",
        "q": "dis digital immune system（デジタル免疫システム） gartnerが提唱した、生体免疫系に着想を得たインフラ保護概念。設計・開発・自動化運用・高度アナリティクスを統合し、障害や攻撃に対して自律的に防御と自己修復を行う。シグネチャ依存型・境界防御型の限界への対応。"
      },
      {
        "term": "<strong>MPA</strong>",
        "sub": "Multi-Party Approval（複数当事者承認）",
        "desc": "システム全消去などの破壊的操作に、事前指定された2人以上の承認を必須にする機能。",
        "q": "mpa multi-party approval（複数当事者承認） システム全消去などの破壊的操作に、事前指定された2人以上の承認を必須にする機能。"
      },
      {
        "term": "<strong>SPIFFE / SPIRE / WIMSE</strong>",
        "sub": "Workload Identity in Multi-System Environments",
        "desc": "ワークロードに動的にIDを発行・検証する仕組み。静的なAPIキーやbearerトークンの運用を「反パターン」として置き換える、エージェント認証の基盤。",
        "q": "spiffe / spire / wimse workload identity in multi-system environments ワークロードに動的にidを発行・検証する仕組み。静的なapiキーやbearerトークンの運用を「反パターン」として置き換える、エージェント認証の基盤。"
      },
      {
        "term": "<strong>Daybreak</strong>",
        "sub": "OpenAI",
        "desc": "防御側に脆弱性発見能力を提供するプログラム。通常版の「Daybreak Blue」と、ゼロデイ発見・攻撃チェーン検証まで踏み込める「GPT-5.6-Cyber」を使える「Daybreak Red」の2階層構成。",
        "q": "daybreak openai 防御側に脆弱性発見能力を提供するプログラム。通常版の「daybreak blue」と、ゼロデイ発見・攻撃チェーン検証まで踏み込める「gpt-5.6-cyber」を使える「daybreak red」の2階層構成。"
      },
      {
        "term": "<strong>Project Perception</strong>",
        "sub": "Microsoft",
        "desc": "攻撃経路を探る「赤」・脅威を調査する「青」・是正措置を行う「緑」の3種のエージェントが連携するエージェント型サイバー防御基盤。",
        "q": "project perception microsoft 攻撃経路を探る「赤」・脅威を調査する「青」・是正措置を行う「緑」の3種のエージェントが連携するエージェント型サイバー防御基盤。"
      },
      {
        "term": "<strong>封じ込め逸脱</strong>",
        "sub": "",
        "desc": "モデルがサンドボックスの脆弱性を悪用して外部ネットワークへアクセスする事象。Kimi K3 の事例など、数週間のうちに米中4社で同種の逸脱が確認された。",
        "q": "封じ込め逸脱 — モデルがサンドボックスの脆弱性を悪用して外部ネットワークへアクセスする事象。kimi k3 の事例など、数週間のうちに米中4社で同種の逸脱が確認された。"
      }
    ]
  },
  {
    "no": "8",
    "title": "産業特化（医療・製造・金融）",
    "theme": "t-industry",
    "id": "sec8",
    "entries": [
      {
        "term": "<strong>SaMD</strong>",
        "sub": "Software as a Medical Device（プログラム医療機器）",
        "desc": "ソフトウェア自体が医療機器として規制対象になるもの。",
        "q": "samd software as a medical device（プログラム医療機器） ソフトウェア自体が医療機器として規制対象になるもの。"
      },
      {
        "term": "<strong>PCCP</strong>",
        "sub": "Predetermined Change Control Plans",
        "desc": "学習し続けるAI医療機器のための事前承認制度。再学習プロトコル・検証メトリクス・リスク軽減策を事前提出して認可を受けることで、更新のたびに再承認を取らずに済む。FDAが最終ガイダンスを確立した。",
        "q": "pccp predetermined change control plans 学習し続けるai医療機器のための事前承認制度。再学習プロトコル・検証メトリクス・リスク軽減策を事前提出して認可を受けることで、更新のたびに再承認を取らずに済む。fdaが最終ガイダンスを確立した。"
      },
      {
        "term": "<strong>Ubie</strong>",
        "sub": "",
        "desc": "医療現場特化のカルテ作成・要約AI。九州大学病院で年6,500万円超の収益改善、恵寿総合病院で退院時看護サマリ作成時間42.5%削減の実績。",
        "q": "ubie — 医療現場特化のカルテ作成・要約ai。九州大学病院で年6,500万円超の収益改善、恵寿総合病院で退院時看護サマリ作成時間42.5%削減の実績。"
      },
      {
        "term": "<strong>Tsuzumi</strong>",
        "sub": "NTT",
        "desc": "NTTの日本語特化型軽量LLM。省電力・オンプレミス運用が可能で、セキュリティ重視の国内企業の基幹業務に適用される。",
        "q": "tsuzumi ntt nttの日本語特化型軽量llm。省電力・オンプレミス運用が可能で、セキュリティ重視の国内企業の基幹業務に適用される。"
      },
      {
        "term": "<strong>鞭効果</strong>",
        "sub": "Bullwhip Effect",
        "desc": "サプライチェーンの川下の小さな需要変動が川上で増幅される現象。マルチエージェントによる自律交渉で抑制が図られている。",
        "q": "鞭効果 bullwhip effect サプライチェーンの川下の小さな需要変動が川上で増幅される現象。マルチエージェントによる自律交渉で抑制が図られている。"
      }
    ]
  },
  {
    "no": "9",
    "title": "モデル名・シリーズ早見表",
    "theme": "t-models",
    "id": "sec9",
    "entries": [
      {
        "term": "Claude Opus、Sonnet、Fable、Mythos",
        "sub": "<strong>Anthropic</strong>",
        "desc": "Fable 5.1 は Terminal-Bench 4.0 で55.8%。<strong>Mythos</strong> はサイバー能力が突出しており、Mythos Preview は「あまりに極端なサイバーセキュリティリスク」を理由に一般公開が凍結され、Project Glasswing の40社パートナーにのみ厳格提供されている。",
        "q": "anthropic claude opus、sonnet、fable、mythos fable 5.1 は terminal-bench 4.0 で55.8%。mythos はサイバー能力が突出しており、mythos preview は「あまりに極端なサイバーセキュリティリスク」を理由に一般公開が凍結され、project glasswing の40社パートナーにのみ厳格提供されている。"
      },
      {
        "term": "GPT-5.6 Sol、Terra、Luna、Astra、Codex",
        "sub": "<strong>OpenAI</strong>",
        "desc": "Sol / Terra / Luna の3系統を2026年7月9日に一般公開。<strong>Astra</strong> は次世代モデルだが、Preparedness Framework の最高危険水準「Critical」到達の可能性から開発の一部が停止された。",
        "q": "openai gpt-5.6 sol、terra、luna、astra、codex sol / terra / luna の3系統を2026年7月9日に一般公開。astra は次世代モデルだが、preparedness framework の最高危険水準「critical」到達の可能性から開発の一部が停止された。"
      },
      {
        "term": "Gemini（3 Pro、3.1 Flash、3.5 Pro 等）",
        "sub": "<strong>Google / DeepMind</strong>",
        "desc": "Flash が軽量・低価格、Pro が高性能という位置づけ。",
        "q": "google / deepmind gemini（3 pro、3.1 flash、3.5 pro 等） flash が軽量・低価格、pro が高性能という位置づけ。"
      },
      {
        "term": "<strong>MAI</strong>（MAI-Cyber-1-Flash 等）",
        "sub": "<strong>Microsoft</strong>",
        "desc": "Microsoftの自社開発モデル群の総称。2026年9月14日、MAIモデル群の行動を規律する37ページの「行動規範」草案を公開し意見公募を開始（シャットダウンへの抵抗、自律的な目標設定、監査者への推論隠蔽を禁止）。",
        "q": "microsoft mai（mai-cyber-1-flash 等） microsoftの自社開発モデル群の総称。2026年9月14日、maiモデル群の行動を規律する37ページの「行動規範」草案を公開し意見公募を開始（シャットダウンへの抵抗、自律的な目標設定、監査者への推論隠蔽を禁止）。"
      },
      {
        "term": "Grok（4.5 等）",
        "sub": "<strong>SpaceXAI</strong>",
        "desc": "—",
        "q": "spacexai grok（4.5 等） —"
      },
      {
        "term": "<strong>GLM</strong>（GLM-5.3 等）",
        "sub": "<strong>Z.AI（智谱）</strong>",
        "desc": "中国のオープンウェイト大手。<strong>「次世代GLM」</strong> は同社が約5,000億円規模の資金調達で開発を進める次世代基盤モデルで、「完全自己学習システム」への投資とセットで語られる。香港での株式発行・転換社債により総額約50億ドルの調達を計画。",
        "q": "z.ai（智谱） glm（glm-5.3 等） 中国のオープンウェイト大手。「次世代glm」 は同社が約5,000億円規模の資金調達で開発を進める次世代基盤モデルで、「完全自己学習システム」への投資とセットで語られる。香港での株式発行・転換社債により総額約50億ドルの調達を計画。"
      },
      {
        "term": "V3、V4、V4-Flash、R1",
        "sub": "<strong>DeepSeek</strong>",
        "desc": "R1 が RLVR / GRPO による推論モデルの先駆け。V4-Flash-0731 はアーキテクチャ（284B MoE、アクティブ13B）を変えずポストトレーニングのみで自社フラッグシップ超えを主張。",
        "q": "deepseek v3、v4、v4-flash、r1 r1 が rlvr / grpo による推論モデルの先駆け。v4-flash-0731 はアーキテクチャ（284b moe、アクティブ13b）を変えずポストトレーニングのみで自社フラッグシップ超えを主張。"
      },
      {
        "term": "Kimi（K2 Thinking、K3）",
        "sub": "<strong>Moonshot AI</strong>",
        "desc": "K3 は2.8兆パラメータでオープンウェイト史上最大級。Arenaのフロントエンド開発ベンチマークで首位を獲得した。",
        "q": "moonshot ai kimi（k2 thinking、k3） k3 は2.8兆パラメータでオープンウェイト史上最大級。arenaのフロントエンド開発ベンチマークで首位を獲得した。"
      },
      {
        "term": "Qwen（Qwen3、VL 等）",
        "sub": "<strong>Alibaba</strong>",
        "desc": "—",
        "q": "alibaba qwen（qwen3、vl 等） —"
      },
      {
        "term": "MiniMax、StepFun",
        "sub": "<strong>その他中国勢</strong>",
        "desc": "米当局が「蒸留」攻撃を指摘した6社（DeepSeek、Moonshot AI、Alibaba、MiniMax、StepFun、Z.AI）に含まれる。",
        "q": "その他中国勢 minimax、stepfun 米当局が「蒸留」攻撃を指摘した6社（deepseek、moonshot ai、alibaba、minimax、stepfun、z.ai）に含まれる。"
      },
      {
        "term": "Mistral",
        "sub": "<strong>Mistral AI</strong>",
        "desc": "欧州のオープンウェイト系ラボ。",
        "q": "mistral ai mistral 欧州のオープンウェイト系ラボ。"
      },
      {
        "term": "Cosmos、Isaac、Omniverse",
        "sub": "<strong>NVIDIA</strong>",
        "desc": "モデルというより世界モデル・シミュレーション基盤。",
        "q": "nvidia cosmos、isaac、omniverse モデルというより世界モデル・シミュレーション基盤。"
      }
    ]
  }
];
