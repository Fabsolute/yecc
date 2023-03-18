defmodule Yecc do
  alias Yecc.Util
  alias Yecc.Struct.Rule

  defmacro __using__(opts) do
    file = Keyword.get(opts, :file)

    quote do
      @symbol_empty :__empty__
      @symbol_end :__end__
      @nonterminals [{}]
      @terminals [@symbol_empty]

      @precedences []
      @rules []
      @expect 0

      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)

      load(unquote(file))
    end
  end

  defmacro __before_compile__(env) do
    Util.Table.initialize_tables()

    [
      &check_grammar/1,
      &update_rules/1,
      &Util.create_symbol_table/1,
      &Util.create_codeds/1,
      &Util.compute_states/1
    ]
    |> Enum.each(& &1.(env.module))

    rest =
      [:symbol_table, :rule_pointer_to_rule, :codeds, :rule_pointer_rhs, :rule_pointer_info]
      |> Enum.map(&{&1, Util.Table.get_content(&1)})
      |> Macro.escape()

    quote do
      def parse(tokens) do
        {tokens,
         [
           precedences: @precedences,
           root: @root,
           nonterminals: @nonterminals,
           terminals: @terminals,
           rules: @rules,
           expect: @expect
         ] ++ unquote(rest)}
      end

      def return_error(a, b) do
        quote do
          unquote(a ++ b)
        end
      end
    end
  end

  defmacro {name, _meta, nil} ~> context do
    {context, right} =
      Util.get_names(context)
      |> List.pop_at(-1)

    context = Macro.escape(context)

    quote do
      @rules @rules ++
               [%Rule{symbols: [unquote(name) | unquote(right)], tokens: unquote(context)}]
    end
  end

  defmacro root(context) do
    [context] = Util.get_names(context)

    quote do
      @root unquote(context)
    end
  end

  defmacro expect(value) do
    quote do
      @expect unquote(value)
    end
  end

  defmacro nonterminals(context) do
    context = context |> Util.clear_context() |> Enum.flat_map(&Util.get_names/1)

    quote do
      @nonterminals @nonterminals ++ unquote(context)
    end
  end

  defmacro terminals(context) do
    context = context |> Util.clear_context() |> Enum.flat_map(&Util.get_names/1)

    quote do
      @terminals @terminals ++ unquote(context)
    end
  end

  for precedence_name <- [:right, :left, :nonassoc, :unary] do
    defmacro unquote(:"#{precedence_name}")(context) do
      {precedence, context} =
        Util.get_names(context)
        |> List.pop_at(-1)

      precedence_name = unquote(precedence_name)

      quote do
        @precedences @precedences ++
                       [{unquote(precedence_name), unquote(precedence), unquote(context)}]
      end
    end
  end

  defmacro load(nil), do: nil

  defmacro load(file) do
    [Path.dirname(__ENV__.file), file]
    |> Path.join()
    |> File.read!()
    |> Code.string_to_quoted!()
  end

  defp check_grammar(module) do
    root = Module.get_attribute(module, :root)
    nonterminals = Module.get_attribute(module, :nonterminals)
    terminals = Module.get_attribute(module, :terminals)
    rules = Module.get_attribute(module, :rules)
    precedences = Module.get_attribute(module, :precedences)

    cond do
      root == nil -> raise "root missing"
      nonterminals == [] -> raise "nonterminals missing"
      terminals == [] -> raise "terminals missing"
      rules == [] -> raise "rules missing"
      true -> :ok
    end

    all = terminals ++ nonterminals

    if all != Enum.uniq(all) do
      raise "terminals and nonterminals should be unique"
    end

    precedences = Enum.flat_map(precedences, &elem(&1, 2))

    if precedences != Enum.uniq(precedences) do
      raise "precedences should be unique"
    end
  end

  defp update_rules(module) do
    rules =
      [
        %Rule{symbols: [{}, Module.get_attribute(module, :root)], tokens: []}
        | Module.get_attribute(module, :rules)
      ]
      |> Enum.with_index()
      |> Enum.map(fn {rule, index} -> %{rule | n: index} end)

    Module.put_attribute(module, :rules, rules)
  end
end
