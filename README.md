# Traverse

Traverse is a simple tool that makes it easy to traverse XML. 

Let's say you're messing around with Twitter's
[public timeline](http://api.twitter.com/statuses/public_timeline.xml).
Traverse let's you do things like this:
 
```ruby
timeline = Traverse::Document.new(open "http://api.twitter.com/statuses/public_timeline.xml")
timeline.statuses.each do |status|
  puts "#{status.user.name} says: #{status.text}"
end
```

For a slightly more complicated example, take a look at a
[boxscore](http://gd2.mlb.com/components/game/mlb/year_2011/month_03/day_31/gid_2011_03_31_detmlb_nyamlb_1/boxscore.xml)
pulled from Major League Baseball's public API.

```ruby
url = "http://gd2.mlb.com/components/game/mlb/year_2011/month_03/day_31/gid_2011_03_31_detmlb_nyamlb_1/boxscore.xml"
boxscore = Traverse::Document.new(open url)

# let's start traversing!

boxscore.game_id # => '2011/03/31/detmlb-nyamlb-1'
boxscore.battings[0].batters[1].name_display_first_last # => 'Derek Jeter'
boxscore.battings[0].batters.select do |batter|
  batter.rbi.to_i > 0
end.count # => 4
boxscore.pitchings.find do |pitching|
  pitching.team_flag == 'away'
end.out # => '24'
```
