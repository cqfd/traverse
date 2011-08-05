# Traverse

Traverse is a simple tool that makes it easy to traverse XML.

Let's say you're messing around with Twitter's
[public timeline](http://api.twitter.com/statuses/public_timeline.xml).
Traverse let's you do things like this:
`
{% highlight ruby %}
timeline = Traverse::Document.new(open "http://api.twitter.com/statuses/public_timeline.xml")
timeline.statuses.each do |status|
  puts "#{status.user.name} says: #{status.text}"
end
{% endhighlight %}
