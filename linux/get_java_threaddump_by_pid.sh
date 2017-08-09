#!/bin/sh
## @20170115 by qiueer
##
JDK_BIN_PATHS=/wls/apache/tomcat/jdk1.8.0_25/bin
PATH=$PATH:${JDK_BIN_PATHS}
export PATH

CURDIR=$(cd $(dirname ${BASH_SOURCE[0]});pwd)
CURR_DT=$(date +"%Y%m%d%H%M%S")
MAX_GET_CNT=5

PID=$1
if [ "x${PID}" = "x" ];then
	echo "Usage: $0 \${JAVA_PROCESS_PID}"
	exit 1
fi

PGID=$(ps -ef | awk '{print $2}' | awk -v PID="${PID}" '{if ($1==PID) print $1}')
if [ "x${PGID}" = "x" ];then
	echo "[ERROR] Pid:${PID} Can Not Found"
	exit 1
fi

LOG_DIRROOT=/tmp/dumplog/${CURR_DT}_${PID}
OS_INFO_LOGPATH=${LOG_DIRROOT}/os_base_info.out
THREAD_DUMP_LOGPATH=${LOG_DIRROOT}/threaddump_info.out
HEAP_DUMP_LOGPATH=${LOG_DIRROOT}/heapdump_info.hprof

mkdir -p ${LOG_DIRROOT}

### OS BASE INFO
echo "---netstat��ϢStart---" >>${OS_INFO_LOGPATH}
netstat -na >>${OS_INFO_LOGPATH}
echo "---netstat��ϢStop---" >>${OS_INFO_LOGPATH}
echo -e "\n\n" >>${OS_INFO_LOGPATH}

echo "---���̴��ļ���ϢStart---" >>${OS_INFO_LOGPATH}
ls -l /proc/${PGID}/fd >>${OS_INFO_LOGPATH}
echo "---���̴��ļ���ϢEnd---" >>${OS_INFO_LOGPATH}
echo -e "\n\n" >>${OS_INFO_LOGPATH}


########## JVM��Ϣ  ###########
# JVM �־ô�������Ϣ��JVM ���ڴ�ʹ����Ϣ
#echo "---JVM�־ô�������ϢStart---" >>${THREAD_DUMP_LOGPATH}
#echo "# jmap -permstat $PGID" >> ${THREAD_DUMP_LOGPATH}
#jmap -permstat $PGID>> ${THREAD_DUMP_LOGPATH}
#echo "---JVM�־ô�������ϢEND---" >>${THREAD_DUMP_LOGPATH}
#echo -e "\n\n" >>${THREAD_DUMP_LOGPATH}

# JVM �־ô�������Ϣ��JVM ���ڴ�ʹ����Ϣ
echo "---JVM����ϢStart---" >>${THREAD_DUMP_LOGPATH}
echo "# jmap -heap $PGID" >> ${THREAD_DUMP_LOGPATH}
jmap -heap $PGID>> ${THREAD_DUMP_LOGPATH}
echo "---JVM����ϢEnd---" >>${THREAD_DUMP_LOGPATH}
echo -e "\n\n" >>${THREAD_DUMP_LOGPATH}

# JVM�̶߳�ջ��Ϣ
echo "---JVM THREAD DUMP ��ϢStart---"  >>${THREAD_DUMP_LOGPATH}
echo "# jstack -F ${PGID}" >>${THREAD_DUMP_LOGPATH}
jstack -F ${PGID} >>${THREAD_DUMP_LOGPATH}
echo "Location:${THREAD_DUMP_LOGPATH}" >>${THREAD_DUMP_LOGPATH}
echo "---JVM THREAD DUMP ��ϢEnd---" >>${THREAD_DUMP_LOGPATH}
echo -e "\n\n" >>${THREAD_DUMP_LOGPATH}

# �߳���Ϣ
for((i=1;i<=${MAX_GET_CNT};i++));do
	if [ $i -lt 10 ];then
		i="0${i}"
	fi
	echo "---�߳���Ϣ ${i}-Start---" >>${THREAD_DUMP_LOGPATH}
	echo "# top -Hp ${PGID} -d 1 -n 3 " >> ${THREAD_DUMP_LOGPATH}
	top -Hp ${PGID} -d 1 -n 3 >>${THREAD_DUMP_LOGPATH}
	echo "---�߳���Ϣ ${i}-End---"  >>${THREAD_DUMP_LOGPATH}
	sleep 1
done

#### JVM����Ϣ�������� ####
jmap -dump:format=b,file=${HEAP_DUMP_LOGPATH} $PGID

chmod 755 ${LOG_DIRROOT} -R

echo "###################################################"
echo "[SUMMARY]:"
echo "###################################################"
echo "PID: ${PGID}"
echo "DUMPDIR: ${LOG_DIRROOT}"
echo "RUN_ENV_LOG: ${OS_INFO_LOGPATH}"
echo "THREAD_DUMP_LOG: ${THREAD_DUMP_LOGPATH}"
echo "HEAP_DUMP_LOG: ${HEAP_DUMP_LOGPATH}"