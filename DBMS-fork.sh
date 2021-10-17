#!/bin/bash
mkdir DBMS 2>> ./.fail.log
clear
echo "welcome to DBMS"
function mainMenu {
  echo -e "\n Main Menu"
  echo " (1). Select DB"
  echo " (2). Create DB"
  echo " (3). Drop DB"
  echo " (4). Show DBs"
  echo " (5). Exit"
  echo " (6). Logout"
  echo " ********************"
  echo -e "enter choice: \c"
  read ch
  case $ch in
    1)  selectDB ;;
    2)  createDB ;;
    3)  renameDB ;;
    4)  dropDB ;;
    5)  ls ./DBMS ; mainMenu;;
    6) exit ;;
    *) echo " wrong choice " ; mainMenu;
  esac
}

function selectDB {
  echo -e "enter database name: \c"
  read dbName
  cd ./DBMS/$dbName 2>>./.fail.log
  if [[ $? == 0 ]]; then
    echo "Database $dbName was successfully selected"
    tablesMenu
  else
    echo "database $dbName wasn't found"
    mainMenu
  fi
}

function createDB {
  echo -e "enter database name: \c"
  read dbName
  mkdir ./DBMS/$dbName
  if [[ $? == 0 ]]
  then
    echo "Database connected {created} successfully"
  else
    echo "Error connected {created} Database $dbName"
  fi
  tablesMenu
}


function dropDB {
  echo -e "Enter Database Name: \c"
  read dbName
  rm -r ./DBMS/$dbName 2>>./.fail.log
  if [[ $? == 0 ]]; then
    echo "database dropped successfully"
  else
    echo "database not found"
  fi
  mainMenu
}

function tablesMenu {
  echo -e "\n Tables Menu "
  echo " (1). show existing tables       "
  echo " (2). create new table           "
  echo " (3). insert into table          "
  echo " (4). select from table          "
  echo " (5). update table               "
  echo " (6). delete from table          "
  echo " (7). drop table                 "
  echo " (8). back to main menu          "
  echo " (9). Exit                       "
  echo "*****************"
  echo -e "enter choice: \c"
  read ch
  case $ch in
    1)  ls .; tablesMenu ;;
    2)  createTable ;;
    3)  insert;;
    4)  clear; selectMenu ;;
    5)  updateTable;;
    6)  deleteFromTable;;
    7)  dropTable;;
    8) clear; cd ../.. 2>>./.fail.log; mainMenu ;;
    9) exit ;;
    *) echo " wrong choice " ; tablesMenu;
  esac

}

function createTable {
  echo -e "what is the table name? : \c"
  read tableName
  if [[ -f $tableName ]]; then
    echo "table already exist , choose another name"
    tablesMenu
  fi
  echo -e "number of columns: \c"
  read colsNum
  counter=1
  sep="|"
  rSep="\n"
  pKey=""
  metaData="field"$sep"type"$sep"key"
  while [ $counter -le $colsNum ]
  do
    echo -e "name of column no.$counter: \c"
    read colName

    echo -e "type of column $colName: "
    select var in "int" "str"
    do
      case $var in
        int ) colType="int";break;;
        str ) colType="str";break;;
        * ) echo "wrong choice" ;;
      esac
    done
    if [[ $pKey == "" ]]; then
      echo -e "make primaryKey ? "
      select var in "yes" "no"
      do
        case $var in
          yes ) pKey="PK";
          metaData+=$rSep$colName$sep$colType$sep$pKey;
          break;;
          no )
          metaData+=$rSep$colName$sep$colType$sep""
          break;;
          * ) echo "wrong choice" ;;
        esac
      done
    else
      metaData+=$rSep$colName$sep$colType$sep""
    fi
    if [[ $counter == $colsNum ]]; then
      temp=$temp$colName
    else
      temp=$temp$colName$sep
    fi
    ((counter++))
  done
  touch .$tableName
  echo -e $metaData  >> .$tableName
  touch $tableName
  echo -e $temp >> $tableName
  if [[ $? == 0 ]]
  then
    echo "table created successfully"
    tablesMenu
  else
    echo "error creating table $tableName"
    tablesMenu
  fi
}

function dropTable {
  echo -e "Enter Table Name: \c"
  read tName
  rm $tName .$tName 2>>./.fail.log
  if [[ $? == 0 ]]
  then
    echo "Table Dropped Successfully"
  else
    echo "Error Dropping Table $tName"
  fi
  tablesMenu
}

function insert {
  echo -e "table name: \c"
  read tableName
  if ! [[ -f $tableName ]]; then
    echo "Table $tableName isn't existed, choose another table"
    tablesMenu
  fi
  colsNum=`awk 'END{print NR}' .$tableName`
  sep="|"
  rSep="\n"
  for (( i = 2; i <= $colsNum; i++ )); do
    colName=$(awk 'BEGIN{FS="|"}{ if(NR=='$i') print $1}' .$tableName)
    colType=$( awk 'BEGIN{FS="|"}{if(NR=='$i') print $2}' .$tableName)
    colKey=$( awk 'BEGIN{FS="|"}{if(NR=='$i') print $3}' .$tableName)
    echo -e "$colName ($colType) = \c"
    read data

    # Validate Input
    if [[ $colType == "int" ]]; then
      while ! [[ $data =~ ^[0-9]*$ ]]; do
        echo -e "plz enter a valid integer"
        echo -e "$colName ($colType) = \c"
        read data
      done
    fi

    if [[ $colKey == "PK" ]]; then
      while [[ true ]]; do
        if [[ $data =~ ^[`awk 'BEGIN{FS="|" ; ORS=" "}{if(NR != 1)print $(('$i'-1))}' $tableName`]$ ]]; then
          echo -e "plz enter a valid pk "
        else
          break;
        fi
        echo -e "$colName ($colType) = \c"
        read data
      done
    fi

    #Set row
    if [[ $i == $colsNum ]]; then
      row=$row$data$rSep
    else
      row=$row$data$sep
    fi
  done
  echo -e $row"\c" >> $tableName
  if [[ $? == 0 ]]
  then
    echo "Data Inserted Successfully with $colsNum record  "
  else
    echo "error in insertion data at $tableName"
  fi
  row=""
  tablesMenu
}

function updateTable {
  echo -e "enter table name:- \c"
  read tName
  echo -e "enter current structure column:- \c"
  read field
  fid=$(awk 'BEGIN{FS="|"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$field'") print i}}}' $tName)
  if [[ $fid == "" ]]
  then
    echo "not found"
    tablesMenu
  else
    echo -e "enter current value:- \c"
    read val
    res=$(awk 'BEGIN{FS="|"}{if ($'$fid'=="'$val'") print $'$fid'}' $tName 2>>./.fail.log)
    if [[ $res == "" ]]
    then
      echo "value not found"
      tablesMenu
    else
      echo -e "enter field structure name to set new value:- \c"
      read setField
      setFid=$(awk 'BEGIN{FS="|"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$setField'") print i}}}' $tName)
      if [[ $setFid == "" ]]
      then
        echo "not found"
        tablesMenu
      else
        echo -e "enter new value to set new value:- \c"
        read newValue
        NR=$(awk 'BEGIN{FS="|"}{if ($'$fid' == "'$val'") print NR}' $tName 2>>./.fail.log)
        oldValue=$(awk 'BEGIN{FS="|"}{if(NR=='$NR'){for(i=1;i<=NF;i++){if(i=='$setFid') print $i}}}' $tName 2>>./.fail.log)
        echo $oldValue
        sed -i ''$NR's/'$oldValue'/'$newValue'/g' $tName 2>>./.fail.log
        echo "$field updated from $val to $newValue"
        tablesMenu
      fi
    fi
  fi
}

function deleteFromTable {
  echo -e "enter table name: \c"
  read tName
  echo -e "enter current column structure name: \c"
  read field
  fid=$(awk 'BEGIN{FS="|"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$field'") print i}}}' $tName)
  if [[ $fid == "" ]]
  then
    echo "not found"
    tablesMenu
  else
    echo -e "Enter current field value: \c"
    read val
    res=$(awk 'BEGIN{FS="|"}{if ($'$fid'=="'$val'") print $'$fid'}' $tName 2>>./.fail.log)
    if [[ $res == "" ]]
    then
      echo "value not found"
      tablesMenu
    else
      NR=$(awk 'BEGIN{FS="|"}{if ($'$fid'=="'$val'") print NR}' $tName 2>>./.fail.log)
      sed -i ''$NR'd' $tName 2>>./.fail.log
      echo "row deleted"
      tablesMenu
    fi
  fi
}

function selectMenu {
  echo -e "\n\n+-Select Menu-"
  echo "(1) Select All Columns of a Table           "
  echo "(2) Select Specific Column from a Table     "
  echo "(3) Select From Table under condition       "  
  echo "(4) Back To Tables Menu                     "
  echo "(5) Back To Main Menu                       "
  echo "(6) Exit                                    "
  echo "*********************************************"
  echo -e "Enter your Choice: \c"
  read ch
  case $ch in
    1) selectAll ;;
    2) selectCol ;;
    3) clear; selectCon ;;
    4) clear; tablesMenu ;;
    5) clear; cd ../.. 2>>./.fail.log; mainMenu ;;
    6) exit ;;
    *) echo "  you select wrong Choice " ; selectMenu;
  esac
}

function selectAll {
  echo -e "Enter Table Name: \c"
  read tName
  column -t -s '|' $tName 2>>./.fail.log
  if [[ $? != 0 ]]
  then
    echo "Error in Display Table $tName"
  fi
  selectMenu
}

function selectCol {
  echo -e "Enter the Table Name: \c"
  read tName
  echo -e "Enter the Column Number: \c"
  read colNum
  awk 'BEGIN{FS="|"}{print $'$colNum'}' $tName
  selectMenu
}

function selectCon {
  echo -e "\n\n-Select Under Condition Menu-"
  echo "(1) Select All Columns Matching Condition    "
  echo "(2) Select Specific Column Matching Condition"
  echo "(3) Back To Selection Menu                   "
  echo "(4)Back To Main Menu                         "
  echo "(5)Exit                                      "
  echo "*********************************************"
  echo -e "Enter your Choice: \c"
  read ch
  case $ch in
    1) clear; allCond ;;
    2) clear; specCond ;;
    3) clear; selectCon ;;
    4) clear; cd ../.. 2>>./.fail.log; mainMenu ;;
    5) exit ;;
    *) echo " you select Wrong Choice " ; selectCon;
  esac
}

function allCond {
  echo -e "Select all columns from TABLE Where FIELD(operator)VALUE \n"
  echo -e "Enter the Table Name: \c"
  read tName
  echo -e "Enter the required FIELD name: \c"
  read field
  fid=$(awk 'BEGIN{FS="|"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$field'") print i}}}' $tName)
  if [[ $fid == "" ]]
  then
    echo "Not found"
    selectCon
  else
    echo -e "\select Operators: [==, !=, >, <, >=, <=]  \c"
    read op
    if [[ $op == "==" ]] || [[ $op == "!=" ]] || [[ $op == ">" ]] || [[ $op == "<" ]] || [[ $op == ">=" ]] || [[ $op == "<=" ]]
    then
      echo -e "\nEnter required VALUE: \c"
      read val
      res=$(awk 'BEGIN{FS="|"}{if ($'$fid$op$val') print $0}' $tName 2>>./.fail.log |  column -t -s '|')
      if [[ $res == "" ]]
      then
        echo "Value Not Found"
        selectCon
      else
        awk 'BEGIN{FS="|"}{if ($'$fid$op$val') print $0}' $tName 2>>./.fail.log |  column -t -s '|'
        selectCon
      fi
    else
      echo "wrong choice of Operator\n"
      selectCon
    fi
  fi
}

function specCond {
  echo -e "Select specific column from TABLE Where FIELD(operator)VALUE \n"
  echo -e "Enter the Table Name: \c"
  read tName
  echo -e "Enter your required FIELD name: \c"
  read field
  fid=$(awk 'BEGIN{FS="|"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$field'") print i}}}' $tName)
  if [[ $fid == "" ]]
  then
    echo "Not found"
    selectCon
  else
    echo -e "\n select Operators: [==, !=, >, <, >=, <=] \n \c"
    read op
    if [[ $op == "==" ]] || [[ $op == "!=" ]] || [[ $op == ">" ]] || [[ $op == "<" ]] || [[ $op == ">=" ]] || [[ $op == "<=" ]]
    then
      echo -e "\nEnter your required VALUE: \c"
      read val
      res=$(awk 'BEGIN{FS="|"; ORS="\n"}{if ($'$fid$op$val') print $'$fid'}' $tName 2>>./.fail.log |  column -t -s '|')
      if [[ $res == "" ]]
      then
        echo "value not found"
        selectCon
      else
        awk 'BEGIN{FS="|"; ORS="\n"}{if ($'$fid$op$val') print $'$fid'}' $tName 2>>./.fail.log |  column -t -s '|'
        selectCon
      fi
    else
      echo "wrong choice of Operator\n"
      selectCon
    fi
  fi
}

mainMenu
