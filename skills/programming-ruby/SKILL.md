---
name: programming-ruby
description: Best practices when developing in Ruby codebases
---

# Programming Ruby

## Instructions

- Add underscores to large numeric literals to improve their readability.

```ruby
# bad - how many 0s are there?
num = 1000000

# good - much easier to parse for the human brain
num = 1_000_000
```
