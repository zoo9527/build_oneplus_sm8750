# 一加13、ACE 5 Pro本地编译
### 复刻时请不要更改项目名 否则将编译失败
#### 该脚本转译自酷安@Futabawa，如有侵权请联系``qiudaoyu2888@gmail.com``删除
## 使用方法<br>
* `git clone https://github.com/showdo/build_oneplus_sm8750.git`<br>
#### ⚠️注意：如果你想使用你复刻的项目进行编译请将上面链接中的``showdo``改成为你的github用户名<br>
#### 假设你的用户名为``abcd``则你的链接为``git clone https://github.com/abcd/build_oneplus_sm8750.git``<br>
* ``cd build_oneplus_sm8750``<br>
* ``chmod +x Build_Kernel.sh``<br>
* ``sudo -E ./Build_Kernel.sh``<br>
#### ⚠️注意：这里的 -E必须有，否则主目录会识别成/root从而找不到目录导致编译失败<br>
## Windows推荐使用WSL运行-这里提供WSL转移到其他盘（E）避免文件占用C盘<br>
### WSL2迁移至其他目录<br>
#### (1) 管理员身份运行PowerShell，执行：<br>
``wsl -l -v``<br>
#### (2) 停止正在运行的wsl<br>

``wsl --shutdown``<br>

#### (3) 将需要迁移的Linux，进行导出<br>

``wsl --export Ubuntu-20.04 E:/ubuntu.tar``<br>

#### (4) 导出完成之后，将原有的Linux卸载<br>

``wsl --unregister Ubuntu-20.04``<br>

#### (5) 将导出的文件放到需要保存的地方，进行导入即可<br>

``wsl --import Ubuntu-20.04 E:\ubuntu\ E:\ubuntu.tar --version 2``<br>

#### (6) 设置默认用户<br>
``ubuntu2004.exe config --default-user <username>  ``<br>
其中的``<username>``为你安装WSL时设置的用户名<br>
我的用户名为``qiudaoyu``则命令为：<br>
``ubuntu2004.exe config --default-user qiudaoyu  ``<br>
<br>
