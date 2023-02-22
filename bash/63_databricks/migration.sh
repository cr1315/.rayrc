#!/usr/bin/env bash

## define members array
declare -a target_user_emails
target_user_emails=("" "")

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
    databricks_user=$(curl -s --netrc -G --data-urlencode "filter=userName sw ${target_user_email}" "https://accounts.cloud.databricks.com/api/2.0/accounts/${TF_VAR_databricks_nszd_mws_account_id}/scim/v2/Users")
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