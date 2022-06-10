// use delay_timer::anyhow::Result;
use core::option::Option;
use std::collections::HashMap;
// use serde::de::{Deserialize, Deserializer, Error};
// use serde::{Deserialize, Deserializer};
use serde::Deserialize;
// use serde::de::{Error};
// use serde::ser::{Serialize};
// use serde_yaml;

#[derive(Deserialize, Debug, Clone)]
// #[serde(remote = "Self", rename_all = "camelCase")]
#[serde(rename_all = "camelCase")]
pub struct Config {
    pub(crate) script_location: String,
    pub(crate) colour_output: bool,
    pub(crate) destination_url: String,
    pub(crate) max_sleep_secs: Option<u32>,
    // #[serde(default = "false")]
    pub(crate) parallel: bool,
    pub(crate) ssh_ca_certificate: Option<String>,
    pub(crate) ssh_certificate: Option<String>,
    pub(crate) ssh_certificate_type: Option<String>,
    pub(crate) ssh_key: Option<String>,
    pub(crate) ssh_key_type: Option<String>,
    // #[serde(default = "bool::from(true)")]
    pub(crate) secure: bool,
    // ISO8601 duration
    pub(crate) send_interval_secs: i64,
    pub(crate) sources: Vec<Source>,
}

// #[serde(remote = "Self", rename_all = "camelCase")]
#[derive(Deserialize, Debug, Clone)]
#[serde(rename_all = "camelCase")]
pub struct Source {
    // #[serde(default = "false")]
    pub(crate) delete_after_sending: bool,
    // #[serde(default = "false")]
    pub(crate) compress: bool,
    pub(crate) environment: Option<String>,
    pub(crate) extra_headers: HashMap<String, String>,
    pub(crate) feed_name: String,
    pub(crate) file_regex: Option<String>,
    pub(crate) source_directory: String,
    pub(crate) system_name: Option<String>,
}
