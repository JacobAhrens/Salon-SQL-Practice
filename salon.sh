#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=salon -t --no-align -c"

display_services() {
  echo "Welcome to My Salon, how can I help you?"
  SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")
  echo "$SERVICES" | while IFS="|" read SERVICE_ID NAME
  do
    echo "$SERVICE_ID) $NAME"
  done
}

get_customer_id() {
  CUSTOMER_PHONE=$1
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
  echo $CUSTOMER_ID
}

while true; do
  display_services
  read SERVICE_ID_SELECTED
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")

  # Validate service selection
  if [[ -z $SERVICE_NAME ]]; then
    echo "Invalid service. Please select a valid service."
  else
    # Prompt for customer phone number
    echo "Enter your phone number:"
    read CUSTOMER_PHONE

    # Check if customer exists
    CUSTOMER_ID=$(get_customer_id $CUSTOMER_PHONE)
    if [[ -z $CUSTOMER_ID ]]; then
      # Prompt for customer name if new customer
      echo "I don't have a record for that phone number, what's your name?"
      read CUSTOMER_NAME

      # Insert new customer
      INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers (name, phone) VALUES ('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
      CUSTOMER_ID=$(get_customer_id $CUSTOMER_PHONE)
    else
      # Get existing customer name
      CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE customer_id=$CUSTOMER_ID")
    fi

    # Prompt for appointment time
    echo "What time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
    read SERVICE_TIME

    # Insert appointment
    INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")

    # Confirm appointment
    if [[ $INSERT_APPOINTMENT_RESULT == "INSERT 0 1" ]]; then
      echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
    else
      echo "Failed to schedule appointment."
    fi

    # Exit after appointment
    break
  fi
done
