gather 会根据系统 service name 自动与对应 service (`/var/run/$NAME/$NAME/pid`) 建立联系, 并周期性(默认每秒)获取进程信息, 以 JSON 格式按行追加在 `~/data/alarm-system/$NAME.dump` 文件末尾.

当 service 重启后, gather 会再次检查 PID 并重新建立映射, 因此无需手动操作.

其中各个参数均可改变 (比如路径, 信息存储/转发方式, 采集频率等).

目前采集类型有:

+ 该进程相对于多核 cpu 的整体使用率
+ 该进程的内存用量
+ 该进程的 I/O
