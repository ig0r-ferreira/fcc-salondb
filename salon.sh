#!/bin/bash
PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"
echo -e "\n~~~~~ MY SALON ~~~~~\n"
echo -e "Welcome to My Salon, how can I help you?\n"


ASK_SERVICE() {
    if [[ $1 ]]
    then
        echo -e $1
    fi
    echo "$($PSQL "SELECT * FROM services ORDER BY service_id")" | while read SERVICE_ID BAR SERVICE_NAME
    do
        echo "$SERVICE_ID) $SERVICE_NAME"
    done
    echo -e -n "\nEnter a option: "
    read SERVICE_ID_SELECTED
    if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
    then
        ASK_SERVICE 'Please enter a number.\n'
    fi
}

ASK_NAME() {
    echo -e -n "$1"
    read CUSTOMER_NAME
    if [[ -z $CUSTOMER_NAME ]]
    then
        ASK_NAME "Please enter your name: "
    fi
}

ASK_PHONE() {
    echo -e -n "$1"
    read CUSTOMER_PHONE
    if [[ -z $CUSTOMER_PHONE ]]
    then
        ASK_PHONE "Please enter your phone number: "
    fi
}

ASK_TIME() {
    echo -e -n "$1"
    read SERVICE_TIME
    if [[ -z $SERVICE_TIME ]]
    then
        ASK_TIME "Please enter service time: "
    fi
}

MAIN() {
    ASK_SERVICE "$@"
    SERVICE_ID_SELECTED=$($PSQL "SELECT service_id FROM services WHERE service_id=$SERVICE_ID_SELECTED")
    if [[ -z $SERVICE_ID_SELECTED ]]
    then
        MAIN "I could not find that service. What would you like today?\n"
    else
        ASK_PHONE "\nWhat's your phone number? "

        CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
        if [[ -z $CUSTOMER_ID ]]
        then
            ASK_NAME "\nI don't have a record for that phone number, what's your name? "
            
            INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers (name, phone) VALUES ('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
            if [[ $INSERT_CUSTOMER_RESULT == "INSERT 0 1" ]]
            then
                CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
            fi
        else
            CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'")
        fi
    
        SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id='$SERVICE_ID_SELECTED';")
        ASK_TIME "\nWhat time would you like your $(echo $SERVICE_NAME), $(echo $CUSTOMER_NAME)? "

        INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")
        if [[ $INSERT_APPOINTMENT_RESULT == "INSERT 0 1" ]]
        then
            echo -e "\nI have put you down for a $(echo $SERVICE_NAME) at $SERVICE_TIME, $(echo $CUSTOMER_NAME)."
        else
            echo -e "\nUnable to schedule the service."
        fi
    fi
}

MAIN
