#!/bin/bash
# =====================================================================
# 海内服务器环境自动化部署脚本
# 
# Copyright © jshainei.com
# Author: sudem.sang@atonal.tech
# Version: 1.4.1
# Date: 2021-12-29
# Debug And Test Os: CentOS Linux release 7.5.1804 (Core) 
# 
# 修复因无法读取 脚本md5 导致的bug
#
#
# 路径及目录规划
# /HaiNeiSoft                     海内服务器通用更目录
# /HaiNeiSoft/Build               下载的不同的环境包编译目录
# /HaiNeiSoft/Env                 安装后的环境包的所在目录
# /HaiNeiSoft/App                 部署的网站，应用服务的代码文件目录
#=======================================================================

# 定义脚本的版本信息
ShellVer="1.4.1"
ShellUpdate="2021-12-29"

# 定义环境资源包名称和路径地址 
SourceFile="SourceFile_1.2.zip"
SourceFile_Md5="" 

# 定义海内外网镜像地址
MirrorHaiNei="mirrors.jshainei.com/smb/autoInstall"





# 自动设置 YUM 源
# 支持1.清华源 2.阿里源 3.腾讯源 4.华为源
function AutoConfigYum(){

	echo "系统将自动设置 YUM 的Base 源 和 EPAL 源,您可在下列镜像源中选择，默认清华源"
	echo "[1]. 清华大学开源镜像(OpenTUNA)   https://opentuna.cn/"
	echo "[2]. 阿里巴巴开源镜像站           https://mirrors.aliyun.com/"
	echo "[3]. 腾讯软件源                   https://mirrors.cloud.tencent.com/"
	echo "[4]. 华为开源镜像站               https://mirrors.huaweicloud.com/"
	echo -n "请输入欲设置的YUM源的标号：" 
	read Sid
	case "$Sid" in 
	"1") MirrorSource="tsinghua";;
	"2") MirrorSource="aliyun";;
	"3") MirrorSource="qcloud";;
	"4") MirrorSource="huawei";;
	"*") MirrorSource="tsinghua";;
	esac
	
	# 从远端下载对应系统版本的repo 文件，并更新yum 的配置
	DownloadUrl="https://${MirrorHaiNei}/mirrors/repo/${MirrorSource}/Centos-7.repo"
	cp -a /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
	curl -o /etc/yum.repos.d/CentOS-Base.repo $DownloadUrl
	
	# 删除腾讯云可能存在的centos-epel源的配置文件
	if [ ! -f "/etc/yum.repos.d/CentOS-Epel.repo" ]; then
		rm -rf CentOS-Epel.repo
	fi
	yum install -y "https://${MirrorHaiNei}/mirrors/epel/epel-release-latest-7.noarch.rpm"
	
	# 更新EPAL 源的配置信息
	if [[ $MirrorSource == "aliyun" ]]
	then
		sed -i "s/#baseurl/baseurl/g" /etc/yum.repos.d/epel.repo
		sed -i "s/metalink/#metalink/g" /etc/yum.repos.d/epel.repo
		sed -i "s/pgcheck=1/pgcheck=0/g" /etc/yum.repos.d/epel.repo
		sed -i "s@https\?://download.fedoraproject.org/pub@https://mirrors.aliyun.com@g" /etc/yum.repos.d/epel.repo
		
	elif [[ $MirrorSource == "tencent" ]]
	then
	sed -i "s/#baseurl/baseurl/g" /etc/yum.repos.d/epel.repo
	sed -i "s/metalink/#metalink/g" /etc/yum.repos.d/epel.repo
	sed -i "s/pgcheck=1/pgcheck=0/g" /etc/yum.repos.d/epel.repo
	sed -i "s@https\?://download.fedoraproject.org/pub@https://mirrors.cloud.tencent.com@g" /etc/yum.repos.d/epel.repo
	
	elif [[ $MirrorSource == "huawei" ]]
	then
	sed -i "s/#baseurl/baseurl/g" /etc/yum.repos.d/epel.repo
	sed -i "s/metalink/#metalink/g" /etc/yum.repos.d/epel.repo
	sed -i "s/pgcheck=1/pgcheck=0/g" /etc/yum.repos.d/epel.repo
	sed -i "s@https\?://download.fedoraproject.org/pub@https://repo.huaweicloud.com@g" /etc/yum.repos.d/epel.repo
	
	else
	sed -i "s/#baseurl/baseurl/g" /etc/yum.repos.d/epel.repo
	sed -i "s/metalink/#metalink/g" /etc/yum.repos.d/epel.repo
	sed -i "s/pgcheck=1/pgcheck=0/g" /etc/yum.repos.d/epel.repo
	sed -i "s@https\?://download.fedoraproject.org/pub@https://opentuna.cn@g" /etc/yum.repos.d/epel.repo
	fi
	
	cp /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 /etc/pki/rpm-gpg/RPM-GPG-KEY-7

	yum clean all
	yum makecache
	echo "======================================="
	echo "|YUM 源、EPAL源已经更新完成           "
	echo "|镜像源:${MirrorSource}               "
	echo "======================================="
}



# 安装 JDK 环境 
function Install_JDK(){

	# 获取JDK 环境的包
	Download="本地安装"
	SrcFile="jdk-8u201-linux-x64.tar.gz"
	rm -rf /HaiNeiSoft/Build/$SrcFile
	if [ ! -f "source/${SrcFile}" ]; then
		Download="云端下载"
		echo "本地数据文件不存在...从云端下载数据中..."
		wget -O "/HaiNeiSoft/Build/${SrcFile}" "https://${MirrorHaiNei}/source/jdk-8u201-linux-x64.tar.gz"
		echo "从远端下载JDK 资源包成功"
	else
		cp "source/${SrcFile}" /HaiNeiSoft/Build/$SrcFile
	fi
	cd  /HaiNeiSoft/Build/ && tar -zxvf jdk-8u201-linux-x64.tar.gz
    mv -f jdk1.8.0_201 /usr/local/java
	JAVA_HOME="/usr/local/java"
	cat >> /etc/profile << EOF
export JAVA_HOME=/usr/local/java
export JRE_HOME=$JAVA_HOME/jre 
export CLASSPATH=.:$JAVA_HOME/lib:$JRE_HOME/lib 
export PATH=$JAVA_HOME/bin:$PATH
EOF
	source /etc/profile
	echo "======================================="
	echo "|JDK 环境已经部署完成                 "
	echo "|数据源:${Download}                   "
	echo "|JDK版本：java 1.8.0_201              "
	echo "|JDK安装目录:/usr/local/java      "
	echo "======================================="
}


# 安装 MYSQL 数据库
function Install_MYSQL(){
	groupadd mysql
	useradd -s /sbin/nologin -M -g mysql mysql
	Download="本地安装"
	echo -n "请输入欲设置的MYSQL的的ROOT密码：(回车默认 ZHEtang403~!)" 
	read MYSQL_PWD
	if [ $MYSQL_PWD =="" ];then
		MYSQL_PWD="ZHEtang403~!"
	fi
	echo "MYSQL 的ROOT密码:$MYSQL_PWD"
	echo "MYSQL 版本已经更新成 mysql-5.7.34,Fix MYSQL 可能会定时重启的错误"
	# 安装依赖环境
	yum install -y numactl libaio libaio-devel unzip
	# 海内 定制的MYSQL 数据库资源包
	SrcFile="mysql-5.7.34-hn.zip"
	rm -rf /HaiNeiSoft/Build/$SrcFile
	if [ ! -f "source/${SrcFile}" ]; then
		Download="云端下载"
		echo "本地数据文件不存在...从云端下载数据中..."
		wget -O "/HaiNeiSoft/Build/${SrcFile}" "https://${MirrorHaiNei}/source/mysql-5.7.34-hn.zip"
		echo "从远端下载MYSQL 资源包成功"
	else
		cp "source/${SrcFile}" /HaiNeiSoft/Build/$SrcFile
	fi
	cd /HaiNeiSoft/Build/
	unzip mysql-5.7.34-hn.zip
	cd mysql-5.7.34-hn
	tar xzvf mysql-5.7.34-linux-glibc2.12-x86_64.tar.gz
	mv mysql-5.7.34-linux-glibc2.12-x86_64 /usr/local/mysql
	mkdir /usr/local/mysql/data
	chown -R mysql:mysql /usr/local/mysql/data
	chmod -R 755 /usr/local/mysql/data
	touch /usr/local/mysql/error.log
	chown -R mysql:mysql /usr/local/mysql/error.log
	chmod -R 755 /usr/local/mysql/error.log 
	mv hn-my.cnf /etc/my.cnf
	mv hn-my.service /usr/lib/systemd/system/mysqld.service
	cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
	chkconfig --add mysqld 
	echo "export PATH=$PATH://usr/local/mysql/bin" >> /etc/profile
	source /etc/profile
	cd /usr/local/mysql/bin/
	./mysqld --initialize --user=mysql --datadir=/usr/local/mysql/data --basedir=/usr/local/mysql/
	systemctl start mysqld
	MYSQL_TEMP_PWD=$(grep "temporary password" /usr/local/mysql/error.log|cut -d "@" -f 2|awk '{print $2}')
 
	#废弃参数 用于控制密码长度
	#mysql -hlocalhost  -P3306  -uroot -p${MYSQL_TEMP_PWD} -e "set global validate_password_policy=0" --connect-expired-password
	mysql -hlocalhost  -P3306  -uroot -p${MYSQL_TEMP_PWD} -e "SET PASSWORD = PASSWORD('${MYSQL_PWD}')"  --connect-expired-password
	mysql -hlocalhost  -P3306  -uroot -p${MYSQL_PWD} -e "grant all privileges on *.* to root@'%' identified by '${MYSQL_PWD}'" --connect-expired-password
	source /etc/profile
	rm -rf /HaiNeiSoft/Build/mysql-5.7.34-hn
	
	firewall-cmd --permanent --add-port=3306/tcp
	firewall-cmd --reload
	
	echo "======================================="
	echo "|MYSQL 环境已经部署完成               "
	echo "|放行端口3306                         "
	echo "|重新打开终端来刷新MYSQL的环境变量    "
	echo "|数据源:${Download}                   "
	echo "|MYSQL版本：5.7.34 -hn                "
	echo "|MYSQL安装目录://usr/local/mysql/     "
	echo "|您可以使用 systemctl [start|stop|restart] mysqld 来启动/关闭/重启 MYSQL 服务"
	echo "======================================="
	
}

#安装 InfluxDB 数据库
function Install_InfluxDB(){
	Download="本地安装"
	SrcFile="influxdb-1.8.2.x86_64.rpm"
	rm -rf /HaiNeiSoft/Build/$SrcFile
	if [ ! -f "source/${SrcFile}" ]; then
		Download="云端下载"
		echo "本地数据文件不存在...从云端下载数据中..."
		wget -O "/HaiNeiSoft/Build/${SrcFile}" "https://${MirrorHaiNei}/source/influxdb-1.8.2.x86_64.rpm"
		echo "从远端下载InfluxDB 资源包成功"
	else
		cp "source/${SrcFile}" /HaiNeiSoft/Build/$SrcFile
	fi
	cd /HaiNeiSoft/Build/
	rpm -ivh influxdb-1.8.2.x86_64.rpm
	rm -rf influxdb-1.8.2.x86_64.rpm
	systemctl enable influxdb
	systemctl start influxdb
	firewall-cmd --permanent --add-port=8086/tcp
	firewall-cmd --reload
	echo "======================================="
	echo "|InfluxDB 环境已经部署完成            "
	echo "|放行端口:8086                        "
	echo "|数据源:${Download}                   "
	echo "|InfluxD版本：1.8.2                   "
	echo "======================================="

}

# 安装 Tomcat 环境
function Install_Tomcat(){
	Download="本地安装"
	SrcFile="apache-tomcat-8.5.38.tar.gz"
	rm -rf /HaiNeiSoft/Build/$SrcFile
	if [ ! -f "source/${SrcFile}" ]; then
		Download="云端下载"
		echo "本地数据文件不存在...从云端下载数据中..."
		wget -O "/HaiNeiSoft/Build/${SrcFile}" "https://${MirrorHaiNei}/source/apache-tomcat-8.5.38.tar.gz"
		echo "从远端下载Tomcat 资源包成功"
	else
		cp "source/${SrcFile}" /HaiNeiSoft/Build/$SrcFile
	fi
	mkdir /usr/local/tomcat
	mv /HaiNeiSoft/Build/apache-tomcat-8.5.38.tar.gz /usr/local/tomcat
	cd /usr/local/tomcat
	tar -zxvf apache-tomcat-8.5.38.tar.gz
	# 自动放行 tomcat 的 8080 端口
	firewall-cmd --permanent --add-port=8080/tcp
	firewall-cmd --reload
	cd /usr/local/tomcat/apache-tomcat-8.5.38/bin
	source /etc/profile
	./startup.sh
	echo "======================================="
	echo "|Tomcat 环境已经部署完成               "
	echo "|放行端口:8080                         "
	echo "|数据源:${Download}                    "
	echo "|Tomcat版本：8.5.38                    "
	echo "======================================="

}

# 安装 REDIS 数据库 环境
function Install_Redis(){
	Download="本地安装"
	SrcFile="redis-6.2.5-hn.zip"
	echo "REDIS 版本已经更新成 6.2.5,支持若干全新特性"
	rm -rf /HaiNeiSoft/Build/$SrcFile
	if [ ! -f "source/${SrcFile}" ]; then
		Download="云端下载"
		echo "本地数据文件不存在...从云端下载数据中..."
		wget -O "/HaiNeiSoft/Build/${SrcFile}" "https://${MirrorHaiNei}/source/redis-6.2.5-hn.zip"
		echo "从远端下载 Redis 资源包成功"
	else
		cp "source/${SrcFile}" /HaiNeiSoft/Build/$SrcFile
	fi
	cd /HaiNeiSoft/Build/
	# 删除旧版本的安装包 
	yum install unzip -y
	rm -rf redis-6.2.5
	unzip redis-6.2.5-hn.zip && rm -rf redis-6.2.5-hn.zip
	rm -rf pax_global_header
	yum install gcc gcc-c++ tcl -y
	chmod -R 777 redis-6.2.5
	cd redis-6.2.5
	make MALLOC=libc
	make install 
	mkdir /usr/local/redis
	mkdir /usr/local/redis/logs
	mkdir /usr/local/redis/config 
	mkdir /usr/local/redis/bin 
	mv /usr/local/bin/redis-benchmark  /usr/local/redis/bin/redis-benchmark
	mv /usr/local/bin/redis-check-aof  /usr/local/redis/bin/redis-check-aof
	mv /usr/local/bin/redis-check-rdb  /usr/local/redis/bin/redis-check-rdb
	mv /usr/local/bin/redis-cli        /usr/local/redis/bin/redis-cli
	mv /usr/local/bin/redis-sentinel    /usr/local/redis/bin/redis-sentinel
	mv /usr/local/bin/redis-server     /usr/local/redis/bin/redis-server
	cd ../
	# 新配置文件位置 /usr/local/redis/config/redis.conf
	mv config/redis.conf    /usr/local/redis/config/redis.conf
	mv config/redis.init    /etc/init.d/redis
	source /etc/profile
	chmod -R 777 /etc/init.d/redis
	chkconfig redis on
	systemctl start redis 
	firewall-cmd --permanent --add-port=6379/tcp
	firewall-cmd --reload
	echo "======================================="
	echo "|REDIS 环境已经部署完成                "
	echo "|REDIS 密码：HaiNei1205                "
	echo "|您可以使用 systemctl [start|stop|restart] redis 来启动/关闭/重启 REDIS 服务"
	echo "|放行端口:6379                         "
	echo "|数据源:${Download}                    "
	echo "======================================="
}
# 安装中文语言包支持
function Install_ChinaSupport()
{
	Download="本地安装"
	yum install kde-l10n-Chinese  -y
	yum reinstall glibc-common -y 
	LANG="zh_CN.UTF-8"
	echo "======================================="
	echo "|中文语言包&simsun字体已经安装完成               "
	echo "======================================="
}

# 获取当前服务器的外网IP地址
function Config_LocalInterIp(){
	LocalIp=$(curl https://ip.iw3c.top)
	echo "======================================="
	echo "|当前服务器的外网IP地址:${LocalIp}     "
	echo "======================================="
}

# 设置当前的服务器的DNS 地址
function Config_DNS(){
	rm -rf /etc/resolv.conf
	echo -e "nameserver 223.5.5.5\nnameserver 119.29.29.29" >> /etc/resolv.conf
	echo "======================================="
	echo "|DNS服务器地址已经更改                "
	echo "|主DNS地址:阿里云 223.5.5.5           "
	echo "|副DNS地址:腾讯云 119.29.29.29        "
	echo "======================================="
}

# 同步当前服务器的时间信息
function Config_SeverTime(){
	yum install ntp -y
	wget -O /etc/ntp.conf "https://${MirrorHaiNei}/source/ntp.conf"
	service ntpd stop
	ntpdate ntp.aliyun.com
	echo "======================================="
	echo "|同步服务器时间成功                    "
	echo "|NTP服务器地址: ntp.aliyun.com         "
	echo "======================================="
}


# 安装ffmpeg 环境
function Install_FFmpeg(){
	# 删除ffpmeg 
	rm -rf /usr/local/ffmpeg
	cd /HaiNeiSoft/Build/ 
	wget -O ffmpeg.sh "https://${MirrorHaiNei}/ffmpeg.sh"
	bash ffmpeg.sh
	echo "======================================="
	echo "|安装 FFPMEG 环境成功                   "
	echo "|请使用 ffpmeg -version 命令查看版本信息"
	echo "通常情况为 ffmpeg version 4.2.1         "
	echo "configuration: --prefix=/usr/local/ffmpeg --enable-gpl --enable-shared --enable-libx264"
	echo "======================================="
	ffmpeg -version
	
}

# 创建资源文件夹
if [ ! -d "/HaiNeiSoft" ]; then
	mkdir "/HaiNeiSoft"
fi
if [ ! -d "/HaiNeiSoft/Build" ]; then
	mkdir "/HaiNeiSoft/Build"
fi

md5sum $0 > /tmp/HN-autoinstall.md5
shellMd5=""
for line in $(</tmp/HN-autoinstall.md5)
do
	if [ "$shellMd5" = "" ]; then
	shellMd5=$line
	fi
done

curl "https://mirrors.jshainei.com/autoinstall/?_r=${RANDOM}" > /tmp/HN-autoinstall.c_md5
shellCMd5=$(</tmp/HN-autoinstall.c_md5)
echo "当前文件MD5:${shellMd5}"
echo "云端文件MD5:${shellCMd5}"
if [ "$shellCMd5" != "$shellMd5" ];then
	echo "更新海内一键安装脚本中..."
	yum install wget -y && wget https://mirrors.jshainei.com/smb/autoInstall/auto_install.sh -O auto_install.sh  && bash auto_install.sh 
else
	echo "当前已经是最新版本[${ShellVer}],更新于：${ShellUpdate}"
	echo "============================"
	echo "海内服务器环境自动化部署脚本"
	echo "[1].设置服务器的YUM和EPAL软件源"
	echo "[2].更改服务器的DNS地址为阿里和腾讯"
	echo "[3].校对并更改当前服务器的时间"
	echo "[4].获取当前服务器的外网IP地址"
	echo "[5].部署安装JDK 环境"
	echo "[6].部署安装Tomcat（需要JDK）"
	echo "[7].部署安装MYSQL 环境"
	echo "[8].部署安装Redis 环境"
	echo "[9].部署安装InfluxDB环境"
	echo "[10].部署安装FFMPEG（LibX254）环境"
	echo "============================="
	echo -n "请选择需要使用的功能:" 
	read choose
	case "$choose" in 
		"1") AutoConfigYum        		;;
		"2") Config_DNS           		;;
		"3") Config_SeverTime     		;;
		"4") Config_LocalInterIp  		;;
		"5") Install_JDK 		        ;;
		"6") Install_Tomcat   		    ;;
		"7") Install_MYSQL  		    ;;
		"8") Install_Redis 		        ;;
		"9") Install_InfluxDB  		    ;;
		"10") Install_FFmpeg            ;;
		"*") echo "输入的指令有误！"	;;
		esac
fi
