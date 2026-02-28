# Age Encryption

[age](https://github.com/FiloSottile/age) is used to encrypt and decrypt files. Encrypted files are suffixed with `.age`.

The secret key must be at `~/.age/secret-key.txt`. It is stored in [1Password](https://start.1password.com/open/i?a=KVD4KHJ525AS3LLIH2ZHCEQLDI&v=kt76oi5s3tqjg54lvlolplvvaq&i=i2cv74sjuijo52jolucqqwmm3y&h=my.1password.com).

```bash
op read "op://kt76oi5s3tqjg54lvlolplvvaq/Age CLI Identity/password" > ~/.age/secret-key.txt
```

## Encrypt a file

```bash
age --encrypt --identity ~/.age/secret-key.txt -o <output.age> <input>
```

## Decrypt a file

```bash
age --decrypt --identity ~/.age/secret-key.txt <file.age>
```
