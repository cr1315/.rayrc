#!/usr/bin/env bash

## define members array
declare -a target_user_emails
target_user_emails=("yuto.ohtsuka@accenture.com" "miho.b.tanaka@accenture.com")

##
main() {
    local target_user_email
    local databricks_user
    local databricks_user_id
    for target_user_email in "${target_user_emails[@]}"; do
        echo "## for user ${target_user_email}"

        databricks_user_id=$(get_databricks_user_id)
        generate_tf
    done
}

## get user info
get_databricks_user_id() {
    # echo "curl -s --netrc -G --data-urlencode 'filter=userName sw ${target_user_email}' 'https://dbc-cbb40dd7-5d7b.cloud.databricks.com/api/2.0/preview/scim/v2/Users'"
    databricks_user=$(curl -s --netrc -G --data-urlencode "filter=userName sw ${target_user_email}" 'https://accounts.cloud.databricks.com/api/2.0/accounts/99de7e02-45ef-4107-a953-488249935be6/scim/v2/Users')
    # echo "$databricks_user" | jq '.'

    ## TODO: try-catch
    databricks_user_id=$(echo "$databricks_user" | jq -r '.Resources[0].id')
    echo "$databricks_user_id"
}

## foreach member
generate_tf() {
    echo "tf state rm 'databricks_user.developer_members[\""${target_user_email}"\"]'"
    echo "tf import 'databricks_user.arch_admins[\""${target_user_email}"\"]' ${databricks_user_id}"
}

main "$@"