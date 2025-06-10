## Target X SafeKey Installer instructions

This is the installer for safekey cloud, 5G, and safe login.
Prerequisites: i46 script must be installed

1. Check config.txt
2. Uncomment the lines if running for the first time:
```bash
#sudo gpg --full-generate-key
#sudo gpg --list-secret-keys --keyid-format=long
```
3. Run
./install.sh