(var_declaration
  (var_spec
    name: (identifier) @name)) @statement

(short_var_declaration
  left: (_
  (identifier) @name)) @statement

(function_declaration
  parameters: (parameter_list
    (parameter_declaration
      name: (identifier) @name)) @statement)
