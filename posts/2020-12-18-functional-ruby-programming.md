title: Beginning functional programming in Ruby
subtitle: Pipelines, callable objects, and other tools for cleaner code
---

Until recently, I had a vague notion of functional programming as Ph.D.-level math embodied in code that is only useful for theoretical problems. On a clear day, I could almost catch a glimpse of it way up in the clouds, surrounded by a halo of theorems, undisturbed by the nitty-gritty, impure real world below. Then I watched these talks:

- [**Blending Functional and OO Programming in Ruby**](https://youtu.be/rMxurF4oqsc) by Piotr Solnica.
- [**Real-World Functional Ruby**](https://youtu.be/4p4LE9J5bWA) by Tim Riley.
- [**Boundaries**](https://www.destroyallsoftware.com/talks/boundaries) by Gary Bernhardt.

Here's what I learned:

1. Any domain can benefit from functional techniques.
2. These techniques can result in code that is simpler, more bug-proof, and more extensible.
3. Functional and object-oriented approaches are not exclusive; they can profitably work side by side.

So what are these techniques? Here are three that are already improving my code.

**DISCLAIMER:** These efforts of mine are *functional lite* or *baby functional*. For a more comprehensive approach, see [dry-rb](https://dry-rb.org/). The reason I'm doing my own thing for now is that I don't understand all the functional paraphernalia, and I'm guessing I have yet to experience the problems that make them useful. In the dry-rb docs I found a good piece of advice: if it's confusing, learn a functional language such as Haskell and then come back and it will make sense. So I'll do that sometime, but here is the low-hanging functional fruit that I'm already picking.

**ANOTHER DISCLAIMER:** I'm new to Ruby, so if you see any glaring stupidities below, you can take comfort in the fact that in a few months I will be shaking my head right alongside you. In the meantime, [please let me know](https://www.reddit.com/message/compose/?to=fps-vogel) of anything that can be improved.

## 1. Pipe data …

Thinking in terms of a data pipeline can be immensely clarifying. Here is the outermost layer of my current project, a CLI app that gives statistics on a reading log. Note that for this to work, `piper.rb` redefines the `>>` operator (and the forward proc composition operator is changed from `>>` to `+`, and Integer right shift from `>>` to `#rshift`). The fact that it's so easy to do this is one of the many reasons I love Ruby. ❤️

    require_relative "piper"
    require_relative "errors"
    # ... requires for the function classes LoadLibrary, etc.

    module ReadStat
      extend Piper

      @err_block = ->(err) { err.show }

      'C:\read_test.csv' >>
        LoadLibrary(&@err_block) >>
        EachInput do |lib, input|
          +[lib, input] >>
            Command >>
            ShowOutput
        rescue InputError => e; @err_block.call(e)
        end
    rescue AppError => e; @err_block.call(e)
    end

In other words, "Take this file path, load the library from there, then for each user input, take the input and library and run a command based on them, then output the results. Handle errors by showing them to the user. After input errors, keep asking for input. After bigger app errors, end execution. Errors during library loading will be handled there."

**NOTE:** The `+` operator before an array converts it to piped arguments. The syntax where a block appears after the function class name is achieved through `method_missing`.

**DIGRESSION ABOUT EXCEPTIONS:** Yes, I know exceptions are poor functional form. *Functional lite*, remember? For my purposes, it seems sufficient to use a combination of exceptions and `nil` representing failure. (The safe navigation operator `a&.b` and [`Object#presence`](https://apidock.com/rails/Object/presence) make it a lot easier to work with `nil`.) So right now the added complexity of [monads](https://dry-rb.org/gems/dry-monads/1.3/) or the [null object pattern](https://avdi.codes/null-objects-and-falsiness/) doesn't seem justified. But again, maybe I just need to go learn Haskell and then I'll understand.

Anyway, this is the vanilla-Ruby equivalent of my monkey-patched code above. First, with regular, non-pipeline calls (and here I use the `.()` shortcut for `.call()`):

    module ReadStat
      @err_block = ->(err) { err.show }

      EachInput.(LoadLibrary.('C:\read_test.csv', &@err_block)) do |input, lib|
        ShowOutput.(Command.(input, lib))
        rescue InputError => e; @err_block.(e)
      end
    rescue AppError => e; @err_block.(e)
    end

That's a bit confusing, with parts that seem backward. We can properly order the calls with `Object#then`:

    module ReadStat
      @err_block = ->(err) { err.show }

      'C:\read_test.csv'
        .then { |path| LoadLibrary.(path, &@err_block) }
        .then do |lib|
          EachInput.(lib) do |input, lib|
            Command.(input, lib)
              .then { |result| ShowOutput.(result) }
            rescue InputError => e; @err_block.(e)
          end
        end
    rescue AppError => e; @err_block.(e)
    end

This *does* follow the same flow as my monkey-patched pipeline. But it's kind of a mess.

In any case, the important point is to *think in terms of a pipeline* to see where it could simplify your design.

## 2. … through functions

These pipelines are based on functions, which in Ruby means *callable objects*. Here are some examples, starting with the first function above.

In `load_library.rb`:

    module ReadStat
      class LoadLibrary
        include Piper

        def call(path, &err_block)
          path >>
            ReadSections >>
            ReadLines >>
            Item(&err_block) >>
            Library
        end
      end

      class ReadSections
        ...  #call and helper methods
      end

      class ReadLines
        ...  #call and helper methods
      end
    end

Again, a pipeline helps to break down a task into simpler parts: "To load the library, take a given file path, then read its major sections (e.g. *currently reading*, *done reading*, and *want to read*), then parse each section's lines into item data, use that data to make a bunch of Item objects, then throw those into a new Library object. Pass along the error handling process to Item creation (since some missing Item fields should only generate warnings and not fatal errors)."

## 3. Avoid state mutation

The talks linked earlier do a good job of explaining why an object's state should be immutable wherever possible: if an object's state can be changed, then you can never be sure that its state is what you think it is. And thus bugs are born.

Whenever an object *does* need to be modified, you can often get around it by following Solnica's advice in the first video above: instead of changing the object's state, add a `with` method which returns a new object with the desired state.

Here's an example. For certain reading statistics, it is necessary to split an Item into smaller one-month parts: for example, calculating the average amount read per day in a given month. If an Item spans multiple months, only the part within the desired month(s) will be counted.

Here is a previous version, with state-mutating bits marked in comments. In the class `Item`:

    def split_months
      monthly_items = []
      monthly_items << shift_month while multi_month?
      monthly_items << self           # SELF HAS BEEN MUTATED! 😱
    end

    # necessary for #dup to work properly
    def initialize_copy(orig)
      self.state = orig.state
    end

    protected

    def multi_month?
      date_started.abs_month < date_finished.abs_month
    end
    # in Date: def abs_month; year * 12 + month; end

    # takes the first month out of self, with a new length to match
    def shift_month
      end_of_month = Date.new(date_started.year,
                              date_started.month, -1)
      separated = dup
      separated.set_dates(date_started, end_of_month)
      separated.length = length *
        ((end_of_month - date_started).to_f + 1) /
        ((date_finished - date_started).to_f + 1)
      self.length = length - separated.length       # SELF IS MUTATED! 😱
      set_dates(end_of_month + 1, date_finished)    # SELF IS MUTATED! 😱
      separated
    end

You can imagine how this could lead to a bug where the original Item is reused under the natural assumption that it still represents the entire, multi-month Item… an assumption that is sadly incorrect.

You might argue that any self-respecting coder would have avoided this problem from the start, but it was only for the sake of clarity that I chose this obviously problematic example. There are much more elusive ways that state changes can cause bugs.

Here's how I've refactored the above to eliminate unexpected state mutation:

    def split_months
      monthly_items = []
      remainder = self
      while remainder.multi_month?
        first_month, remainder = remainder.partition_at_first_month  # NO MUTATION 👍
        monthly_items << first_month
      end
      monthly_items << remainder
    end

    protected

    def multi_month?
      date_started.abs_month < date_finished.abs_month
    end

    # returns two Items:
    # 1. a copy with self's date started and the given date finished (w/ adjusted length)
    # 2. the remainder Item
    def partition_at_first_month
      end_of_month = Date.new(date_started.year, date_started.month, -1)
      first_length = length *
                     ((end_of_month - date_started).to_f + 1) /
                     ((date_finished - date_started).to_f + 1)
      first = with_dates(date_started, end_of_month)            # NON-MUTATING 👍
              .with_length(first_length)
      remainder = with_dates(end_of_month + 1, date_finished)   # NON-MUTATING 👍
                  .with_length(length - first.length)
      [first, remainder]
    end

Here are the `with_x` methods that this refactoring relies on:

    def with_dates(new_start, new_finish)
      new_state = state({ dates_started: [new_start.dup],
                          dates_finished: [new_finish.dup] })
      self.class.new(new_state)
    end

    def with_length(new_length)
      new_state = state({ length: new_length })
      self.class.new(new_state)
    end

And here is how state is defined, extracted, and set (not including validations):

    def self.fields
      %i[status
        rating
        format
        author
        title
        # ...
        ]
      end
    end
    fields.each { |field| attr_reader field }

    def initialize(args)
      self.state = args
    end

    # ...

    protected

    def state=(fields_to_change)
      fields_to_change.each do |k, v|
        instance_variable_set("@#{k}", v)
      end
    end

    def state(updates = nil)
      copy = fields.map do |field|
        [field, instance_variable_get("@#{field}").dup]
      end.to_h
      updates.nil? ? copy : copy.merge(updates)
    end

## Conclusion

If, like me, you'd love to learn Haskell *someday*, I hope I've given you some bits of functional programming that you can apply right away. I'm pleased with how these few simple concepts have done so much to clarify my code and (possibly) to prevent bug-induced headaches. On top of that, these functional techniques are concise and lightweight, not creeping over all of my code but ready at hand when I need to simplify a process. Not a bad first step for Baby Functional.
