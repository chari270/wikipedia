require 'csv'
require 'cgi'

INDUSTRY_CODE = {
  "0050" => "水産・農林業",
  "1050" => "鉱業",
  "2050" => "建設業",
  "3050" => "食料品",
  "3100" => "繊維製品",
  "3150" => "パルプ・紙",
  "3200" => "化学",
  "3250" => "医薬品",
  "3300" => "石油・石炭製品",
  "3350" => "ゴム製品",
  "3400" => "ガラス・土石製品",
  "3450" => "鉄鋼",
  "3500" => "非鉄金属",
  "3550" => "金属製品",
  "3600" => "機械",
  "3650" => "電気機器",
  "3700" => "輸送用機器",
  "3750" => "精密機器",
  "3800" => "その他製品",
  "4050" => "電気・ガス業",
  "5050" => "陸運業",
  "5100" => "海運業",
  "5150" => "空運業",
  "5200" => "倉庫・運輸関連業",
  "5250" => "情報・通信業",
  "6050" => "卸売業",
  "6100" => "小売業",
  "7050" => "銀行業",
  "7100" => "証券、商品先物取引業",
  "7150" => "保険業",
  "7200" => "その他金融業",
  "8050" => "不動産業",
  "9050" => "サービス業"
}

def shape file_name
  outcsv = CSV.open(output_file_name(file_name),'w')
  nonamecsv = CSV.open(output_file_name_for_noname(file_name),'w')
  overseacsv = CSV.open(output_file_name_for_oversea(file_name),'w')

  order = 0
  before_title = ''

  CSV.foreach(file_name,headers:true).with_index do |row,i|
    if i == 0
      outcsv.puts(row.headers+['掲載順'])
      nonamecsv.puts(row.headers+['掲載順'])
      overseacsv.puts(row.headers+['掲載順'])
    end
    
    # row.each{|r|r = CGI.unescapeHTML(r)}

    # row["本社所在地"] = shape_address(row["本社所在地"].to_s)

    # row["社名"]&.gsub!(/<.*?>/,'')

    url = row["外部リンク"]
    url = url&.split(/URL\||url\|/).last&.gsub(/\[|\]|\{|\}/,'')&.gsub(/<.*?>/,' ')&.split(' ')&.first&.strip
    url = url&.gsub(/　|official\||Official\||<nowiki>|<\/nowiki>|=/,"")
    row["外部リンク"] = url


    row["ページタイトル"] = shape_text(row["ページタイトル"])
    row["社名"] = shape_name(row["社名"])
    row["法人番号"] = shape_text(row["法人番号"])
    row["外部リンク"] = shape_url(row["外部リンク"])
    row["種類"] = shape_text(row["種類"])
    row["略称"] = shape_text(row["略称"])
    row["本社郵便番号"] = shape_zipcode(row["本社郵便番号"])
    row["本社所在地"] = shape_address(row["本社所在地"])
    row["本店郵便番号"] = shape_zipcode(row["本店郵便番号"])
    row["本店所在地"] = shape_address(row["本店所在地"])
    row["業種"] = shape_industry(row["業種"])
    row["事業内容"] = shape_text(row["事業内容"])
    row["代表者"] = shape_text(row["代表者"])
    row["資本金"] = shape_text(row["資本金"])
    row["売上高"] = shape_text(row["売上高"])
    row["従業員数"] = shape_text(row["従業員数"])
    row["支店舗数"] = shape_text(row["支店舗数"])
    row["主要株主"] = shape_text(row["主要株主"])
    row["主要子会社"] = shape_text(row["主要子会社"])

    if before_title != row["ページタイトル"]
      before_title = row["ページタイトル"]
      order = 0
    end
    order += 1

    row["掲載順"] = order

    if row["本社所在地"]&.match(/\A(\p{katakana}|[a-zA-Z]|[0-9]+ [a-zA-Z]|[0-9]+,|〒[0-9]+-[0-9]+ \p{katakana}|[東|西|南|北]\p{katakana}+)/) || row["本社所在地"]&.match(/北京|平壌|香港|新竹市|済州|台南市|台北市/) || row["外部リンク"]&.match(/(\.kr|\.kr\/|\.tw|\.tw\/)\z/)
      overseacsv.puts(row)
    elsif row["社名"] == '' || row["社名"] == nil
      nonamecsv.puts(row)
    else
      outcsv.puts(row)
    end
  end
  outcsv.close
  overseacsv.close
  nonamecsv.close
end

def shape_address text
  text = shape_text(text)&.gsub(/http.*/,'')

  return text
end

def shape_url text
  text = shape_text(text)&.split(/URL\||url\|/)&.last&.gsub(/\[|\]|\{|\}/,'')&.gsub(/<.*?>/,' ')&.split(' ')&.first&.strip
  text = text&.gsub(/　|official\||Official\||<nowiki>|<\/nowiki>|=/,"")
  return text
end

def shape_name text
  text = text.scan(/\| *社名 *= *(.*?)\|/).first.first if text.match(/\| *社名 *= *(.*?)\|/)
  text = text.scan(/\| *社名 *= *(.*?)\z/).first.first  if text.match(/\| *社名 *= *(.*?)\z/)
  text = shape_text(text)&.gsub(/http.*/,'')

  return text
end

def shape_industry text
  text = shape_text(text)
  text&.gsub(/(\d{4})/, INDUSTRY_CODE)
end

def shape_zipcode text
  text = shape_text(text)
  zipcode = text&.tr("０-９","0-9")&.scan(/\d/)&.join('')
end

def shape_text text
  text ||= ""
  text = CGI.unescapeHTML(text.clone)
  text = text&.gsub(/\[\[\s*画像\s*:.*?\]\]|\[\[\s*ファイル\s*:.*?\]\]/,'')
  text&.scan(/\[\[.*?\]\]/).each do |part|
    text = text&.gsub(part,"#{part&.split('|')&.last&.gsub(/\[|\]/,'')}")
  end
  text = text&.gsub(/\[|\]/,'')&.gsub(/\{\{.*?\}\}/,'')
  text = text&.split(/<br.*?>/)&.compact&.delete_if(&:empty?)&.join("\n")
  text = text&.gsub(/<ref.*<\/ref>/,'')
  text = text&.gsub(/<.*?>/,'')

  text = text&.split('|')&.first if text&.include?('|')
  return text
end

def output_file_name file_name
  file_name.gsub('.csv','_shaped.csv').gsub('data/source/','data/shaped/')
end

def output_file_name_for_oversea file_name
  file_name.gsub('.csv','_oversea.csv').gsub('data/source/','data/shaped/')
end

def output_file_name_for_noname file_name
  file_name.gsub('.csv','_noname.csv').gsub('data/source/','data/shaped/')
end

def get_industry code

end


file_names = Dir.glob('data/source/*.csv')
file_names.each do |file_name|
  shape(file_name)
end