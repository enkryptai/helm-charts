#!/bin/sh

# This script is used to setup the initial internal Kong admin consumer if it does not exist
# It needs curl to call the Kong Admin API. Hence, creating a custom entrypoint script and custom Dockerfile

# Check if curl is installed
if ! command -v curl >/dev/null 2>&1; then
  echo "curl is not installed. Please install curl and rerun the script."
  exit 1
fi

# ---------------------------------------------------------
# Internal Kong admin user setup
# ---------------------------------------------------------

# Check if the internal Kong admin user exists
checkInternalUserResponse=$(curl -s -o /dev/null -w "%{http_code}" $DECK_KONG_ADDR/consumers/$DECK_INTERNAL_KONG_ADMIN_EMAIL)

echo "GET existing internal consumer response: $checkInternalUserResponse"

# Flag to check if existing basic auth credentials need to be checked
CheckInternalUserBasicAuth=false

# Flag to check if basic auth credentials need to be created
CreateInternalUserBasicAuth=false

# If the user does not exist, create the internal Kong admin user
if [ "$checkInternalUserResponse" -eq 404 ]; then
  echo "Creating the internal Kong admin user..."

  createInternalUserResponse=$(curl -s -o /dev/null -w "%{http_code}" -i -X POST $DECK_KONG_ADDR/consumers/ --data "{\"username\":\"$DECK_INTERNAL_KONG_ADMIN_EMAIL\"}" --header "Content-Type: application/json")

  echo "POST internal consumer creation response: $createInternalUserResponse"

  if [ "$createInternalUserResponse" -eq 201 ]; then
    CreateInternalUserBasicAuth=true
    echo "The internal Kong admin user has been created successfully."
  else
    echo "An error occurred while creating the internal Kong admin user. HTTP code: $createInternalUserResponse"
    exit 1
  fi

elif [ "$checkInternalUserResponse" -eq 200 ]; then
  CheckInternalUserBasicAuth=true
  echo "The internal Kong admin user already exists."
else
  echo "An error occurred while checking the internal Kong admin user. Please check the issue and rerun the script."
fi

if [ "$CheckInternalUserBasicAuth" = true ]; then
  # Check if basic-auth credentials exist
  internalUserCredentialsResponse=$(curl -s --write-out "\n%{http_code}" -X GET "$DECK_KONG_ADDR/consumers/$DECK_INTERNAL_KONG_ADMIN_EMAIL/basic-auth")
  # Extract HTTP code (last line)
  checkInternalUserBasicAuthResponseCode=$(echo "$internalUserCredentialsResponse" | tail -n1)
  # Extract JSON body (everything except last line)
  checkInternalUserBasicAuthResponseBody=$(echo "$internalUserCredentialsResponse" | sed '$d')

  echo "GET basic-auth credentials response: $checkInternalUserBasicAuthResponseCode"
  # NOTE: Below logs sensitive info, uncomment only for debugging
  # echo "GET basic-auth credentials response body: $checkInternalUserBasicAuthResponseBody"

  if [ "$checkInternalUserBasicAuthResponseCode" -eq 200 ]; then
    if [ -z "$checkInternalUserBasicAuthResponseBody" ]; then
      echo "Error: Empty response body"
      exit 1
    fi

    # Get length of data array
    # Example empty response: {"next":null,"data":[]}
    # Example non-empty response: {"next":null,"data":[{"created_at":1731176797,...]}
    credentailsLength=$(echo "$checkInternalUserBasicAuthResponseBody" | jq -e -r '(.data | length)' 2>/dev/null)
    jq_exit=$?

    if [ $jq_exit -ne 0 ]; then
      echo "Error: Invalid JSON response or missing .data array"
      echo "Response was: $checkInternalUserBasicAuthResponseBody"
      exit 1
    fi

    echo "Found $credentailsLength credential entries"

    if [ "$credentailsLength" -ge 1 ]; then
      echo "Basic-auth credentials were already created for internal user."
    else
      CreateInternalUserBasicAuth=true
      echo "No basic-auth credentials found for internal user. Need to create them."
    fi

  else
    echo "Failed to check basic-auth credentials. HTTP code: $checkInternalUserBasicAuthResponseCode"
    exit 1
  fi
fi

if [ "$CreateInternalUserBasicAuth" = true ]; then
  echo "Creating basic auth credentials for the internal Kong admin user..."

  # Configure basic auth creds for the consumer
  createInternalUserAuthResponse=$(curl -s -o /dev/null -w "%{http_code}" -i -X POST $DECK_KONG_ADDR/consumers/$DECK_INTERNAL_KONG_ADMIN_EMAIL/basic-auth --data "{\"username\":\"$DECK_INTERNAL_KONG_ADMIN_USERNAME\",\"password\":\"$DECK_INTERNAL_KONG_ADMIN_PASSWORD\"}" --header "Content-Type: application/json")

  echo "POST internal consumer basic auth creation response: $createInternalUserAuthResponse"

  if [ "$createInternalUserAuthResponse" -eq 201 ]; then
    echo "The internal Kong admin user basic auth has been created."
  else
    echo "An error occurred while creating the internal Kong admin user basic auth. Please check the issue and rerun the script."
    exit 1
  fi
fi

# ---------------------------------------------------------
# Public Leaderboard user setup
# ---------------------------------------------------------

# Check if the public Leaderboard user exists
checkLeaderboardUserResponse=$(curl -s -o /dev/null -w "%{http_code}" $DECK_KONG_ADDR/consumers/$DECK_LEADERBOARD_PUBLIC_CONSUMER_EMAIL)

echo "GET existing Leaderboard consumer response: $checkLeaderboardUserResponse"

# Flag to check if existing key auth credentials need to be checked
CheckLeaderboardUserKeyAuth=false

# Flag to check if key auth credentials need to be created
CreateLeaderboardUserKeyAuth=false

# If the user does not exist, create the public Leaderboard user
if [ "$checkLeaderboardUserResponse" -eq 404 ]; then
  echo "Creating the public Leaderboard user..."

  createLeaderboardUserResponse=$(curl -s -o /dev/null -w "%{http_code}" -i -X POST $DECK_KONG_ADDR/consumers/ --data "{\"username\":\"$DECK_LEADERBOARD_PUBLIC_CONSUMER_EMAIL\"}" --header "Content-Type: application/json")

  echo "POST Leaderboard consumer creation response: $createLeaderboardUserResponse"

  if [ "$createLeaderboardUserResponse" -eq 201 ]; then
    CreateLeaderboardUserKeyAuth=true
    echo "The public Leaderboard user has been created successfully."
  else
    echo "An error occurred while creating the public Leaderboard user. HTTP code: $createLeaderboardUserResponse"
    exit 1
  fi

elif [ "$checkLeaderboardUserResponse" -eq 200 ]; then
  CheckLeaderboardUserKeyAuth=true
  echo "The public Leaderboard user already exists."
else
  echo "An error occurred while checking the public Leaderboard user. Please check the issue and rerun the script."
fi

if [ "$CheckLeaderboardUserKeyAuth" = true ]; then
  # Check if key-auth credentials exist
  leaderboardUser=$(curl -s --write-out "\n%{http_code}" -X GET "$DECK_KONG_ADDR/consumers/$DECK_LEADERBOARD_PUBLIC_CONSUMER_EMAIL/key-auth")
  # Extract HTTP code (last line)
  checkLeaderboardUserKeyAuthResponseCode=$(echo "$leaderboardUser" | tail -n1)
  # Extract JSON body (everything except last line)
  checkLeaderboardUserKeyAuthResponseBody=$(echo "$leaderboardUser" | sed '$d')

  echo "GET key-auth credentials response: $checkLeaderboardUserKeyAuthResponseCode"
  # NOTE: Below logs sensitive info, uncomment only for debugging
  # echo "GET key-auth credentials response body: $checkLeaderboardUserKeyAuthResponseBody"

  if [ "$checkLeaderboardUserKeyAuthResponseCode" -eq 200 ]; then
    if [ -z "$checkLeaderboardUserKeyAuthResponseBody" ]; then
      echo "Error: Empty response body"
      exit 1
    fi

    # Get length of data array
    # Example empty response: {"next":null,"data":[]}
    # Example non-empty response: {"next":null,"data":[{"created_at":1731176797,...]}
    credentailsLength=$(echo "$checkLeaderboardUserKeyAuthResponseBody" | jq -e -r '(.data | length)' 2>/dev/null)
    jq_exit=$?

    if [ $jq_exit -ne 0 ]; then
      echo "Error: Invalid JSON response or missing .data array"
      echo "Response was: $checkLeaderboardUserKeyAuthResponseBody"
      exit 1
    fi

    echo "Found $credentailsLength credential entries"

    if [ "$credentailsLength" -ge 1 ]; then
      echo "key-auth credentials were already created for public Leaderboard user."
    else
      CreateLeaderboardUserKeyAuth=true
      echo "No key-auth credentials found for public Leaderboard user. Need to create them."
    fi

  else
    echo "Failed to check key-auth credentials. HTTP code: $checkLeaderboardUserKeyAuthResponseCode"
    exit 1
  fi
fi

if [ "$CreateLeaderboardUserKeyAuth" = true ]; then
  echo "Creating key auth credentials for the public Leaderboard user..."

  # Configure key auth creds for the consumer
  createLeaderboardUserAuthResponse=$(curl -s -o /dev/null -w "%{http_code}" -i -X POST $DECK_KONG_ADDR/consumers/$DECK_LEADERBOARD_PUBLIC_CONSUMER_EMAIL/key-auth --data "{\"key\":\"$DECK_LEADERBOARD_PUBLIC_CONSUMER_API_KEY\"}" --header "Content-Type: application/json")

  echo "POST Leaderboard consumer key auth creation response: $createLeaderboardUserAuthResponse"

  if [ "$createLeaderboardUserAuthResponse" -eq 201 ]; then
    echo "The public Leaderboard user key auth has been created."
  else
    echo "An error occurred while creating the public Leaderboard user key auth. Please check the issue and rerun the script."
    exit 1
  fi
fi

# ---------------------------------------------------------
# Deck sync Kong configuration
# ---------------------------------------------------------

echo "Syncing the Kong configuration..."

# Pre-sync: verify deck can read Kong's current state.
# deck gateway dump can fail due to transient Kong Admin API 500 errors
# (e.g. on /snis). If the dump fails, sync treats all services as new
# and attempts to CREATE them, causing 409 UNIQUE violation errors.
MAX_DUMP_RETRIES=3
DUMP_RETRY=0
DUMP_OK=false

while [ $DUMP_RETRY -lt $MAX_DUMP_RETRIES ]; do
  if deck gateway dump --skip-consumers -o - >/dev/null 2>/dev/null; then
    DUMP_OK=true
    break
  fi
  DUMP_RETRY=$((DUMP_RETRY + 1))
  echo "deck gateway dump failed (attempt $DUMP_RETRY/$MAX_DUMP_RETRIES). Retrying in 10 seconds..."
  sleep 10
done

if [ "$DUMP_OK" = false ]; then
  echo "WARNING: deck gateway dump failed after $MAX_DUMP_RETRIES attempts. Diagnostic output:"
  deck gateway dump --skip-consumers -o - >/dev/null || true
  echo "Attempting sync anyway..."
fi

# Sync the Kong configuration with the Kong Gateway
# https://docs.konghq.com/deck/latest/reference/deck/
#: only manage tagged entities
# --parallelism 1: serialize API calls to reduce transient errors
deck gateway sync /mnt/deck/kong.yaml --skip-consumers --parallelism 1 --verbose 0

SYNC_EXIT_CODE=$?

# Retry once if sync fails (transient dump failure during sync)
if [ $SYNC_EXIT_CODE -ne 0 ]; then
  echo "Initial sync failed (exit code: $SYNC_EXIT_CODE). Retrying in 15 seconds..."
  sleep 15
  echo "Retrying deck sync with verbose logging..."
  deck gateway sync /mnt/deck/kong.yaml --skip-consumers --parallelism 1 --verbose 1
  SYNC_EXIT_CODE=$?
fi

if [ $SYNC_EXIT_CODE -eq 0 ]; then
  echo "Kong configuration sync completed successfully!"
else
  echo "Kong configuration sync failed with exit code $SYNC_EXIT_CODE. Please check the issue and rerun the script."
fi

echo "---------------------------------------------"
exit $?
