defmodule Yecc.Util.Table do
  @table_state_id :yecc_table_state_id
  @table_goto :yecc_table_goto
  @table_symbol :yecc_table_symbol
  @table_inverted_symbol :yecc_table_inverted_symbol
  @table_rhs :yecc_table_rhs
  @table_info :yecc_table_info
  @table_coded :yecc_table_coded
  @table_instance :yecc_table_instance
  @table_precedences :yecc_table_precedences
  @table_action :yecc_table_action

  def initialize_tables() do
    :ets.new(@table_state_id, [:set, :named_table])
    :ets.new(@table_goto, [:bag, :named_table])
    :ets.new(@table_symbol, [{:keypos, 1}, :named_table])
    :ets.new(@table_action, [{:keypos, 1}, :named_table])
    :ets.new(@table_inverted_symbol, [{:keypos, 2}, :named_table])
    :ets.new(@table_precedences, [:named_table])
    Agent.start_link(fn -> nil end, name: @table_rhs)
    Agent.start_link(fn -> nil end, name: @table_info)
    Agent.start_link(fn -> nil end, name: @table_coded)
    Agent.start_link(fn -> Keyword.new() end, name: @table_instance)
  end

  def get_instance_n() do
    get(@table_instance, :n_states)
  end

  def get_coded(key) do
    get(@table_coded, key)
  end

  def get_rhs() do
    get(@table_rhs)
  end

  def get_rhs(rule_pointer) do
    get(@table_rhs, rule_pointer)
  end

  def get_info(rule_pointer) do
    get(@table_info, rule_pointer)
  end

  def get_rule_pointer_to_rule(rule_pointer) do
    get(@table_instance, :rule_pointer_to_rule, rule_pointer)
  end

  def store_action(key, value) do
    :ets.insert(@table_action, {key, value})
  end

  def store_instance_n(value) do
    store(@table_instance, :n_states, value)
  end

  def store_instance_state_table(value) do
    store(@table_instance, :state_table, value)
  end

  def store_rule_pointer_to_rule(value) do
    store(@table_instance, :rule_pointer_to_rule, value)
  end

  def store_rhs(value) do
    store(@table_rhs, value)
  end

  def store_info(value) do
    store(@table_info, value)
  end

  def store_coded(value) do
    store(@table_coded, value)
  end

  def store_symbols(value) do
    IO.inspect(value, label: "store_symbols")
    :ets.insert(@table_symbol, value) |> IO.inspect(label: "result")
    :ets.insert(@table_inverted_symbol, value)
  end

  def store_precedences(value) do
    true = :ets.insert(@table_precedences, value)
  end

  def store_goto(value) do
    :ets.insert(@table_goto, value)
  end

  def store_state_id(value) do
    true = :ets.insert(@table_state_id, value)
  end

  def delete_state_id() do
    true = :ets.delete(@table_state_id)
  end

  def pop_all_goto() do
    g = :ets.tab2list(@table_goto)
    :ets.delete_all_objects(@table_goto)
    g
  end

  def lookup_element_state_id(state_id) do
    :ets.lookup_element(@table_state_id, state_id, 2)
  end

  def lookup_element_symbol(symbol) do
    :ets.lookup_element(@table_symbol, symbol, 2)
  end

  def lookup_element_inverted_symbol(symbol) do
    :ets.lookup_element(@table_inverted_symbol, symbol, 1)
  end

  def lookup_symbol(symbol) do
    :ets.lookup(@table_symbol, symbol) |> hd()
  end

  def lookup_inverted_symbol(symbol) do
    :ets.lookup(@table_inverted_symbol, symbol) |> hd()
  end

  def lookup_precedence(symbol) do
    case :ets.lookup(@table_precedences, symbol) do
      [] -> nil
      [e] -> e
    end
  end

  def lookup_goto(content) do
    case :ets.lookup(@table_goto, content) do
      [] -> nil
      [e] -> e
    end
  end

  def lookup_state(n) do
    get(@table_instance, :state_table, n)
  end

  def lookup_action(n) do
    try do
      :ets.lookup(@table_action, n) |> hd()
    catch
      _ -> :undefined
    end
  end

  def get_content(:symbol_table) do
    :ets.tab2list(@table_symbol)
  end

  def get_content(:rule_pointer_to_rule) do
    get(@table_instance, :rule_pointer_to_rule)
  end

  def get_content(:rule_pointer_rhs) do
    get(@table_rhs)
  end

  def get_content(:rule_pointer_info) do
    get(@table_info)
  end

  def get_content(:codeds) do
    get(@table_coded)
  end

  defp get(name) do
    Agent.get(name, & &1)
  end

  defp get(name, rule_pointer) when is_integer(rule_pointer) do
    Agent.get(name, &elem(&1, rule_pointer))
  end

  defp get(name, key) when is_atom(key) do
    Agent.get(name, &Keyword.get(&1, key))
  end

  defp get(name, key, n) when is_atom(key) and is_integer(n) do
    Agent.get(name, &(Keyword.get(&1, key) |> elem(n)))
  end

  defp store(name, key, value) when is_atom(key) do
    Agent.update(name, &Keyword.put(&1, key, value))
  end

  defp store(name, value) do
    Agent.update(name, fn _ -> value end)
  end
end
