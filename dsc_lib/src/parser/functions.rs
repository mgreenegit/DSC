// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

use serde_json::{Number, Value};
use tree_sitter::Node;

use crate::DscError;
use crate::configure::context::Context;
use crate::parser::{
    expressions::Expression,
    FunctionDispatcher,
};

#[derive(Clone)]
pub struct Function {
    name: String,
    args: Option<Vec<FunctionArg>>,
}

#[derive(Clone)]
pub enum FunctionArg {
    Value(Value),
    Expression(Expression),
}

impl Function {
    /// Create a new `Function` instance.
    ///
    /// # Arguments
    ///
    /// * `function_dispatcher` - The function dispatcher to use.
    /// * `statement` - The statement that the function is part of.
    /// * `function` - The function node.
    ///
    /// # Errors
    ///
    /// This function will return an error if the function node is not valid.
    pub fn new(statement_bytes: &[u8], function: &Node) -> Result<Self, DscError> {
        let Some(function_name) = function.child_by_field_name("name") else {
            return Err(DscError::Parser("Function name node not found".to_string()));
        };
        let function_args = function.child_by_field_name("args");
        let args = convert_args_node(statement_bytes, &function_args)?;
        Ok(Function{
            name: function_name.utf8_text(statement_bytes)?.to_string(),
            args})
    }

    /// Invoke the function.
    ///
    /// # Errors
    ///
    /// This function will return an error if the function fails to execute.
    pub fn invoke(&self, function_dispatcher: &FunctionDispatcher, context: &Context) -> Result<Value, DscError> {
        // if any args are expressions, we need to invoke those first
        let mut resolved_args: Vec<Value> = vec![];
        if let Some(args) = &self.args {
            for arg in args {
                match arg {
                    FunctionArg::Expression(expression) => {
                        let value = expression.invoke(function_dispatcher, context)?;
                        resolved_args.push(value.clone());
                    },
                    FunctionArg::Value(value) => {
                        resolved_args.push(value.clone());
                    }
                }
            }
        }

        function_dispatcher.invoke(&self.name, &resolved_args, context)
    }
}

fn convert_args_node(statement_bytes: &[u8], args: &Option<Node>) -> Result<Option<Vec<FunctionArg>>, DscError> {
    let Some(args) = args else {
        return Ok(None);
    };
    let mut result = vec![];
    let mut cursor = args.walk();
    for arg in args.named_children(&mut cursor) {
        match arg.kind() {
            "string" => {
                let value = arg.utf8_text(statement_bytes)?;
                result.push(FunctionArg::Value(Value::String(value.to_string())));
            },
            "number" => {
                let value = arg.utf8_text(statement_bytes)?;
                result.push(FunctionArg::Value(Value::Number(Number::from(value.parse::<i32>()?))));
            },
            "boolean" => {
                let value = arg.utf8_text(statement_bytes)?;
                result.push(FunctionArg::Value(Value::Bool(value.parse::<bool>()?)));
            },
            "expression" => {
                // TODO: this is recursive, we may want to stop at a specific depth
                let expression = Expression::new(statement_bytes, &arg)?;
                result.push(FunctionArg::Expression(expression));
            },
            _ => {
                return Err(DscError::Parser(format!("Unknown argument type '{0}'", arg.kind())));
            }
        }
    }
    Ok(Some(result))
}
