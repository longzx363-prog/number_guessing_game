#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# 生成 1 到 1000 之间的随机数
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# 使用 read -p 确保测试框架能准确捕获提示语
read -p "Enter your username: " USERNAME

# 查询数据库中是否存在该用户
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME';")

if [[ -z $USER_ID ]]
then
  # 新用户逻辑
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME');")
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  # 老用户逻辑
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE user_id=$USER_ID;")
  BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE user_id=$USER_ID;")
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# 猜数字提示
echo "Guess the secret number between 1 and 1000:"
GUESS_COUNT=0
GUESS=0

while [[ $GUESS -ne $SECRET_NUMBER ]]
do
  read GUESS
  
  # 验证输入是否为整数
  if ! [[ $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi

  ((GUESS_COUNT++))

  if [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
  elif [[ $GUESS -lt $SECRET_NUMBER ]]
  then
    echo "It's higher than that, guess again:"
  else
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
  fi
done

# 确保获取到用户 ID
if [[ -z $USER_ID ]]
then
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME';")
fi

# 更新数据库中的游戏统计数据
CURRENT_GAMES=$($PSQL "SELECT games_played FROM users WHERE user_id=$USER_ID;")
NEW_GAMES=$((CURRENT_GAMES + 1))

CURRENT_BEST=$($PSQL "SELECT best_game FROM users WHERE user_id=$USER_ID;")
if [[ -z $CURRENT_BEST ]] || [[ $GUESS_COUNT -lt $CURRENT_BEST ]]
then
  NEW_BEST=$GUESS_COUNT
else
  NEW_BEST=$CURRENT_BEST
fi

UPDATE_RESULT=$($PSQL "UPDATE users SET games_played=$NEW_GAMES, best_game=$NEW_BEST WHERE user_id=$USER_ID;")
