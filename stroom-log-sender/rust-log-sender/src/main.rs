use std::collections::HashMap;
use std::fs::File;
use std::future::Future;
use std::path::Path;
// use std::io::{stdout, Write};
use std::process::Command;
use std::string::String;
use std::sync::Arc;

use delay_timer::anyhow::Result;
// use anyhow::Result;
use delay_timer::error::TaskError;
use delay_timer::prelude::*;
// use crate::model::Source;
// use serde::de::{Deserialize, Deserializer, Error};
// use serde::ser::Serialize;
// use serde::{Deserialize, Deserializer, Serialize};
// use serde::de::Error;
// use smol::Timer;
use serde_yaml;

use crate::model::{Config, Source};

mod model;

fn main() -> Result<()> {

    let result = read_config_file();
    let config = result.expect("Can't read file");
    // let config: Config = read_config_file();
     // let s: &'static Config = &config;

    // println!("{:?}", &config);
    // println!("{:?}", &config.sources[0].feed_name);

    let delay_timer = DelayTimerBuilder::default().build();

    // Develop a print job that runs in an asynchronous cycle.
    // A chain of task instances.
    let _task_instance_chain = delay_timer.insert_task(
        build_serial_async_send_task(&config)?)?;

    // Park the main thread as the scheduled jobs run in the background
    std::thread::park();

    println!("{:?}", &config);
    Ok(())
}

// fn constrain_closure<F: Fn() -> dyn Future + 'static>(f: F) -> F {
//     f
// }

fn build_serial_async_send_task(config: &Config) -> Result<Task, TaskError> {
    let mut task_builder = TaskBuilder::default();

    // let my_config = config.clone();
    let config_arc = Arc::new(config.clone());
    let local_config_arc = config_arc.clone();

    let body = move || async {
        // println!("Do stuff");

        // Timer::after(Duration::from_secs(3)).await;

        // for source in &local_config_arc.sources {
        //     let mut command = build_command(&local_config_arc, &source);
        //     run_command(&mut command);
        // }
        println!("{:?}", &local_config_arc);

        println!("{:?}", chrono::Local::now());

        // println!("create_async_fn_body:i'success");
    };
    // println!("{:?}", &local_config_arc);

    // constrain_closure(body);

    task_builder
        .set_task_id(1)
        .set_frequency_repeated_by_seconds(5)
        .set_maximum_parallel_runnable_num(1)
        .spawn_async_routine(body)
}

fn run_command(command: &mut Command) {
    let output = command.output()
        .expect(format!("Error running script {}",
                        command.get_program().to_str().unwrap()).as_str());

    let status = output.status;
    println!("status: {}", &status.code().unwrap());

    let stdout_str = String::from_utf8_lossy(&output.stdout);
    println!("stdout:\n{}", stdout_str);
    let stderr_str = String::from_utf8_lossy(&output.stderr);
    println!("stderr:\n{}", stderr_str);
}

fn build_command(config: &Config, source: &Source) -> Command {
    check_file_exists(&config.script_location);

    let script = &config.script_location;
    let mut command = Command::new(script);
    command.current_dir(script);

    // TODO Prob ought to assemble a list of common args once
    //  then pass them to .args()
    // All the optional args common to all sources
    add_extra_headers(&mut command, &source.extra_headers);
    add_arg_from_bool(&mut command, "--secure", &config.secure);
    add_arg_from_bool(&mut command, "--pretty", &config.colour_output);
    add_arg_from_option(&mut command, "--max-sleep", &config.max_sleep_secs);
    add_arg_from_option(&mut command, "--key", &config.ssh_key);
    add_arg_from_option(&mut command, "--key-type", &config.ssh_key_type);
    add_arg_from_option(&mut command, "--cert", &config.ssh_certificate);
    add_arg_from_option(&mut command, "--cert-type", &config.ssh_certificate_type);
    add_arg_from_option(&mut command, "--cacert", &config.ssh_ca_certificate);

    // All the optional args for this source
    add_arg_from_option(&mut command, "--system", &source.system_name);
    add_arg_from_option(&mut command, "--environment", &source.environment);
    add_arg_from_option(&mut command, "--file-regex", &source.file_regex);
    add_arg_from_bool(&mut command, "--compress", &source.compress);
    add_arg_from_bool(
        &mut command,
        "--delete-after-sending",
        &source.delete_after_sending);

    // Finally the mandatory positional args
    command
        .arg(&source.source_directory)
        .arg(&source.feed_name)
        .arg(&config.destination_url);

    command
}

fn add_extra_headers(command: &mut Command, headers: &HashMap<String, String>) {
    for (key, value) in headers {
        command
            .arg("--header")
            .arg(format!("{}:{}", key, value));
    }
}

fn add_arg_from_bool(command: &mut Command, arg: &str, val: &bool) {
    command
        .arg(arg)
        .arg(val.to_string());
}

fn add_arg_from_string(command: &mut Command, arg: &str, val: String) {
    if !val.is_empty() {
        command
            .arg(arg)
            .arg(val);
    }
}

fn add_arg_from_option<T>(command: &mut Command, arg: &str, opt_val: &Option<T>)
    where T: std::fmt::Display {
    if opt_val.is_some() {
        // TODO not sure this bit is right
        let val: String = opt_val.as_ref().unwrap().to_string();
        command
            .arg(arg)
            .arg(val);
    }
}

fn validate_config(config: &Config) {
    let mut errors: Vec<String> = Vec::new();

    check_not_empty(&mut errors, &config.script_location, "scriptLocation");
    check_not_empty(&mut errors, &config.destination_url, "destinationUrl");
    check_not_empty(&mut errors, &config.send_interval, "sendInterval");

    if config.sources.is_empty() {
        errors.push(String::from("Missing sources value"));
    } else {
        for (i, source) in config.sources.iter().enumerate() {
            check_not_empty(
                &mut errors,
                &source.feed_name,
                format!("feedName (source {})", i).as_str());
            check_not_empty(
                &mut errors,
                &source.source_directory,
                format!("sourceDirectory (source {})", i).as_str());
        }
    }
    if !errors.is_empty() {
        eprintln!("ERROR: The following {} error(s) where found when reading the config file",
                  errors.len());
        for error in errors {
            eprintln!("  {}", error);
        }
        std::process::exit(1);
    }
}

fn check_not_empty(errors: &mut Vec<String>, val: &String, name: &str) {
    // For some reason a null/missing value in the yaml gets deserialised as '~'
    if val.is_empty() || val == "~" {
        errors.push(format!("Missing {} value", name));
    }
}

fn check_file_exists(path: &String) {
    if !Path::new(path).exists() {
        eprintln!("ERROR: Script {} does not exist", path);
    }
}

fn read_config_file() -> Result<Config> {
    let file = File::open("config.yml").unwrap();
    let config: Config = serde_yaml::from_reader(file).unwrap();
    validate_config(&config);
    Ok(config)
}
