# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
areas = [
  { name: '北海道', region: '北海道・東北' },
  { name: '青森県', region: '北海道・東北' },
  { name: '岩手県', region: '北海道・東北' },
  { name: '宮城県', region: '北海道・東北' },
  { name: '秋田県', region: '北海道・東北' },
  { name: '山形県', region: '北海道・東北' },
  { name: '福島県', region: '北海道・東北' },
  { name: '茨城県', region: '関東' },
  { name: '栃木県', region: '関東' },
  { name: '群馬県', region: '関東' },
  { name: '埼玉県', region: '関東' },
  { name: '千葉県', region: '関東' },
  { name: '東京都', region: '関東' },
  { name: '神奈川県', region: '関東' },
  { name: '新潟県', region: '中部' },
  { name: '富山県', region: '中部' },
  { name: '石川県', region: '中部' },
  { name: '福井県', region: '中部' },
  { name: '山梨県', region: '中部' },
  { name: '長野県', region: '中部' },
  { name: '岐阜県', region: '中部' },
  { name: '静岡県', region: '中部' },
  { name: '愛知県', region: '中部' },
  { name: '三重県', region: '近畿' },
  { name: '滋賀県', region: '近畿' },
  { name: '京都府', region: '近畿' },
  { name: '大阪府', region: '近畿' },
  { name: '兵庫県', region: '近畿' },
  { name: '奈良県', region: '近畿' },
  { name: '和歌山県', region: '近畿' },
  { name: '鳥取県', region: '中国・四国' },
  { name: '島根県', region: '中国・四国' },
  { name: '岡山県', region: '中国・四国' },
  { name: '広島県', region: '中国・四国' },
  { name: '山口県', region: '中国・四国' },
  { name: '徳島県', region: '中国・四国' },
  { name: '香川県', region: '中国・四国' },
  { name: '愛媛県', region: '中国・四国' },
  { name: '高知県', region: '中国・四国' },
  { name: '福岡県', region: '九州' },
  { name: '佐賀県', region: '九州' },
  { name: '長崎県', region: '九州' },
  { name: '熊本県', region: '九州' },
  { name: '大分県', region: '九州' },
  { name: '宮崎県', region: '九州' },
  { name: '鹿児島県', region: '九州' },
  { name: '沖縄県', region: '九州' }
]

areas.each do |area|
  Area.find_or_create_by(name: area[:name], region: area[:region])
end

instruments = [
  { name: 'ボーカル' },
  { name: 'ギター' },
  { name: 'ベース' },
  { name: 'ドラム' },
  { name: 'キーボード' },
  { name: 'リスナー' }
]

instruments.each do |instrument|
  Instrument.find_or_create_by(name: instrument[:name])
end

quiz1 = Quiz.find_or_create_by(
  question: 'この和音（コード）の構成音に含まれないものを一つ選びなさい。',
  image_path: '/assets/quiz_music_theory_1.png',
  quiz_type: 'music_theory',
  quiz_rank: 1
)

Choice.find_or_create_by(quiz: quiz1, content: 'ド', correct: false)
Choice.find_or_create_by(quiz: quiz1, content: 'ミ', correct: false)
Choice.find_or_create_by(quiz: quiz1, content: 'ファ', correct: true)
Choice.find_or_create_by(quiz: quiz1, content: 'ラ', correct: false)
