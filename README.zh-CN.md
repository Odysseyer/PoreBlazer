# PoreBlazer
语言: [English](README.md) | **简体中文**

PoreBlazer (v4.0) 的高性能多线程实现（OpenMP 加速），包含源码、示例，以及针对 CSD MOF 子集约 12,000 个结构的几何性质计算数据。

该仓库重点优化了晶格与孔径分布（PSD）计算性能，并在实际基准中保持与串行基线结果的偏差很小。

## 1. 仓库内容
- 文件夹：**src**

包含完整源代码、预编译可执行文件，以及编译与运行说明（`README_PB_v4.0.txt`）。

- 文件夹：**data**

包含 MOF 结构与性质数据库文件：`MOFsubsetPB4.dat`、`MOFsubsetZeo++.dat`、`MOFsubsetRASPA.dat`。

- 压缩包：**PB4_vs_Zeo++_vs_RASPA.zip**

包含 HKUST-1、IRMOF-1、ZIF-8 的完整案例。

- 压缩包：**case_studies.zip**

包含更大规模的 MOF 与沸石案例集合。

## 2. 使用方法
下载仓库：
```bash
git clone https://github.com/SarkisovGroup/PoreBlazer
cd PoreBlazer
```

### 2.1 推荐方式：CMake（标准开源流程）
```bash
mkdir -p build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DPB_ENABLE_OPENMP=ON ..
cmake --build . -j
```

可执行文件位于：
```bash
build/bin/poreblazer
```

可选安装：
```bash
cmake --install .
```

常用 CMake 选项：
- `PB_ENABLE_OPENMP=ON|OFF`（默认 `ON`）
- `PB_ENABLE_NATIVE_OPT=ON|OFF`（默认 `OFF`，仅 GNU Fortran）
- `CMAKE_BUILD_TYPE=Release|Debug`

- 线程数由 `OMP_NUM_THREADS` 控制。
- 程序启动时会打印是否启用 OpenMP 及可用线程信息。
- 在与串行基线的基准对比中，自由体积与 PSD 输出保持基本不变。

### 2.2 兼容方式：Makefile 构建
```bash
cd src
make -f Makefile_gfort release-serial   # 生成 poreblazer_serial.exe
make -f Makefile_gfort release-omp      # 生成 poreblazer_omp.exe (OpenMP)
```

### 2.3 MPI 路线图（第二阶段）
计划的 MPI 域分解方案包括：
- 按 rank 划分晶格计算任务；
- 各 rank 计算本地可达性/PSD 贡献；
- 在 rank 0 汇总并输出最终结果。

当前尚未实现，需先安装 MPI 工具链（`mpifort`、`mpirun`）。

## 3. 运行方式
### 3.1 基础模式
基础模式使用默认参数。运行目录需包含 `defaults.dat` 与 `UFF.atoms`。  
`input.dat` 示例：
```bash
HKUST1.xyz
26.28791        26.28791        26.28791
90             90             90
```

说明：当 `defaults.dat` 使用 `UFF.atoms` 且运行目录没有该文件时，程序会自动尝试从可执行文件相关目录以及 `POREBLAZER_DATA_DIR` 查找。

运行：
```bash
./build/bin/poreblazer < input.dat
```

### 3.2 高级模式
高级模式可在 `defaults.dat` 中控制参数（He/N2 参数、截断半径、网格大小等）。示例：
```bash
UFF.atoms
2.58, 10.22, 298, 12.8
3.314
500
0.2
20.0, 0.25
21908391
0
```

## 4. 结果说明
程序会在屏幕打印结果，并写入 `summary.dat`。此外会输出：
- `Total_psd_cumulative.txt`
- `Total_psd.txt`
- `Network-accessible_psd_cumulative.txt`
- `Network-accessible_psd.txt`
- `probe_occupiable_volume.xyz`
- `nitrogen_network.xyz`
- `nitrogen_network.grd`

## 截图
![PB_v4.0.png](PB_v4.0.png)

## 贡献
如需贡献代码，请先通过 issue、邮件等方式和维护者沟通。

## 联系方式
**Email**: [Lev Sarkisov](mailto:lev.sarkisov@manchester.ac.uk)  
**Address**:  
The Department of Chemical Engineering and Analytical Science  
The University of Manchester  
Sackville Street  
Manchester, M13 9PL

## 许可证
本项目采用 GNU GPL（v3 或更高版本）。
