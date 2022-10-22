# <3 some of My configs

the path of these files is `~/xxx`
some proxy config only worked when using [ClashX](https://github.com/yichengchen/clashX)

## The folder `730`

The 730 folder is a windows config, and it should be put at the Destination at:
> **Note**
>`C:\Program Files (x86)\Steam\userdata\455459836`

## The Vim config `.vimrc`

`.vimrc` should be placed at `~/`, path: `~/.vimrc`

## Learing Vim Text Object

By the way, surround vim is awesome.😎

Just remember the *i* and *a* operations, `i` for `inner`, `a` for `a`.

In `Markup Language` like html, `cit` mean change inner content of the current tag.
  * before `<h2>Sample Title</h2>`
  * after `<h2></h2>`

### Structure of an Editing Command
```
<number><command><text object or motion>
```
The `number` is used to perform the command over multiple text objects or motions, it is optional and appear either before or after the `command`.

The `command` is an operation, e.g., change, delete (cut), or yank (copy). The command is also optional; but without it, you only have a motion command, not an edit command.

The `text object` or `motion` can either be a text construct, e.g., a word, a sentence, a paragraph, or a motion, e.g., delete this word, change the next sentence, copy this paragraph.

* **Plaintext Text Objects**

    Vim provides text objects for the three building blocks of plaintext: words, sentences and paragraphs.
  
  1. **Words**
      * aw - a word (includes surrounding white space)
      * iw - inner word (does **not** include surrounding white space)
      
      Have a try with `daw` and `diw` command!
  2. **Sentences**
      * as - a sentence
      * is - inner sentence
      
      Have a try with `das` and `dis` command!
  3. **Paragraphs**
      * ap - s paragraph
      * ip - inner paragraph
      
      Have a try with `dap` and `dip` command!
      
* **Motion Commands vs. Text Objects Commands**
  
    A command using a motion, e.g., `cw`, operates from the current cursor position.
    
    A command using a text-object, e.g., `ciw` operates on the whole object regardless of the cursor position.

* **Pragramming Language Text Objects**
  1. **Strings**
      * a" - a double quoted string
      * i" - inner double quoted string
      * a' - a single quoted string
      * i' - inner single quoted string
      * a\` - a back quoted string
      * i\` - inner back quoted string
      
      `puts 'Hello "world"'` after `ci"`, get `puts 'Hello ""'`.
      
      `puts 'Hello "world"'` after `ci'`, get `puts ''`.
      
  2. **Parenthese**
      * a) - a parenthesized block
      * i) - inner parenthesized block
      
      `Project.all(:conditions => { :published => true })` after `ds)` get `Project.all`.
      
      > **Note**
      > The `%` motion is another way to match a pair of parentheses. Type `%` at the begining of a parenthesis will move the cursor to the closing parenthesis.
      > `c%` is like `ca)`. But with limits.
  3. **Brackets**
      * a] - a bracketed block
      * i] - inner bracketed block
      
  4. **Braces**
      * a} - a brace block
      * i} - inner brace block
    
  5. **Markup Language Tags**
      * at - a tag block
      * it - inner tag block
      
      `<h2>Sample Title</h2>` after `cit` : `<h2></h2>`
      
      > **Note**
      > the cursor was **not** even within the `<h2>`. This is a very efficient way to quickly replace tag content.
      
      * a> - a single tag
      * i> - inner single tag
      
      `<div id="content"></div>` after `di>` : `<></div>`
      
* **Vim Script Providing Additional Text Objects**
  1. **VimTextObject**
      * aa - an argument
      * ia - inner argument
      
      provide a text object for function arguments.
      
      `foo(32, var(3), 'hello');` after `cia`, get `foo(32, , 'hello');`
      
  2. **Indent Object**
      * ai - the current indentation level and the line above
      * ii - the current indentation level excluding the line above
      
      Aim for langs like `Python`, `CoffeeScript`, etc.
      
      ```
      def foo():
        if 3 > 5:
          return True
        return "foo"
      ```
      after the `dai`
      ```
      def foo():
        return "foo"
      ```
      
 The above are the base for vim objects. Vim surrounding is fast.
 ---
