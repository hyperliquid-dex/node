# 需求

1. run.sh 通过 docker-compose.yml 来管理容器环境，比如 run.sh start 启动容器环境， run.sh stop 暂停容器环境。
2. docker-compose.yml 通过 Dockerfile 来创建 node service 使用的镜像。
3. docker-compose.yml 使用 config.env 来设置构建镜像，创建容器。
4. docker-compose.yml 使用 config.env 来设置 node service 容器启动时候 ENTRYPOINT 之外的参数。
5. Dockerfile 使用 init.sh 脚本初始容器环境。init.sh 不需要在容器启动的时候执行。
6. node service 容器的默认执行的命令式是`hl-visor run-non-validator`。
7. 容器中的/home/hluser/hl/data 挂载到环境变量指定的宿主机目录。如果环境变量指定的目录不存在就创建目录，注意目录权限，宿主机也要可以读取文目录下的文件内容。
8. 生成的脚本中不要有中文的注释或者打印。
9. 太简单的逻辑不要添加注释。
10. 代码中不要有中文注释和中文打印
11. 逻辑太简单的代码不要写注释。
12. 注意生成代码的格式，尤其是缩进错误。
