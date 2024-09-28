# frozen_string_literal: true

module BCDice
  module GameSystem
    class ArknightsFan < Base
      # ゲームシステムの識別子
      ID = "ArknightsFan"

      # ゲームシステム名
      NAME = "アークナイツTRPG by Dapto"

      # ゲームシステム名の読みがな
      SORT_KEY = "ああくないつTRPGはいたふと"

      HELP_MESSAGE = <<~TEXT
        ■ 能力値判定 (nADm<=x)
          nDmのダイスロールをして、出目が x 以下であれば成功。
          出目が91以上でエラー。
          出目が10以下でクリティカル。

        ■ 攻撃/防御判定 (nABm<=x)
          nBmのダイスロールをして、
            出目が x 以下であれば成功数+1。
            出目が91以上でエラー。成功数-1。
            出目が10以下でクリティカル。成功数+1。
          上記による成功数をカウント。

        ■ 役職効果付き攻撃判定 (nABm<=x--役職名)
          nBmのダイスロールをして、
            出目が x 以下であれば成功数+1。
            出目が91以上でエラー。成功数-1。
            出目が10以下でクリティカル。成功数+1。
          上記による成功数をカウントした上で、以下の役職名による成功数増加効果を適応。
            狙撃（SNIPER）: 成功数1以上のとき、成功数+1。

        ■ 鉱石病判定 (ORP(p,q,n)+mD)
          生理的耐性pのOPが侵食度qに上昇した際の鉱石病判定、判定値補正n、ダイス数補正mで行う。
          判定値補正とダイス数補正は省略可能。例えば、ORP(60,25)はORP(60,25,0)+0Dと同義。

        ■ 増悪判定（--WORSENING）
          症状を「末梢神経障害」「内臓機能不全」「精神症状」からランダムに選択。
          継続ラウンド数を1d6+1で判定。

        ■ 中毒判定（--ADDICTION）
          症状を「中枢神経障害」「多臓器不全」「急性ストレス反応」からランダムに選択。

        ■ 判定の省略表記
          nADm、nABm、nABmにおいて、
            n（ダイス個数）を省略した場合、1として扱われる。
            m（ダイス種類）を省略した場合、100として扱われる。
          例えば、AD<=90は1AD100<=90として解釈される。
      TEXT

      register_prefix('[-+*/\d]*AD\d*', '[-+*/\d]*AB\d*', 'ORP', '--ADDICTION', '--WORSENING')

      def initialize(command)
        super(command)
        @sort_add_dice = true # 加算ダイスでダイス目をソートする
        @sort_barabara_dice = true # バラバラダイスでダイス目をソートする
        @sides_implicit_d = nil # 1D のようにダイスの面数が指定されていない場合にダイス表記に置換しない
      end

      def eval_game_system_specific_command(command)
        roll_ad(command) || roll_ab(command) || roll_orp(command) || roll_addiction(command) || roll_worsening(command)
      end

      private

      module Status
        CRITICAL = 1
        SUCCESS  = 2
        FAILURE  = 3
        ERROR    = 4
      end

      STATUS_NAME = {
        Status::CRITICAL => 'クリティカル！',
        Status::SUCCESS => '成功',
        Status::FAILURE => '失敗',
        Status::ERROR => 'エラー'
      }.freeze

      # クリティカル、エラー、成功失敗周りの閾値や優先関係が複雑かつルールが変動する可能性があるため、明示的にルール管理するための関数。
      def check_roll(roll_result, target)
        success = roll_result <= target

        crierror =
          if roll_result <= 10
            "Critical"
          elsif roll_result >= 91
            "Error"
          else
            "Neutral"
          end

        result =
          if success && (crierror == "Critical")
            Status::CRITICAL
          elsif success && (crierror == "Neutral")
            Status::SUCCESS
          elsif success && (crierror == "Error")
            Status::SUCCESS
          elsif !success && (crierror == "Critical")
            Status::FAILURE
          elsif !success && (crierror == "Neutral")
            Status::FAILURE
          elsif !success && (crierror == "Error")
            Status::ERROR
          end

        return result
      end

      def roll_ad(command)
        # -は文字クラスの先頭または最後に置く。
        # そうしないと範囲指定子として解釈される。
        m = %r{^([-+*/\d]*)AD(\d*)<=([-+*/\d]+)$}.match(command)
        return nil unless m

        times = m[1]
        sides = m[2]
        target = Arithmetic.eval(m[3], @round_type)
        times = !times.empty? ? Arithmetic.eval(m[1], @round_type) : 1
        sides = !sides.empty? ? sides.to_i : 100

        roll_d(command, times, sides, target)
      end

      def roll_ab(command)
        m = %r{^([-+*/\d]*)AB(\d*)<=([-+*/\d]+)(?:--([^\d\s]+)(0|1)?)?$}.match(command)
        return nil unless m

        times = m[1]
        sides = m[2]
        target = Arithmetic.eval(m[3], @round_type)
        type = m[4]
        type_enable = m[5]
        times = !times.empty? ? Arithmetic.eval(m[1], @round_type) : 1
        sides = !sides.empty? ? sides.to_i : 100
        type_enable = !type_enable.nil? ? type_enable.to_i : 1

        if type.nil? || (type_enable == 0)
          roll_b(command, times, sides, target)
        else
          roll_b_withtype(command, times, sides, target, type)
        end
      end

      def roll_orp(command)
        m = %r{^ORP\(([-+*/\d]+),([-+*/\d]+)(?:,([-+*/\d]+))?\)(?:\+([-+*/\d]+)D)?$}.match(command)
        return nil unless m

        endurance = Arithmetic.eval(m[1], @round_type)
        oripathy = Arithmetic.eval(m[2], @round_type)
        target_mod = !m[3].nil? ? Arithmetic.eval(m[3], @round_type) : 0
        times_mod = !m[4].nil? ? Arithmetic.eval(m[4], @round_type) : 0

        roll_oripathy(command, endurance, oripathy, target_mod, times_mod)
      end

      def roll_d(command, times, sides, target)
        dice_list = @randomizer.roll_barabara(times, sides).sort
        total = dice_list.sum

        result = check_roll(total, target)

        if times == 1
          result_text = "(#{command}) ＞ #{dice_list.join(',')} ＞ #{STATUS_NAME[result]}"
        else
          result_text = "(#{command}) ＞ #{total}[#{dice_list.join(',')}] ＞ #{STATUS_NAME[result]}"
        end
        case result
        when Status::CRITICAL
          Result.critical(result_text)
        when Status::SUCCESS
          Result.success(result_text)
        when Status::FAILURE
          Result.failure(result_text)
        when Status::ERROR
          Result.fumble(result_text)
        end
      end

      def roll_b(command, times, sides, target)
        dice_list, success_count, critical_count, error_count = process_b(times, sides, target)
        result_count = success_count + critical_count - error_count

        result_text = "(#{command}) ＞ [#{dice_list.join(',')}] ＞ #{success_count}+#{critical_count}C-#{error_count}E ＞ 成功数#{result_count}"
        Result.new.tap do |r|
          r.text = result_text
          r.condition = result_count > 0
          r.critical = critical_count > 0
          r.fumble = error_count > 0
        end
      end

      def roll_b_withtype(command, times, sides, target, type)
        dice_list, success_count, critical_count, error_count = process_b(times, sides, target)
        result_count = success_count + critical_count - error_count

        type_effect =
          if (type == "SNIPER") && (result_count > 0)
            1
          else
            0
          end
        result_count += type_effect

        result_text = "(#{command}) ＞ [#{dice_list.join(',')}] ＞ #{success_count}+#{critical_count}C-#{error_count}E+#{type_effect}(#{type}) ＞ 成功数#{result_count}"
        Result.new.tap do |r|
          r.text = result_text
          r.condition = result_count > 0
          r.critical = critical_count > 0
          r.fumble = error_count > 0
        end
      end

      ENDURANCE_LEVEL_TABLE = [20, 40, 70, 90, Float::INFINITY].freeze # 生理的耐性の実数値から能力評価への変換テーブル
      ORP_TIMES_TABLE = [1, 2, 2, 3, 4].freeze                         # 生理的耐性の能力評価ごとのダイス数基本値
      def roll_oripathy(command, endurance, oripathy, target_mod, times_mod)
        sides = 100

        endurance_level = ENDURANCE_LEVEL_TABLE.find_index { |n| endurance <= n }
        times = ORP_TIMES_TABLE[endurance_level] + times_mod

        oripathy_stage = (oripathy / 20).floor
        target = (80 - oripathy_stage * 20) - (oripathy - oripathy_stage * 20) * 5 + target_mod

        if target <= 0
          return Result.failure("(#{command}) ＞ ダイス数#{times}, 判定値#{target} ＞ 自動失敗！")
        end

        # 複数振ったダイスのうち1つでも判定値を下回れば成功なので、最も出目の小さいダイスのみを確認すればよい。
        # dice_listをソートした上で、dice_list[0]が最小の出目。
        dice_list = @randomizer.roll_barabara(times, sides).sort
        if dice_list[0] <= target
          Result.success("(#{command}) ＞ ダイス数#{times}, 判定値#{target} ＞ [#{dice_list.join(',')}] ＞ 成功")
        else
          Result.failure("(#{command}) ＞ ダイス数#{times}, 判定値#{target} ＞ [#{dice_list.join(',')}] ＞ 失敗")
        end
      end

      def process_b(times, sides, target)
        dice_list = @randomizer.roll_barabara(times, sides).sort

        success_count = 0
        critical_count = 0
        error_count = 0

        dice_list.each do |value|
          case check_roll(value, target)
          when Status::CRITICAL
            critical_count += 1
            success_count += 1
          when Status::SUCCESS
            success_count += 1
          when Status::FAILURE
            # Nothing to do
          when Status::ERROR
            error_count += 1
          end
        end

        return [dice_list, success_count, critical_count, error_count]
      end

      ADDICTION_TABLE = [
        "中枢神経障害",
        "多臓器不全",
        "急性ストレス反応",
      ].freeze

      def roll_addiction(command)
        return nil if command != "--ADDICTION"

        value = @randomizer.roll_once(3)
        chosen = ADDICTION_TABLE[value - 1]

        return "--ADDICTION ＞ #{chosen}"
      end

      WORSENING_TABLE = [
        "末梢神経障害",
        "内臓機能不全",
        "精神症状",
      ].freeze

      def roll_worsening(command)
        return nil if command != "--WORSENING"

        value = @randomizer.roll_once(3)
        chosen = WORSENING_TABLE[value - 1]
        elapse = @randomizer.roll_once(6) + 1

        return "--WORSENING ＞ #{chosen}: #{elapse} rounds"
      end
    end
  end
end
