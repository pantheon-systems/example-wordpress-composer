# Troubleshooting

## Outline

- [Pulling Files and Database from Pantheon Test Environment](pulling-files-and-database-from-pantheon-test-environment)

## Pulling Files and Database from Pantheon Test Environment

Running this command:

```
lando pull --database=test --files=test --code=none
```

causes this error:

```
Notice: Undefined index: X-Pantheon-Styx-Hostname in /var/www/html/vendor/pantheon-systems/terminus/src/Models/Environment.php on line 851
 [error]  Pantheon headers missing, which is not quite right.
```

The `test` enviroment has not been created. Dev needs promoted first before the files or database can be pulled from it.