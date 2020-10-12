# frozen_string_literal: true

module BCDice
  module GameSystem
    class Insane < Base
      # ゲームシステムの識別子
      ID = 'Insane'

      # ゲームシステム名
      NAME = 'インセイン'

      # ゲームシステム名の読みがな
      SORT_KEY = 'いんせいん'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定
        スペシャル／ファンブル／成功／失敗を判定
        ・各種表
        シーン表　　　ST
        　本当は怖い現代日本シーン表 HJST／狂騒の二〇年代シーン表 MTST
        　暗黒のヴィクトリアシーン表 DVST
        形容表　　　　DT
        　本体表 BT／部位表 PT
        感情表　　　　　　FT
        職業表　　　　　　JT
        バッドエンド表　　BET
        ランダム特技決定表　RTT
        指定特技(暴力)表　　(TVT)
        指定特技(情動)表　　(TET)
        指定特技(知覚)表　　(TPT)
        指定特技(技術)表　　(TST)
        指定特技(知識)表　　(TKT)
        指定特技(怪異)表　　(TMT)
        会話ホラースケープ表(CHT)
        街中ホラースケープ表(VHT)
        不意訪問ホラースケープ表(IHT)
        廃墟遭遇ホラースケープ表(RHT)
        野外遭遇ホラースケープ表(MHT)
        情報潜在ホラースケープ表(LHT)
        遭遇表　都市　(ECT)　山林　(EMT)　海辺　(EAT)/反応表　RET
        残業ホラースケープ表　OHT/残業電話表　OPT/残業シーン表　OWT
        社名決定表1　CNT1/社名決定表2　CNT2/社名決定表3　CNT3
        暫定整理番号作成表　IRN
        ・D66ダイスあり
      INFO_MESSAGE_TEXT

      register_prefix("BET", "RTT", "IRN")

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @sort_barabara_dice = true
        @enabled_d66 = true
        @d66_sort_type = D66SortType::ASC
      end

      # ゲーム別成功度判定(2D6)
      def check_2D6(total, dice_total, _dice_list, cmp_op, target)
        return '' unless cmp_op == :>=

        if dice_total <= 2
          " ＞ ファンブル(判定失敗。山札から【狂気】を1枚獲得)"
        elsif dice_total >= 12
          " ＞ スペシャル(判定成功。【生命力】1点か【正気度】1点回復)"
        elsif target == "?"
          ""
        elsif total >= target
          " ＞ 成功"
        else
          " ＞ 失敗"
        end
      end

      def eval_game_system_specific_command(command)
        case command
        when 'BET'
          type = 'バッドエンド表'
          output, total_n = get_badend_table
        when 'RTT'
          type = 'ランダム特技決定表'
          output, total_n = get_random_skill_table
        when 'IRN'
          type = '暫定整理番号作成'
          output, total_n = get_interim_reference_number
        else
          return roll_tables(command, TABLES)
        end

        return "#{type}(#{total_n}) ＞ #{output}"
      end

      private

      # バッドエンド表
      def get_badend_table
        table = [
          'あなたの周りに漆黒の闇が、異形の前肢が、無数の触手が集まってくる。彼らは、新たな仲間の誕生を祝福しているのだ。あなたは、もう怪異に怖がることはない。なぜなら、あなた自身が怪異となったからだ。以降、あなたは怪異のNPCとなって登場する。',
          lambda { return "牢獄のような、手術室のような薄暗い部屋に監禁される。そして、毎日のようにひどい拷問を受けることになった。何とか隙を見て逃げ出すことができたが……。#{get_random_skill_table_text_only}の特技が【恐怖心】になる。" },
          '間一髪のところを、謎の組織のエージェントに助けられる。「君は見所がある。どうだい？　我々と一緒にやってみないか」あなたは望むなら、忍者／魔法使い／ハンターとして怪異と戦うことができる。その場合、あなたは別のサイコロ・フィクションのキャラクターとして生まれ変わる。',
          '病院のベッドで目を覚ます。長い間、ひどい悪夢を見ていたような気がする。そのセッションの後遺症判定は、マイナス１の修正がつき、ファンブル値が１上昇する。',
          'どこかの民家で目を覚ます。素敵な人物に助けられ、手厚い介護を受けたようだ。特にペナルティはなし。',
          '「危ない！」大いなる絶望が、あなたに襲いかかってくる。1D6マイナス1点のダメージを受ける。これによって【生命力】が0点になった場合、あなたは死亡する。ただし、あなたにプラスの【感情】を持つNPCがいた場合、そのNPCが、そのダメージを無効化してくれる。',
          '別の新たな怪事件に巻き込まれる。苦労のすえ、そちらは何とか無事解決！　特にペナルティはなし。',
          '大きな傷を負い、生死の境をさまよう。好きな特技で判定を行うこと。失敗すると死亡する。このとき、減少している【生命力】の分だけマイナスの修正がつく。',
          '目が覚めると見慣れない場所にいた。ここはどこだ？　私は誰だ？　どうやら、恐怖のあまり、記憶を失ってしまったようだ。功績点があれば、それを1点失う。',
          lambda { return "目を覚ますと、そこはいつもの場所だった。しかし、どこか違和感を覚える。君たち以外、誰も事件のことを知らないようだ。死んだはずのあの人物も生きている。時間を旅したのか、ここは違う世界線か……？　#{get_random_skill_table_text_only}の特技が【恐怖心】になる。" },
          '振り返ると、そこには圧倒的な「それ」が待ち構えていた。無慈悲な一撃が、あなたを襲い、あなたは死亡する。',
        ]
        return get_table_by_2d6(table)
      end

      # 指定特技ランダム決定表
      def get_random_skill_table
        skillTableFull = [
          ['暴力', ['焼却', '拷問', '緊縛', '脅す', '破壊', '殴打', '切断', '刺す', '射撃', '戦争', '埋葬']],
          ['情動', ['恋', '悦び', '憂い', '恥じらい', '笑い', '我慢', '驚き', '怒り', '恨み', '哀しみ', '愛']],
          ['知覚', ['痛み', '官能', '手触り', 'におい', '味', '物音', '情景', '追跡', '芸術', '第六感', '物陰']],
          ['技術', ['分解', '電子機器', '整理', '薬品', '効率', 'メディア', 'カメラ', '乗物', '機械', '罠', '兵器']],
          ['知識', ['物理学', '数学', '化学', '生物学', '医学', '教養', '人類学', '歴史', '民俗学', '考古学', '天文学']],
          ['怪異', ['時間', '混沌', '深海', '死', '霊魂', '魔術', '暗黒', '終末', '夢', '地底', '宇宙']],
        ]

        skillTable, total_n = get_table_by_1d6(skillTableFull)
        tableName, skillTable = *skillTable
        skill, total_n2 = get_table_by_2d6(skillTable)
        return "「#{tableName}」≪#{skill}≫", "#{total_n},#{total_n2}"
      end

      # 特技だけ抜きたい時用 あまりきれいでない
      def get_random_skill_table_text_only
        text, = get_random_skill_table
        return text
      end

      # 暫定整理番号作成表
      def get_interim_reference_number
        table = [
          [11, '1'],
          [12, '2'],
          [13, '3'],
          [14, '4'],
          [15, '5'],
          [16, '6'],
          [22, 'G'],
          [23, 'I'],
          [24, 'J'],
          [25, 'K'],
          [26, 'O'],
          [33, 'P'],
          [34, 'Q'],
          [35, 'S'],
          [36, 'T'],
          [44, 'U'],
          [45, 'V'],
          [46, 'X'],
          [55, 'Y'],
          [56, 'Z'],
          [66, '-'],
        ]

        number = @randomizer.roll_once(6)
        total_n = number.to_s
        counts = 3
        if number <= 4
          counts = number + 5
        elsif number == 5
          counts = 4
        end

        output = ''
        counts.times do
          character, number = get_table_by_d66_swap(table)
          output += character
          total_n += ",#{number}"
        end
        return output, total_n
      end

      TABLES = {
        "ST" => DiceTable::Table.new(
          "シーン表",
          "2D6",
          [
            '血の匂いがあたりに充満している。事件か？　事故か？　もしや、それは今も続いているのだろうか？',
            'これは……夢か？　もう終わったはずの過去が、記憶の中から蘇ってくる。',
            '眼下に広がる町並みを見下ろしている。なぜこんな高所に……？',
            '世界の終わりのような暗黒。暗闇の中、何者かの気配が蠢く……。',
            '穏やかな時間が過ぎていく。まるであんなことがなかったかのようだ。',
            '湿った土の匂い。濃密な気配が漂う森の中。鳥や虫の声、風にそよぐ木々の音が聞こえる。',
            '人通りの少ない住宅街。見知らぬ人々の住まう家々の中からは、定かではない人声や物音が漏れてくる……。',
            'にわかに空を雲が覆う。強い雨が降り出す。人々は、軒を求めて、大慌てで駆け出していく。',
            '荒れ果てた廃墟、朽ちた生活の名残。かすかに聞こえるのは風か、波の音か、耳鳴りか。',
            '人ごみ。喧騒。けたたましい店内BGMに、調子っぱずれの笑い声。騒がしい繁華街の一角だが……？',
            '明るい光りに照らされて、ほっと一息。だが光が強いほどに、影もまた濃くなる……。',
          ]
        ),
        "HJST" => DiceTable::Table.new(
          "本当は怖い現代日本シーン表",
          "2D6",
          [
            '不意に辺りが暗くなる。停電か？　闇の中から、誰かがあなたを呼ぶ声が聞こえてくる。',
            'ぴちょん。ぴちょん。ぴちょん。どこからか、水滴が落ちるような音が聞こえてくる。',
            '窓ガラスの前を通り過ぎたとき、不気味な何かが映り込む。目の錯覚……？',
            'テレビからニュースの音が聞こえてくる。何やら近所で物騒な事件があったようだが……',
            '暗い道を一人歩いている。背後から、不気味な跫音が近づいてくるような気がするが……。',
            '誰だろう？　ずっと視線を感じる。振り向いて見ても、そこにあるのは、いつも通りの光景なのだが……',
            '突如、携帯電話の音が鳴り響く。マナーモードにしておいたはずなのに……。一体、誰からだろう？',
            '茜さす夕暮れ。太陽は沈みかけ、空は血のように赤い。不安な気持ちが広がっていく……。',
            '美味しそうな香りが漂ってきて、急に空腹を感じる。今日は何を食べようかなぁ？',
            '甲高い泣き声が、響き渡る。猫や子供がどこかで泣いているのか？　それとも……。',
            '寝苦しくて目を覚ます。何か悪夢を見ていたようだが……。あれ、意識はあるのに身体が動かない！',
          ]
        ),
        "MTST" => DiceTable::Table.new(
          "狂騒の二〇年代シーン表",
          "2D6",
          [
            '苔のこびりつく巨大な岩が並ぶ、川に浮かぶ島。何を祀っているのかも分からない祭壇があり、いわく言いがたい雰囲気を漂わせる。',
            'もぐり酒場。看板もない地下の店は、街の男や酌婦たちで騒がしい。',
            '遺跡の中。誰が建てたとも知れぬ、非ユークリッド幾何学的な建築は、中を歩く者の正気を、徐々に蝕んでいく。',
            '大学図書館。四十万冊を超える蔵書の中には、冒涜的な魔道書も含まれているという。',
            '強い風にのって、どこからか磯の香りが漂ってくる。海は遠いはずだが……。',
            '多くの人でごったがえす街角。ここならば、何者が混じっていても、気付かれることはない。',
            '深い闇の中。その向こうには、名状しがたきなにものかが潜んでいそうだ。',
            '歴史ある新聞社。休むことなく発行し続けた、百年分におよぶ新聞が保管されている。',
            '古い墓地。捻れた木々の間に、古びて墓碑銘も読めぬような墓石が並ぶ。いくつかの墓石はなぜか傾いている。',
            '河岸に建つ工場跡。ずいぶん前に空き家になったらしく、建物は崩れかけている。どうやら浮浪者の住処になっているらしい。',
            '静かな室内。なにか、不穏な気配を感じるが……あれはなんだ？　窓に、窓に！',
          ]
        ),
        "DVST" => DiceTable::Table.new(
          "暗黒のヴィクトリアシーン表",
          "2D6",
          [
            '霊媒師を中心に円卓を取り囲む人々が、降霊会を行っている。薄暗い部屋の中に怪しげなエクトプラズムが漂い始める。',
            '労働者達の集うパブ。女給が運ぶエールやジンを、赤ら顔の男たちが飲み干している。',
            '血の香りの漂う場所。ここで何があったのだろうか……。',
            '売春宿の建ち並ぶ貧民街。軒先では娼婦たちが、客を待ち構えている。',
            '人々でごったがえす、騒がしい通り。様々な噂話が飛び交っている。東洋人を初めとした、外国人の姿も目立つ。',
            '霧深い街角。ガス灯の明かりだけが、石畳を照らし出している。',
            '静まり返った部屋の中。ここならば、何をしても余計な詮索はされないだろう。',
            '汽笛の響く波止場。あの船は、外国へと旅立つのだろうか。',
            '書物の溢れる場所。調べ物をするにはもってこいだが。',
            '貴族や資産階級の人々が集うパーティ。上品な微笑みの下では、どんな企みが進んでいるのだろうか。',
            '静かな湖のほとり。草むらでは野生の兎が飛びはねている。',
          ]
        ),
        "DT" => DiceTable::D66Table.new(
          "形容表",
          D66SortType::ASC,
          {
            11 => "青ざめた",
            12 => "血をしたたらせた",
            13 => "うろこ状の",
            14 => "冒涜的な",
            15 => "円筒状の",
            16 => "無限に増殖する",
            22 => "不規則な",
            23 => "ガーガー鳴く",
            24 => "無数の",
            25 => "毛深い",
            26 => "色彩のない",
            33 => "伸縮する",
            34 => "みだらな",
            35 => "膨れ上がった",
            36 => "巨大な",
            44 => "粘液まみれの",
            45 => "絶えず変化する",
            46 => "蟲まみれの",
            55 => "キチン質の",
            56 => "「本体表を使用する」のような",
            66 => "虹色に輝く",
          }
        ),
        "BT" => DiceTable::D66Table.new(
          "本体表",
          D66SortType::ASC,
          {
            11 => "人間",
            12 => "犬",
            13 => "ネズミ",
            14 => "幽鬼",
            15 => "なめくじ",
            16 => "蟲",
            22 => "顔",
            23 => "猫",
            24 => "ミミズ",
            25 => "牛",
            26 => "鳥",
            33 => "半魚人",
            34 => "人造人間",
            35 => "蛇",
            36 => "老人",
            44 => "アメーバ",
            45 => "女性",
            46 => "機械",
            55 => "タコ",
            56 => "「部位表」を使用する",
            66 => "小人",
          }
        ),
        "PT" => DiceTable::D66Table.new(
          "部位表",
          D66SortType::ASC,
          {
            11 => "胴体",
            12 => "足",
            13 => "腕",
            14 => "髪の毛／たてがみ",
            15 => "口",
            16 => "乳房",
            22 => "顔",
            23 => "肌",
            24 => "瞳",
            25 => "尾",
            26 => "触手",
            33 => "鼻",
            34 => "影",
            35 => "牙",
            36 => "骨",
            44 => "宝石",
            45 => "翼",
            46 => "脳髄",
            55 => "舌",
            56 => "枝や葉",
            66 => "内臓",
          }
        ),
        "FT" => DiceTable::Table.new(
          "感情表",
          "1D6",
          [
            '共感（プラス）／不信（マイナス）',
            '友情（プラス）／怒り（マイナス）',
            '愛情（プラス）／妬み（マイナス）',
            '忠誠（プラス）／侮蔑（マイナス）',
            '憧憬（プラス）／劣等感（マイナス）',
            '狂信（プラス）／殺意（マイナス）',
          ]
        ),
        "JT" => DiceTable::D66Table.new(
          "職業表",
          D66SortType::ASC,
          {
            11 => "考古学者≪情景≫≪考古学≫",
            12 => "ギャング≪拷問≫≪怒り≫",
            13 => "探偵≪第六感≫≪数学≫",
            14 => "警察≪射撃≫≪追跡≫",
            15 => "好事家≪芸術≫≪人類学≫",
            16 => "医師≪切断≫≪医学≫",
            22 => "教授　知識分野から好きなものを二つ",
            23 => "聖職者≪恥じらい≫≪愛≫",
            24 => "心理学者　情動分野から好きなものを二つ",
            25 => "学生　知識分野と情動分野から好きなものを一つずつ",
            26 => "記者≪驚き≫≪メディア≫",
            33 => "技術者≪電子機器≫≪機械≫",
            34 => "泥棒≪物陰≫≪罠≫",
            35 => "芸能人≪悦び≫≪芸術≫",
            36 => "作家≪憂い≫≪教養≫",
            44 => "冒険家≪殴打≫≪乗物≫",
            45 => "司書≪整理≫≪メディア≫",
            46 => "料理人≪焼却≫≪味≫",
            55 => "ビジネスマン≪我慢≫≪効率≫",
            56 => "夜の蝶≪笑い≫≪官能≫",
            66 => "用心棒　好きな暴力×2",
          }
        ),
        "TVT" => DiceTable::Table.new(
          "指定特技（暴力）表",
          "2D6",
          ['焼却', '拷問', '緊縛', '脅す', '破壊', '殴打', '切断', '刺す', '射撃', '戦争', '埋葬']
        ),
        "TET" => DiceTable::Table.new(
          "指定特技（情動）表",
          "2D6",
          ['恋', '悦び', '憂い', '恥じらい', '笑い', '我慢', '驚き', '怒り', '恨み', '哀しみ', '愛']
        ),
        "TPT" => DiceTable::Table.new(
          "指定特技（知覚）表",
          "2D6",
          ['痛み', '官能', '手触り', 'におい', '味', '物音', '情景', '追跡', '芸術', '第六感', '物陰']
        ),
        "TST" => DiceTable::Table.new(
          "指定特技（技術）表",
          "2D6",
          ['分解', '電子機器', '整理', '薬品', '効率', 'メディア', 'カメラ', '乗物', '機械', '罠', '兵器']
        ),
        "TKT" => DiceTable::Table.new(
          "指定特技（知識）表",
          "2D6",
          ['物理学', '数学', '化学', '生物学', '医学', '教養', '人類学', '歴史', '民俗学', '考古学', '天文学']
        ),
        "TMT" => DiceTable::Table.new(
          "指定特技（怪異）表",
          "2D6",
          ['時間', '混沌', '深海', '死', '霊魂', '魔術', '暗黒', '終末', '夢', '地底', '宇宙']
        ),
        "CHT" => DiceTable::Table.new(
          "会話ホラースケープ表",
          "1D6",
          [
            "指定特技：死\n会話の最中、あなたはふと、相手の肩越しに目を向ける。なんの前触れもなく、遠くの建物の屋上から女が飛び降りた。声を上げる暇もなく、彼女は吸い込まれるように地面に叩きつけられる。距離があるにもかかわらず、女と目が合ってしまった。―それ以降、女の顔が脳裏にこびりついて、離れようとしない……。",
            "指定特技：殴打\n地面に横たわった相手を見ながら、あなたは冷や汗が背中に伝うのを感じていた。相手は倒れたまま、不自然に体をねじ曲げて、ぴくりとも動かない。じわじわと血溜まりが広がっていく……。――殺してしまった。動揺して瞬きしたとき、相手の身体は消えていた。血溜まりもなくなっている。あなたは茫然と立ちすくむ。幻覚だったのだろうか……？",
            "指定特技：電子機器\nあなたが電話で相手と話をしていると、不意に、相手が黙り込んだ。「……なんだあれ？」独り言のように言って、それから慌てたような声を出した。「こっち来る……こっち来る！うわっ！うわああああっ！助けて！助けて！！」それを最後に、電話はぶつりと切れる。かけ直すと話し中だ。ずっと。",
            "指定特技：物音\nあなたが電話で相手と話していると、ぶつぶつ言う声が聞こえてくる。混線だろうか？不思議に思って聞いているうちに、頭がぼんやりしてくる。ぶつぶつ、ぶつぶつ、ぶつぶつ、ぶつぶつ……。気が付くと、電話をもったままぼーっと立っていた。ただ、とても怖いことを言われたような気がしている。そもそも、あなたは誰と話をしていたんだろう？",
            "指定特技：拷問\n会話の最中、血の味を感じた。同時に、口の中にごろごろした違和感を覚える。相手が真っ青になってあなたの顔を指差す。どうしたのか訊ねようと口を開くと、ぽろりと何かが地面に落ちた。見下ろすと、血溜まりの中に白々と、あなたの歯が一本落ちていた。",
            "指定特技：人類学\n会話の最中、視界に違和感を覚えて、あなたは瞬きする。相手の顔が、変になっていた。引き延ばして、かき回したように、グロテスクに歪んでいる。えっ？と思ってよく見るが、歪みは変わらない。相手はまったく気付いていないようだ。きつく目を瞑ってから見直すと、ようやく歪みは消えた。君の心に一つの疑いが生まれる。目の前の相手は、本当に人間なのだろうか？",
          ]
        ),
        "VHT" => DiceTable::Table.new(
          "街中ホラースケープ表",
          "1D6",
          [
            "指定特技：乗物\nキキィーッ！激しいブレーキ音、そして鈍い音。はっとして振り返ると、止まった車と、その前に倒れている人が目に入った。交通事故だ！慌てて駆け寄り、被害者の顔を見た途端、あなたは凍り付いた。倒れているのは、あなただった。――えっ！？驚いて瞬きすると、路上のあなたも、車も消えていた。",
            "指定特技：情景\n通りすがりの家の屋根に誰かが立っている。あんなところで何を……？その誰かは踊りを踊っているように見えた。手足を振り回し、頭を激しく動かして、踊っている。尋常な様子ではない。狂ったように踊っている。見ているうちにものすごく不吉な気分になってきた。見たくないのに、どういうわけか、目を逸らすことができない。不吉な予感はどんどん強くなってくる……。",
            "指定特技：終末\nウゥゥゥゥゥゥゥゥ…………　街にサイレンが鳴り響く。どこで鳴っているのか、いつまで鳴っているのか。こんなに大きな音なのに、どうして誰も騒がないのだろう。不思議に思って歩いていると、道を向こうから歩いてくる人影がある。怪我をしているのか、よろめいて、今にも倒れそうになりながら、がくり、がくりと不自然な歩き方で近づいてくる。あれはいったい………？",
            "指定特技：脅す\n歩いていると、不意に静かになった。あたりを見渡すと、人も車も誰もいない。無人の街が、どこまでも広がっている。さっきまでたくさん人がいたのに……！？「おい！何やってるんだ！」突然怒鳴られてぎくりとする。振り返ると、作業着をきた男性がこっちへ走ってきていた。「馬鹿野郎！こんなところに来たら――」最後まで聞かないうちに、不意に音が戻ってきた。人と車が行き交う、元通りの街だ。今のは何だったんだ……？",
            "指定特技：混沌\n電柱の根元に、女性がうずくまっている。お腹を押さえて、苦しそうに顔を伏せている。「大丈夫ですか？」近づいて声をかけたあなたに、女性は頷いた。「はい――ありがとうございます。」そう言って顔を上げた女性の顔には、何もなかった。つるりとした剥き玉子のような皮膚が続いているだけだった。うわっ！？のけぞった途端、意識が遠ざかって、気がつくとあなたは電柱の根元にうずくまっていた。",
            "指定特技：笑い\n駅に着くと、やけに混雑している。人身事故で電車が止まっているようだ。ツイてないな。そう思っていると、改札付近の人ごみの中から、和服の女性が急ぎ足であなたのほうへ近づいてきた。女性は満面の笑みを浮かべていた。独りごとを言っているのか、口が動いている。すれ違いざまに、女性の声が耳に入った。「やってやった。やってやった。やってやった。ざまあみろ」えっ、と思って振り返るあなたを残して、女性は人ごみの中へ消えていった。",
          ]
        ),
        "IHT" => DiceTable::Table.new(
          "不意訪問ホラースケープ表",
          "1D6",
          [
            "指定特技：驚き\nバタバタバタッ！突然の物音に、あなたはぎょっとして振り仰ぐ。天井裏を何かが動き回っているようだ。動物が入り込んだのだろうか？それにしては大きい音だ。――まるで子供がめちゃめちゃに走り回っているような。物音は一瞬止まり、すぐに再開した。ドン！ドン！ドン！ドン！飛び跳ねるような音がするのは、ちょうどあなたの真上だ……。",
            "指定特技：宇宙\n窓から光が差し込む。窓に目を向けてみると、白く輝く巨大な飛行物体が浮かんでいた。魅せられたように見つめていると、鳥や飛行機とは思えないような、激しく不規則な動きで飛び回り始める。なんだろう、あれは？不思議に思っていると、背後から誰かが囁いた。「あれは………だよ」はっと気付くと、いつの間にか、まったく違う場所にいた。手のひらに何か埋まっているような硬い感触がある……。",
            "指定特技：におい\n奇妙な荷物が届いた。ガムテープでぐるぐる巻きにされた大きな段ボールだ。差出人名を書いた紙がはってあるが、滲んでしまって読めない。箱の中身は土だった。陶器のかけらや石ころが混ざった、変な臭いのする土が入っていた。わけがわからないので中身は捨てたが、それ以降なんだかツキが落ちている気がする……。",
            "指定特技：我慢\n壁の向こうから誰かが話している声が聞こえてくる。「……だから。こいつは……しないと」「そうね……わいそ……さなきゃ」ぼそぼそ、ぼそぼそと、陰気な調子で会話は続く。何を話しているのか、内容はよくわからないが、なんとなく自分のことを言われているようで薄気味が悪い。気になって壁に耳を当てたとき、はっきりした声が、壁の向こうからこう言った。「……ねえ、ちゃんと聞いてる？」",
            "指定特技：手触り\nぽたり。ぽたり。首筋に落ちた生暖かい水滴の感触に、あなたは眉を寄せた。気がつくと机の上に、赤い雫が落ちている。鉄臭いにおいが鼻を突く。ぽたり。ぽたり。ぽたり。雫は勢いを増し、次々と落ちてきて、机の上に広がってゆく。ゆっくりと見上げると、天井には大きく赤黒いしみが広がっていた。ぽたり。ぽたりぽたり。ぽたり。――ぼたぼたぼたっ！高まる水音にあなたは立ちすくむ。天井裏に、いったい何が……？",
            "指定特技：地底\n見慣れたはずの場所に、見慣れない扉を見つけた。開けてみると、長い下り階段が闇の中に伸びている。不審に思って下りてみると……そこは地下室だった。こんな場所があったなんて。明かりを片手に進んでいくと、何かが近づいてくる気配がする。闇の中から、何者かが、あなたの名を呼んだ。",
          ]
        ),
        "RHT" => DiceTable::Table.new(
          "廃墟遭遇ホラースケープ表",
          "1D6",
          [
            "指定特技：暗黒\n重く頑丈そうな扉を開ける。部屋の中は真っ暗だった。灯りで照らしてみると、別の部屋へと続く道が何本か見つかった。目ぼしいものはなさそうだ。一旦、入り口に戻ろうと、入ってきた扉のほうを振り返る。そこには壁しかなかった。あの重厚な扉がなくなっている。そんな馬鹿な。しかし、何度探してもどの壁にも扉らしきものは見当たらない。仕方なく、通路を進むことにしたが、じわじわと不吉な気分が込み上げてくる。……あの扉は、開けてはいけなかったのではないだろうか？",
            "指定特技：整理\nあなたは廃墟の中、ブーン……という低い音に気付いた。冷蔵庫だ。どこから電気が来ているのか、白い冷蔵庫が廃屋の片隅にひっそりと佇んでいる。ガチャリと扉を引き開けてみたあなたは、中にいた何かと、目が合った。……気がつくと、あなたは暗くて冷たいところで体を丸めている。ブーン…という音が聞こえている。ここは涼しくて、狭くて――とても居心地がいい。",
            "指定特技：追跡\n廃屋のふすまを開けたとき、あなたは強い違和感を覚える。分厚く埃が積もったその部屋には、濃厚な気配が漂っていた。ちゃぶ台の上には中身の残った湯飲み。さっきまで誰かが座っていたみたいに凹んだ座布団。なぜこの茶の間には、こんなに生活感があるのだろうか……。",
            "指定特技：愛\n廃墟を歩いていると、突然、あなたの携帯に電話がかかってきた。静まりかえった廃墟に鳴り響く着信音に肝を潰しつつも出てみると、電話の向こうから、あなたの祖母がいきなり叱りつけてきた。「あんた、何やってんの！そんなとこ行ったらダメでないの！」え？なぜ祖母が……？「早くそこから出なさい！大変なことになるよ！」わけがわからずに口ごもっているうちに、電話は切れた。ディスプレイには、「圏外」と表示されていた。",
            "指定特技：罠\n廃墟を歩いていると、いきなり足に激痛が走った。悲鳴をこらえて下を見ると、あなたの足首をがっちりとトラバサミが捕えている。なぜこんな場所に、こんな罠が……？苦労してトラバサミを解除して、改めて周りを見たとき、あなたは愕然とする。罠は一つだけではなかった。瓦礫の下に隠すようにして、いくつもいくつも、トラバサミが仕掛けられていた。",
            "指定特技：薬品\n不意に、シンナーの匂いが鼻を刺した。廃墟の壁にべったりと、赤いペンキの文字が書かれている。何が書いてあるのかは判然としないが、ひたすら悪意と憎しみを塗り込めたようなタッチにおぞけが走る。そのうちあることに気付いて、あなたは総毛立った。ペンキがまだ新しい。……塗り立てのように新しいのだ。",
          ]
        ),
        "MHT" => DiceTable::Table.new(
          "野外遭遇ホラースケープ表",
          "1D6",
          [
            "指定特技：痛み\nブ―――――――ン耳元で甲高い羽音が響いてくる。見たことのない真っ赤な羽虫の群れが飛んでいた。ブ―――――――ン。羽虫を追い払うように、腕を振るう。痛いっ。腕に刺すような痛みが走った。ブ―――――――ン虫たちは、どこかへ去っていく。みるみる腕の表面に不気味な水疱がぽつぽつと浮かび上がってきた。",
            "指定特技：夢\n木々の間で、何か大きなものが動いているのが見える。肉の腐ったような臭いがぷんと鼻を突く。まだら模様のあれは……毛皮？それとも、ずたずたになった服の切れ端？そいつがあなたを見た。木の葉の合間から除く目は、まるで人のような――目が合った瞬間から記憶がない。気が付くと、人の髪に似た黒い毛が、あなたの全身に付着していた。",
            "指定特技：恨み\n林の中で出くわした大樹の幹には、たくさんの藁人形が釘で打ち付けられていた。うわあ、と思いながら見上げるうちに、気のめいる事実に気付いてしまった。新しめの藁人形の一つに、名前の書かれた札が貼り付けられている。――ひどく、見覚えのある名前だった。",
            "指定特技：深海\n……おーい。……お―――い。遠く、呼ぶ声を聴いた気がして、波の合間に目を凝らす。つるりとした黒い影が、浮きつ沈みつ、あなたを差し招いている。ひい、ふう、みい、よう……七人。七人の黒い影が、波間から、あなたに手を振っている。――なんだか、頭がぼうっとしてきた。",
            "指定特技：物陰\n藪の中に廃車が埋もれている。特徴のない白いバンだ。窓は真っ黒な煤で汚れていて、何も見えない。車体は錆び付いて、塗料も剥がれ、打ち棄てられて久しい廃車であることは確実だ。――それなのに、廃車の中から刺すような視線を感じる。ロックが外れる音がして、ゆっくりと後部座席のドアが開き始める……。",
            "指定特技：焼却\nパチ……パチ……。火の燃える音がする。空き地で焚火が炎を上げていた。そばには誰もいない。心温まる思いで立ち止まり、木の枝で焚火をかき回していると、炎の中から軽やかな笑い声が聞こえた。ぎょっとするあなたの足許を、猫のような大きさの何かがするりと抜けていった。焚火に目を戻すと、そこにはただ、くすぶる骨の塊が残されているだけだった。",
          ]
        ),
        "LHT" => DiceTable::Table.new(
          "情報潜在ホラースケープ表",
          "1D6",
          [
            "指定特技：味\nのどの渇きを覚えた。調べ物を開始した時間から、時計の針は大分進んでいる。どうやら根をつめ過ぎたようだ。画面に目を戻しつつ、ペットボットルの水を口に含む。すると、口内に違和感が広がった。たまらず水を吐き出す。すると、真っ黒い液体が机の上の資料を汚した。口の中には、ドブ川のような臭いがこびりついている。確認したペットボトルの水は、透明なのだが……？",
            "指定特技：カメラ\n資料の間から、黄ばんだ封筒に入った写真の束が出てきた。被写体は……あなただ。知らないうちに撮られた、あなたの写真が、何十枚も束ねられている。色褪せた写真を無造作に止めた輪ゴムは劣化して、ねばついていた。――だれが、こんな写真を？何の目的で……？",
            "指定特技：メディア\nテレビのニュースを見ていると、それまで淀みなく喋っていたアナウンサーが、不意に黙り込んだ。どうしたんだろう、と思っていると、アナウンサーが奇妙なことを言い始めた。「死ぬこともあり得ます。と語りました。また、高確率で、災いが起こります。今日から明日にかけて、厳重に警戒してください。警戒してください。警戒してください」アナウンサーは、画面の向こうからあなたの目をじっと見つめている。あなたが戸惑っていると、ひとりでにテレビの電源が切れた。",
            "指定特技：民俗学\n資料を漁るうちに、ある寒村に伝わるおぞましい風習に辿り着いた。暴力……儀式……生贄……。とてもまともな人間のやることとは思えない所業に震えあがる。その風習には、なぜか既視感があった。どこで読んだんだろう？考えるうちに、ある記憶が蘇った。あなたの幼い頃の記憶だった。いや……そんな、馬鹿な。あなたの故郷が、こんな寒村のはずがない……。",
            "指定特技：魔術\n資料の中から、奇妙な古書が出てきた。皮装丁の豪華な本で、妙な臭いがする。文書は支離滅裂で、正気の人間が書いたとは思えない。だが、破れそうなページを一枚一枚めくっていくと、しだいに作者の言っていることがわかってくる。どんどん、どんどん、わかってくる。ああ、もう、わかる。完全にわかる。もう大丈夫だ。きっとこの本は、あなたに読まれるために書かれたのだ。",
            "指定特技：歴史\n表紙のないレポートが見つかった。パラパラめくってみると、まさにあなたが今調べている件についての調査報告だった。もどかしいことに、あちこち墨塗りされていて、肝心のところがわからない。察するに、どうも、軍による調査のようだ。軍？なぜ軍隊がこの件を調べていたのだろう……？",
          ]
        ),
        "ECT" => DiceTable::Table.new(
          "遭遇表・都市",
          "1D6",
          [
            "できそこない×3　基本ｐ246",
            "にらむ人×1　デッドループｐ190　犬×1　基本ｐ243",
            "信奉者×2　基本ｐ243",
            "顔を隠した女×1　デッドループｐ192",
            "幽霊自動車×1　デッドループｐ193",
            "怨霊×1　基本ｐ245",
          ]
        ),
        "EMT" => DiceTable::Table.new(
          "遭遇表・山林",
          "1D6",
          [
            "のっぺらぼう×3　デッドループｐ190",
            "毒蟲の群れ×2　デッドループｐ191",
            "熊×1　デッドループｐ191",
            "巨大昆虫×1　デッドループｐ192",
            "人狼×1　基本ｐ265",
            "くねくね×1　デッドループｐ193",
          ]
        ),
        "EAT" => DiceTable::Table.new(
          "遭遇表・海辺",
          "1D6",
          [
            "人魂×3　デッドループｐ190",
            "深きもの×2　基本ｐ261",
            "星を渡るもの×1　基本ｐ261",
            "宇宙人×1　基本ｐ257",
            "魔女×1　基本ｐ245",
            "這いずるもの×1　基本ｐ261",
          ]
        ),
        "OHT" => DiceTable::Table.new(
          "残業ホラースケープ表",
          "1D6",
          [
            "指定特技：死\n窓に目をやったとき、窓の外を落下する人影と目が合った！慌てて窓辺に駆け寄るが、下には何もない。幻覚だったのだろうか……？",
            "指定特技：機械\n突然、コピー機が唸りを上げて紙を吐き出し始めた。床に舞い散ったコピー用紙には、歪んだ人の顔のようなものが印刷されている。気味が悪い……。",
            "指定特技：物陰\n蒼白い子供が机の下からあなたを見上げている。うわっ！と叫んで飛び退くと、子供の姿は消えた。",
            "指定特技：手触り\n仕事をしていると、背後から長い黒髪が垂れ下がってきた。女の長い黒髪だ。……後ろで覗き込んでいるのは、一体誰だ？",
            "指定特技：憂い\n視界の隅を、暗い顔の男が通り過ぎるのが見えた。振り返ってみても、誰もいない。誰だ？知らないぞ、あんな奴。",
            "指定特技：暗黒\nバツン！突然の停電でフロアが闇に沈んだ。驚いて顔を上げると、闇の中にたくさんの人影が佇んで、じっとあなたを見ている……！",
          ]
        ),
        "OPT" => DiceTable::Table.new(
          "残業電話表",
          "1D6",
          [
            "「進捗どうですか？」クライアントからの進捗確認の電話。今やってるよ！電話の時間がもったいないんだよ！ストレスで胃が痛い。【生命力】マイナス1。",
            "「仕様が変わりまして……」クライアントから仕様変更の連絡。今かよ！？殺すぞ！？せっかくの作業が無駄になる。PPマイナス1。",
            "「最近電話に出ないけど……大丈夫？」恋人や家族など、大切な人からの電話。仕事中にかけてくるなよと思いつつも、少し気が紛れた。【正気度】1回復。",
            "「特上寿司五人前お願いします！」間違い電話だった。驚かせやがって……。",
            "「ちょっと、この前の仕事だけどどうなってるんだ！」別件のクレームの電話だ！疲れた精神にダメージを負って、【正気度】マイナス1。",
            "「……ねばいいのに。」電話の向こうから地獄のような声が囁く。ぞっとして反射的に電話を切る。着信履歴は残っていない……なんだ今の！？《電子機器》で恐怖判定。",
          ]
        ),
        "OWT" => DiceTable::Table.new(
          "残業シーン表",
          "2D6",
          [
            "ジジッ……不意に蛍光灯がちらつく。電気系統がおかしいのだろうか？停電は勘弁してほしいのだが…。",
            "ぴちょん。ぴちょん。どこからか水の滴る音が聞こえる。雨漏りか、蛇口の閉め忘れか？",
            "ジャバーッ……ズゴゴゴゴ。トイレの水を流す音が響き渡る。誰かトイレにいたのか？それとも、他の階だろうか？",
            "サイレンの音が近づいてきて、赤色灯の光が窓から射し込む。近くで何かがあったようだが……。",
            "背後から誰かの話し声が聞こえた気がする。咄嗟に振り返るが……空耳だろうか？",
            "窓ガラスの向こうに見える夜の灯りを切ない気持ちで見つめる。早く帰りたい……。",
            "突如、携帯電話の音が鳴り響く。マナーモードにしていたはずなのに……。一体、誰からだろう？",
            "不意の機械音に驚いてみると、ファックスが紙を吐き出している。こんな時間になんだろう？",
            "美味しそうな香りが漂ってきて、急に空腹を感じる。どこから来たんだ、この匂いは？",
            "気分転換に見ていたネットに夢中になって、ふと気付くと何分も経過……いかんいかん。",
            "ガクンと船を漕いで、ハッと目を覚ました。慌てて時計を見る……えっ、もうこんな時間なの！？",
          ]
        ),
        "CNT1" => DiceTable::Table.new(
          "社名決定表1",
          "1D6",
          [
            "フライング",
            "トラブル",
            "ブラッド",
            "プリティー",
            "クリムゾン",
            "ボンバー",
          ]
        ),
        "CNT2" => DiceTable::Table.new(
          "社名決定表2",
          "1D6",
          [
            "ウィッチ―ズ",
            "インテリジェンス",
            "キャッツ",
            "バード",
            "ホラー",
            "インセイン",
          ]
        ),
        "CNT3" => DiceTable::Table.new(
          "社名決定表3",
          "1D6",
          [
            "(株)",
            "(株)",
            "(株)",
            "(有)",
            "(有)",
            "(有)",
          ]
        ),
        "RET" => DiceTable::Table.new(
          "反応表",
          "2D6",
          [
            "「ちょっとこちらにきてもらえますか。」いきなり逮捕、拘束される。「反応表」を使用したキャラクターは、このシーンが終わってから2シーンの間、自分がシーンプレイヤーでないシーンに登場することができなくなる（マスターシーンには登場可能）。",
            "「私が協力できるのはここまでだ。」協力を求めた人物は、怯えたような様子で手に持った包みをあなたに押し付けた。「反応表」を使用したキャラクターは、何か好きなアイテム一つを獲得する。",
            "「その件は捜査中です。情報提供ありがとうございます。」協力を求めた人物は、にこにこ笑って、そう答える。何を言っても、同じ返答しか返ってこない。「反応表」を使用したキャラクターは、【正気度】を1点減少する。",
            "「もしかして、お前、あの事件の関係者か……？」どうやら協力を求めた人物も、ちょうど同じ事件を調査していたようだ。いろいろ情報を提供してくれるようだ。「反応表」を使用したキャラクターは、以降、調査判定を行うときプラス1の修正がつく。",
            "「夢でも見たんじゃないですか？」どんなに強く訴えても信じてもらえない。……もしかして、おかしいのは私の方なのか？情動の特技分野からランダムに特技一つを選んで恐怖判定を行う。",
            "「はいはい。我々もヒマじゃないんだよ。」色々話しても相手にしてもらえない。門前払いを喰らう。",
            "「ちょっと身体検査よろしいでしょうか？」怪しい人物だと思われたらしい。「反応表」を使用したキャラクターが、アイテムや、違法そうなプライズを持っていた場合、このシーンが終わってから2シーンの間、自分がシーンプレイヤーでないシーンに登場することができなくなる（マスターシーンには登場可能）。",
            "「それは気になりますね。こちらでも調査してみましょう。」親身になって相談に乗ってくれる。何か分かったら連絡してくれると言うが……。1D6を振る。奇数なら、2シーン後に情報をくれる。「反応表」を使用したキャラクターは、好きな【秘密】一つを獲得する。偶数なら調査していたNPCが謎の死を遂げる。「反応表」を使用したキャラクターは、知識の特技分野からランダムに特技一つを選んで恐怖判定を行う。",
            "「命が惜しければこれ以上関わるな。」あなたは人気のない場所に連れていかれ、殴られた。協力を求めた人物は、助けを求めたはずのあなたを激しく拒絶する。「反応表」を使用したキャラクターは、【生命力】を1点減少する。",
            "「分かりました。念のためパトロールを強化しましょう。」周辺の警護を約束してくれる。「反応表」を使用したキャラクターは、このセッションの間、一度だけ自分が受けたダメージを無効化することができる。ダメージを無効化した場合、「反応表」を使用したキャラクターは、暴力の特技分野からランダムに一つを選んで恐怖判定を行う。",
            "「……なんじゃこりゃぁっ！？」助けを求めた相手が突然死亡する。ヤツらの手は、こんなところまで及んでいるのか？「反応表」を使用したキャラクターは、暴力の特技分野からランダムに一つを選んで恐怖判定を行う。",
          ]
        ),
      }.freeze

      register_prefix(TABLES.keys)
    end
  end
end
