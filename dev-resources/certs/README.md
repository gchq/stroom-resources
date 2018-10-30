# Re-creating the dev certificates

To re-create all the dev certificates run the following script:

`./createCerts.sh`

This will delete existing certificates, CSRs, keys and keystores in the following directories then regenerate them all.

`certificate-authority`
`client`
`server`

NOTE: The generated files are for development/testing purposes only and are NOT for any form of produuction use.
