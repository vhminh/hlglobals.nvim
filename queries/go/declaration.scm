(var_declaration
  (var_spec
    name: (identifier) @name)) @statement

(short_var_declaration
  left: (_
  (identifier) @name)) @statement

(const_declaration
  (const_spec
    name: (identifier) @name)) @statement

(parameter_list
  (parameter_declaration
    name: (identifier) @name)) @statement

(for_clause
  initializer: (short_var_declaration
    left: (expression_list
      (identifier) @name))) @statement

(range_clause
  left: (_
  (identifier) @name)) @statement
