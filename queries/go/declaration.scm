(var_declaration
  (var_spec
    name: (identifier) @name)) @statement

(short_var_declaration
  left: (_
  (identifier) @name)) @statement

(parameter_list
  (parameter_declaration
    name: (identifier) @name)) @statement

(range_clause
  left: (_
  (identifier) @name)) @statement
