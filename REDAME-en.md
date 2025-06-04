# OnePlus 13, 13T, ACE 5 Pro Local Build

[![GitHub](https://img.shields.io/badge/-GitHub_Repo-181717?logo=github&logoColor=white&style=flat-square)](https://github.com/showdo/build_oneplus_sm8750)
[![Telegram](https://img.shields.io/badge/Telegram-Channel-blue.svg?logo=telegram)](https://t.me/qdykernel)
[![Coolapk|Homepage](https://img.shields.io/badge/%E9%85%B7%E5%AE%89%7C%E4%B8%BB%E9%A1%B5-3DDC84?style=flat-square&logo=android&logoColor=white)](http://www.coolapk.com/u/1624571)
[![OnePlus Kernel Source](https://img.shields.io/badge/OnePlus_Kernel_Source-EB0029?logo=oneplus&logoColor=white&style=flat-square)](https://github.com/OnePlusOSS/kernel_manifest)

### Please DO NOT change the project name when forking, otherwise the build will fail.

#### Author: TG Channel T — Local build for OnePlus 13, 13T, ACE 5 Pro

### If you change the project name when forking, please update the repository name in the usage instructions below by replacing `build_oneplus_sm8750` with your new repo name.

#### This project workflow is ported from Coolapk user @Futabawa.

---

## Usage

```bash
git clone https://github.com/showdo/build_oneplus_sm8750.git
```

> ⚠️ Note: If you want to build with your forked repo, replace `showdo` in the URL above with your GitHub username.  
> For example, if your username is `abcd`, use:  
> `git clone https://github.com/abcd/build_oneplus_sm8750.git`

```bash
cd build_oneplus_sm8750
chmod +x Build_Kernel.sh
./Build_Kernel.sh
```

---

## Recommended: Use WSL on Windows  
Here is how to move WSL to another drive (e.g., E:) to avoid occupying space on the C: drive.

### How to migrate WSL2 to another directory

1. Open PowerShell as Administrator, check running WSL distributions:

   ```powershell
   wsl -l -v
   ```

2. Shut down all running WSL instances:

   ```powershell
   wsl --shutdown
   ```

3. Export the Linux distro you want to move (example: Ubuntu-20.04):

   ```powershell
   wsl --export Ubuntu-20.04 E:/ubuntu.tar
   ```

4. Unregister the original distro:

   ```powershell
   wsl --unregister Ubuntu-20.04
   ```

5. Import the distro to the new location:

   ```powershell
   wsl --import Ubuntu-20.04 E:\ubuntu\ E:\ubuntu.tar --version 2
   ```

6. Set the default user for the distro:

   ```powershell
   ubuntu2004.exe config --default-user <username>
   ```

   Replace `<username>` with your WSL username.  
   For example, if your username is `qiudaoyu`:

   ```powershell
   ubuntu2004.exe config --default-user qiudaoyu
   ```

---

If you need any additional help or want to customize this README further, feel free to ask!
