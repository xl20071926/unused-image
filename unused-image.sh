#!/bin/sh
# 清楚项目中的无用图片资源
# 使用方法：./unused-image.sh -r -p /path/of/your/project

PROGNAME=$(basename "$0")
PROGDIR=$(dirname "$0")

usage()
{
	echo "Usage: $PROGNAME  [option]  -p path-of-project"
	echo ""
	echo "-p          Specifyed the path of your project"
	echo "-r          Remove unused image file"
	echo "-h          Show this message"

	exit 1
}

PRJ_ROOT=$1
REMOVE=false
COUNT=0

#   如下用到的一些shell语法说明：
#   echo:表示打印
#   find:就是搜索语句
#   -O:表示或(or) -a:表示和(and)
#   $:用来对变量的引用
#   grep 是搜索内容， find 是搜索文件

###############################################################################################################################
####   用户输入命令判断, -p 后面输入工程路径  -r 是否删除
#   getopts 可以获取用户在命令下的参数，然后根据参数进行不同的提示或者不同的执行。
while getopts ":rp:" optname
  do
    case "$optname" in
      "p")
        echo "the program name is : $OPTARG"
        PRJ_ROOT=$OPTARG  # specifyed the project root
        ;;
      "r")
        REMOVE=true		  # remove unused image resource
        ;;
      "?")
        usage
        ;;
      ":")
        echo "No argument value for option $OPTARG"
        ;;
      *)
      # Should not occur
        echo "Unknown error while processing options"
        ;;
    esac
    #echo "OPTIND is now $OPTIND"
done

###############################################################################################################################
####   筛选要搜索的文件清单,将” /“替换成”~\n“, 后面会将文件名中的空格替换成”#“,目的是为了与文件名中的空格区分开处理,避免文件名中有空格则成为俩个文件的bug
check_files=`find $PRJ_ROOT -name '*.xib' -o -name '*.storyboard' -o -name '*.[mh]'  -o -name '*.pch' -o -name '*.java' -o -name '*.xml' -o -name '*.xcodeproj' -o -name '*.m'  -o -name '*.h'  -o -name '*.json'`
#   将变量check_files 写成Lee文件
echo $check_files>Lee
#   将” /“替换成”~\n“
check_files=`awk 'gsub(" /","~\n")' Lee| sed 's/^/\/&/g' | sed '1s#/##'`
#echo "----> $check_files <-----"

###############################################################################################################################
####   工程中的资源图片获取并对后缀进行处理
for png in `find $PRJ_ROOT -name '*.png'`
do
    # basename 取一个文件名（去掉后缀名)
    match_name=`basename $png`

    suffix1="@2x.png"
    suffix2=".9.png"
    suffix3=".png"
    suffix4="@3x.png"

    #   match_name 为去除后缀的图片名称
    if [[ ${match_name/${suffix1}//} != $match_name ]]; then
      match_name=${match_name%$suffix1}
    elif [[ ${match_name/${suffix4}//} != $match_name ]]; then
   		match_name=${match_name%$suffix4}
   	elif [[ ${match_name/${suffix2}//} != $match_name ]]; then
   		match_name=${match_name%$suffix2}
    else
    	match_name=${match_name%$suffix3}
    fi
    #   echo "=========  果：$match_name =========="

    #   dirname 取一个文件存储路径
    dir_name=`dirname $png`
    #   echo "dir name : $dir_name"
    if [[ $dir_name =~ .bundle$ ]] || [[ $dir_name =~ .appiconset$ ]] || [[ $dir_name =~ .launchimage$ ]]; then
      continue
    fi

###############################################################################################################################
####    在搜索清单中搜索png图片是否被使用
    referenced=false
    #   格式：sed 's/要替换的字符串/新的字符串/g'   （要替换的字符串可以用正则表达式）.其中g代表所有，如果不加g，如果文件名字中有多个空格，仅替换第一个。
    #   tr "stringold" "stringnew" 也是替换的功能
    #   将文件名中的空格替换成#号
    check_files=`echo $check_files | sed 's/ /#/g'`
    #    echo "----- #####  $check_files   ##### --------"

    #   将文件之间的空格还原
    for file in `echo $check_files | sed 's/~#/ /g' `
    do
        #   再将文件名的空格还原
        file=`echo $file | sed 's/#/ /g'`
  	    if  grep -sqh "$match_name" "$file"; then
  	        referenced=true
  	    fi
  	done

###############################################################################################################################
####    搜索结果显示及删除处理
  	if ! $referenced ; then
  		echo "The '$png' was not referenced in any file,图片未被使用"
  		COUNT=`expr $COUNT + 1`
  		if $REMOVE ; then
  			echo "Do remove unused image file '$png',删除未使用的图片"
  			rm -f $png
  		fi
  	fi

done

echo "============= Total $COUNT unused image files ============="








