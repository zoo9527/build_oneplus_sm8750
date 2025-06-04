# 一加13、13T、ACE 5 Pro本地编译
[![Build]([https://img.shields.io/badge/GitHub%20Actions-Build-181717?logo=github&logoColor=white&style=flat-square](https://img.shields.io/gitlab/stars/:project
))](https://github.com/Numbersf/Action-Build/actions/workflows/Build%20SukiSU%20Ultra%20OnePlus.yml) [![Channel](https://img.shields.io/badge/Follow-Telegram-blue.svg?logo=telegram)](https://t.me/taichi91) [![OnePlus Kernel Manifest](https://img.shields.io/badge/OnePlus%20Kernel%20Manifest-EB0029?logo=oneplus&logoColor=white&style=flat-square)](https://github.com/OnePlusOSS/kernel_manifest)
### 复刻时请不要更改项目名 否则将编译失败
#### 作者：TG频道T 一加13、13T、ACE 5 Pro本地编译
### 复刻时请不要更改项目名 否则将编译失败
#### 作者：TG频道T
#### 该项目转译自酷安@Futabawa工作流
## 使用方法<br>
* `git clone https://github.com/showdo/build_oneplus_sm8750.git`<br>
#### ⚠️注意：如果你想使用你复刻的项目进行编译请将上面链接中的``showdo``改成为你的github用户名
#### 假设你的用户名为``abcd``则你的链接为``git clone https://github.com/abcd/build_oneplus_sm8750.git``
* ``cd build_oneplus_sm8750``<br>
* ``chmod +x Build_Kernel.sh``<br>
* ``./Build_Kernel.sh``<br>

## Windows推荐使用WSL运行-这里提供WSL转移到其他盘（E）避免文件占用C盘
### WSL2迁移至其他目录<br>
#### (1) 管理员身份运行PowerShell，执行：
``wsl -l -v``<br>
#### (2) 停止正在运行的wsl<br>

``wsl --shutdown``<br>

#### (3) 将需要迁移的Linux，进行导出

``wsl --export Ubuntu-20.04 E:/ubuntu.tar``<br>

#### (4) 导出完成之后，将原有的Linux卸载

``wsl --unregister Ubuntu-20.04``<br>

#### (5) 将导出的文件放到需要保存的地方，进行导入即可

``wsl --import Ubuntu-20.04 E:\ubuntu\ E:\ubuntu.tar --version 2``<br>

#### (6) 设置默认用户
``ubuntu2004.exe config --default-user <username>  ``<br>
其中的``<username>``为你安装WSL时设置的用户名<br>
我的用户名为``qiudaoyu``则命令为：<br>
``ubuntu2004.exe config --default-user qiudaoyu  ``<br>
<br>
