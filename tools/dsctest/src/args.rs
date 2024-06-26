// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

use clap::{Parser, Subcommand, ValueEnum};

#[derive(Debug, Clone, PartialEq, Eq, ValueEnum)]
pub enum Schemas {
    Delete,
    Echo,
    Exist,
    Sleep,
    Trace,
}

#[derive(Debug, Parser)]
#[clap(name = "dscrtest", version = "0.1.0", about = "Test resource", long_about = None)]
pub struct Args {
    /// The subcommand to run
    #[clap(subcommand)]
    pub subcommand: SubCommand,
}

#[derive(Debug, PartialEq, Eq, Subcommand)]
pub enum SubCommand {
    #[clap(name = "delete", about = "delete operation")]
    Delete {
        #[clap(name = "input", short, long, help = "The input to the delete command as JSON")]
        input: String,
    },

    #[clap(name = "echo", about = "Return the input")]
    Echo {
        #[clap(name = "input", short, long, help = "The input to the echo command as JSON")]
        input: String,
    },

    #[clap(name = "exist", about = "Check if a resource exists")]
    Exist {
        #[clap(name = "input", short, long, help = "The input to the exist command as JSON")]
        input: String,
    },

    #[clap(name = "schema", about = "Get the JSON schema for a subcommand")]
    Schema {
        #[clap(name = "subcommand", short, long, help = "The subcommand to get the schema for")]
        subcommand: Schemas,
    },

    #[clap(name = "sleep", about = "Sleep for a specified number of seconds")]
    Sleep {
        #[clap(name = "input", short, long, help = "The input to the sleep command as JSON")]
        input: String,
    },

    #[clap(name = "trace", about = "The trace level")]
    Trace,
}
