

require 'rails_helper'

RSpec.describe 'query-helper' do
  [[['figure', '*'], 'a', 'any figure'],
   [['figure', '*'], 'no', 'no figure'],
   [['figure', 'swing'], 'a', 'a swing'],
   [['figure', 'allemande'], 'a', 'an allemande'],
   [['none', ['figure', 'allemande']], 'a', 'no allemande'],
   [['none', ['or', ['figure', 'allemande'], ['figure', 'swing']]], 'a', 'no allemande and no swing'],
   [['none', ['and', ['figure', 'allemande'], ['figure', 'swing']]], 'a', 'no allemande or no swing'],
   [['none', ['follows', ['figure', 'allemande'], ['figure', 'swing']]], 'a', 'no (an allemande follows a swing)'],
   [['follows', ['figure', 'allemande'], ['figure', 'swing']], 'a', 'an allemande follows a swing'],
   [['follows', ['figure', 'allemande'], ['not', ['figure', 'swing']]], 'a', /an allemande follows a non +swing/],
   [['follows', ['figure', 'allemande'], ['not', ['or', ['figure', 'swing'], ['figure', 'chain']]]], 'a',
    /an allemande follows +not +\(a swing or a chain\)/],
   [['not', ['figure', 'swing']], 'a', /a non +swing/],
   [['not', ['or', ['figure', 'swing'], ['figure', 'chain']]], 'a', /not +\(a swing or a chain\)/],
   [["and",["follows",["figure","allemande"],["figure","balance"]],["figure","box circulate"]],
    'a', '(an allemande follows a balance) and a box circulate'],
   [['figure', '*'], 'a', 'any figure']
  ].each do |a|
    q, article, value = a
    it "buildFigureSentenceHelper(#{q.to_s}, #{article.inspect}) => #{value.inspect}" do
      expect(eval("buildFigureSentenceHelper(#{q.to_s}, #{article.inspect});")).to match(value)
    end
  end

  private
  def eval(string_of_javascript)
    context.eval(string_of_javascript)
  end

  def context
    @context || (@context = new_context)
  end

  def new_context
    context = MiniRacer::Context.new
    context.load(Rails.root.join('app','assets','javascripts','query_helper.js'))
    context
  end
end
