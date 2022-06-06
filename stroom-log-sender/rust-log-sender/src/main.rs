use std::collections::HashMap;
use std::fs::File;
use std::io::Write;
use std::path::Path;
use std::process::Command;
use std::string::String;
use std::sync::Arc;

use anyhow::{bail, Result};
use chrono::Utc;
use log::debug;
use log::Level::Debug;

use crate::model::{Config, Source};

mod model;

#[tokio::main]
async fn main() -> Result<()> {
    configure_logging();

    let result = read_config_file();
    let config = result.expect("Can't read file");

    debug!("{:?}", &config);
    debug!("Starting timer");
    let mut interval_timer = tokio::time::interval(
        chrono::Duration::seconds(7)
            .to_std()
            .unwrap());

    let config = Arc::new(config);
    loop {
        // Wait for the next interval tick
        interval_timer.tick().await;
        debug!("tick");

        if config.parallel {
            for (i, _source) in config.sources.iter().enumerate() {
                let config_clone = Arc::clone(&config);

                tokio::spawn(async move {
                    process_source(config_clone, i).await;
                });
            }
        } else {
            let config_clone = Arc::clone(&config);
            tokio::spawn(async move {
                process_all_sources(config_clone).await;
            }); // For async task
        }
        // tokio::task::spawn_blocking(|| do_my_task()); // For blocking task
    }
}

fn configure_logging() {
    let pid = std::process::id();
    env_logger::builder()
        .format(move |buf, record| {
            writeln!(buf,
                     "{: <6} [{}] [] [{}] {}",
                     record.level(),
                     Utc::now().format("%Y-%m-%dT%H:%M:%S%.3fZ"),
                     pid,
                     record.args()
            )
        })
        .init();
}

async fn process_all_sources(config: Arc<Config>) {
    debug!("process_all_sources() called");
    for source in &config.sources {
        let command: anyhow::Result<Command> = build_command(&config, &source);
        run_command(&mut command.unwrap());
    }
}

async fn process_source(config: Arc<Config>, source_idx: usize) {
    debug!("process_source() called");
    let command: anyhow::Result<Command> = build_command(
        &config,
        &config.sources.get(source_idx).unwrap());
    run_command(&mut command.unwrap());
}

fn run_command(command: &mut Command) {
    // TODO Not sure if we want to use output() or spawn()
    let output = command.output()
        .unwrap_or_else(|_| panic!("Error running script {}",
                                   command.get_program().to_str().unwrap()));

    let status = output.status;
    debug!("status: {}", &status.code().unwrap());

    if !&output.stdout.is_empty() {
        let stdout_str = String::from_utf8_lossy(&output.stdout);
        print!("{}", stdout_str);
    }

    if !&output.stderr.is_empty() {
        let stderr_str = String::from_utf8_lossy(&output.stderr);
        eprint!("{}", stderr_str);
    }
}

fn build_command(config: &Config, source: &Source) -> Result<Command> {
    let script_location = &config.script_location;
    let script_path = Path::new(script_location).join("send_to_stroom.sh");
    if !script_path.exists() {
        bail!(format!("Script {} does not exist", script_path.to_str().unwrap()))
    }

    let mut command = Command::new(&script_path);
    command.current_dir(&script_location);
    debug!("current_dir {}", &script_location);

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

    if log::log_enabled!(Debug) {
        debug_command(&mut command);
    }

    Ok(command)
}

fn debug_command(command: &mut Command) {
    debug!("Command {}", command.get_program().to_str().unwrap().to_string());
    let mut args_str = String::new();
    for arg in command.get_args() {
        if !args_str.is_empty() {
            args_str.push(' ')
        }
        args_str.push('\'');
        args_str.push_str(arg.to_str().unwrap());
        args_str.push('\'');
    }
    debug!("args: [{}]", args_str);
}

fn add_extra_headers(command: &mut Command, headers: &HashMap<String, String>) {
    for (key, value) in headers {
        command
            .arg("--header")
            .arg(format!("{}:{}", key, value));
    }
}

fn add_arg_from_bool(command: &mut Command, arg: &str, val: &bool) {
    // --xxx or --no-xxx
    let arg_string: String;
    let arg_modified = match val {
        true => &arg,
        false => {
            arg_string = String::from(arg).replace("--", "--no-");
            arg_string.as_str()
        }
    };

    command
        .arg(arg_modified);
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
    check_file_exists(&mut errors, &config.script_location, "scriptLocation");
    check_opt_file_exists(&mut errors, &config.ssh_ca_certificate, "sshCaCertificate");
    check_opt_file_exists(&mut errors, &config.ssh_certificate, "sshCertificate");
    check_opt_file_exists(&mut errors, &config.ssh_key, "sshKey");
    check_not_empty(&mut errors, &config.destination_url, "destinationUrl");
    check_greater_than_zero(&mut errors, config.send_interval_secs, "sendIntervalSecs");

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

fn check_greater_than_zero(errors: &mut Vec<String>, val: i64, name: &str) {
    if val <= 0 {
        errors.push(format!("{} should be greater than zero.", name));
    }
}

fn check_opt_file_exists(errors: &mut Vec<String>, path: &Option<String>, name: &str) {
    if path.is_some() {
        let path = path.as_ref().unwrap();
        if !path.is_empty() && !Path::new(&path).exists() {
            errors.push(format!("The path specified for {} ({}) does not exist", name, path));
        }
    }
}

fn check_file_exists(errors: &mut Vec<String>, path: &String, name: &str) {
    if !path.is_empty() && !Path::new(path).exists() {
        errors.push(format!("The path specified for {} ({}) does not exist", name, path));
    }
}

fn read_config_file() -> Result<Config> {
    // TODO Consider using https://docs.rs/crate/subst so we can do env var subst
    //  on the config values to allow some to be set in compose env vars.
    let file = File::open("config.yml").unwrap();
    let config: Config = serde_yaml::from_reader(file).unwrap();
    validate_config(&config);
    Ok(config)
}
