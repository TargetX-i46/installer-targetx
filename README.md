## Target X SafeKey Installer instructions

1. Check config.txt
2. Uncomment the lines if running for the first time:
```bash
#sudo gpg --full-generate-key
#sudo gpg --list-secret-keys --keyid-format=long
```
3. Run
./install.sh