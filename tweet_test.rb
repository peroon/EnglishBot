require 'twitter'
require 'pp'

$base = File.expand_path(File.dirname($0))
require $base + '/config.rb'

def twitter_client
  @twitter_client ||= Twitter::REST::Client.new do |config|
    config.consumer_key = CONSUMER_KEY
    config.consumer_secret = CONSUMER_SECRET
    config.access_token = ACCESS_TOKEN
    config.access_token_secret = ACCESS_TOKEN_SECRET
  end
end

# ファイルの行数取得
def get_file_row_num(filepath)
  count = %x{sed -n '=' #{filepath} | wc -l}.to_i
  return count
end

# ファイルからランダムで1行取得
def get_random_one_row(filepath) 
  count = get_file_row_num(filepath)
  random_index = rand(count)

  f = open(filepath, "r")
  return f.readlines[random_index]
end


#User's tweet
#client.user_timeline('peroon')

# 検索
#Search
#client.search('dropbox', :count=>3, :result_type=>'recent', :lang=>'ja').collect do |tweet|
  #p tweet.text
  #p tweet.user.screen_name
#end

#Follow / Unfollow
#client.follow(name)
#client.unfollow(name)

# 指定した単語でツイートしているユーザをx件取得
# ユーザのリストを返す
def search_user_by_word(search_word, num)
  p "search word : " + search_word

  return twitter_client.search(search_word, :count=>num, :result_type=>'recent', :lang=>'ja').take(num)
  #client.search(search_word, result_type: "recent").take(3)
end


def unfollow_old_user(user)
end

SLICE_SIZE = 100
def unfollow
  p "アンフォローするよ"
  unfollow_count = 0
  index = rand(10000)
  p "offset " + index.to_s

  # 100人ずつユーザ詳細取得
  twitter_client.friend_ids('eitantan').drop(index).each_slice(SLICE_SIZE) do |slice|
    twitter_client.users(slice).each do |user|
      # そのユーザのタイムラインを見て古いか調べる

      twitter_client.user_timeline(user.screen_name, {count:1}).each do |tweet|
      
        # 秒の差分
        time_diff_sec = Time.now - tweet.created_at
        pp time_diff_sec
        if time_diff_sec > 60 * 60 * 24 * 50 #50日
          p "最近ツイートしてないのでアンフォローします " + user.screen_name
          twitter_client.unfollow(user.screen_name)
          unfollow_count += 1
        else
          p "最近ツイートしてるのでアンフォローしません" + user.screen_name
        end
      end
    end
    
    #十分アンフォローしたら
    if unfollow_count > 0
      p "十分アンフォローしたのでbreakします " + unfollow_count.to_s
      break
    end

  end
end



#メインで使う関数たち
def tweet
  # ランダムツイート
  text = get_random_one_row($base+"/word_list.txt")
  p text
  twitter_client.update(text)  
end

def follow
  # フォロー
  random_word = get_random_one_row($base+"/search_word.txt")
  search_results = search_user_by_word(random_word, 1)
  search_results.each do |tweet|
    p tweet.user.screen_name + "をフォローします by " + random_word
    twitter_client.follow(tweet.user.screen_name)
  end
end

# 毎回実行する処理
def main
  require 'logger'
  log = Logger.new(STDOUT)
  log.info "i am log"

  tweet
  #follow
  unfollow
end

main