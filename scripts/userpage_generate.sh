#!/bin/bash

# This is the script to generate the index.  You should run this probably once per day, on a crontab.  I have it set to 2:30 AM, but that is completely arbitrary.  
# Make sure to modify EXCLUDED_USERS as need be, as well as the location of the output.  
# Further remember to set up your service account, so as to be able to kinit properly!  

set -euo pipefail

OUTPUT="/web/users/index.html"

# Users to explicitly exclude.
EXCLUDED_USERS=(
    "cifai"
    "gatekeeper"
    "nextcloud"
    "admin"
    "failsafe_admin"
    "gosha-auth"
    "ldap-bind"
    "ttest"
    "nginx"
    "cerberus"
    "mkhome"
    "applications_service"
    "guacamole"
    "ipa-auth"
    "nfs"
    "portal"
    "printlog"
)

echo "YOU_SHALL_NOT_PASS" | kinit gatekeeper

declare -A DISABLED_USERS

while IFS=$'\t' read -r username locked; do
    if [[ "$locked" == "TRUE" ]]; then
        DISABLED_USERS["$username"]=1
    fi
done < <(
    ipa user-find --all --raw --sizelimit=0 |
    awk '
        /^  uid: / {
            uid=$0
            sub(/^  uid: /, "", uid)
        }

        /^  nsaccountlock: / {
            locked=$0
            sub(/^  nsaccountlock: /, "", locked)
            print uid "\t" locked
        }
    '
)

is_excluded() {
    local username="$1"

    for excluded in "${EXCLUDED_USERS[@]}"; do
        [[ "$username" == "$excluded" ]] && return 0
    done

    return 1
}

get_users() {
    local group="$1"

    ipa group-show "$group" --all --raw |
        awk -F'[=,]' '/^  member: uid=/ {print $2}' |
        sort -f |
        while IFS= read -r username; do
            if is_excluded "$username"; then
                continue
            fi
            if [[ -n "${DISABLED_USERS[$username]+x}" ]]; then
                continue
            fi
            echo "$username"
        done
}

generate_section() {
    local group="$1"
    local title="$2"
    echo "<section>"
    echo "    <h2>$title</h2>"
    echo "    <ul>"
    get_users "$group" | while IFS= read -r username; do
        echo "        <li><a href=\"/users/$username/\">$username</a></li>"
    done
    echo "    </ul>"
    echo "</section>"
}

mkdir -p "$(dirname "$OUTPUT")"

{
    cat <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>CIF User Webpages</title>
    <style>
        html, body {
            margin: 0;
            padding: 0;
            min-height: 100%;
            background-color: #0f0f0f;
            color: #ffffff;
            font-size: 18px;
            font-family: "Courier New", Courier, monospace;
            line-height: 1.6;
        }
        #root {
            width: 90%;
            max-width: 980px;
            margin: 0 auto;
            padding: 30px 20px;
        }
        .post {
            margin: 30px auto;
            max-width: 980px;
            padding: 30px 35px;
            background-color: #151515;
            border: 2px solid #00ff00;
            border-radius: 24px;
            box-shadow: 0 0 15px rgba(0, 0, 0, 0.8);
        }
        .post-date {
            margin-bottom: 20px;
            padding-bottom: 10px;
            color: #00ff00;
            font-size: 0.9rem;
            border-bottom: 1px solid #006600;
        }
        h1, h2, h3 {
            color: #00ff00;
            line-height: 1.3;
            margin-top: 0;
        }
        h1 {
            font-size: 1.8rem;
            border-bottom: 2px solid #006600;
            padding-bottom: 10px;
        }
        section {
            margin-top: 25px;
        }
        h2 {
            font-size: 1.2rem;
            border-bottom: 1px solid #006600;
            padding-bottom: 6px;
        }
        ul {
            columns: 3;
            column-gap: 3rem;
            padding-left: 1.5rem;
        }
        li {
            margin: 0.4rem 0;
            break-inside: avoid;
        }
        a {
            color: #FFFFFF;
            font-weight: bold;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
        #header {
            margin-bottom: 25px;
            text-align: center;
            color: #00ff00;
        }
        #header-title {
            font-size: 1.8rem;
            font-weight: bold;
            margin-bottom: 5px;
        }
        .btn {
            display: inline-block;
            background-color: #00ff00;
            color: #0f0f0f;
            padding: 10px 22px;
            font-family: "Courier New", Courier, monospace;
            font-weight: bold;
            font-size: 0.95rem;
            border: none;
            border-radius: 12px;
            cursor: pointer;
            text-transform: uppercase;
            text-decoration: none;
            margin-top: 25px;
            transition: all 0.2s ease;
        }
        .btn:hover {
            background-color: #00cc00;
        }
        @media screen and (max-width: 700px) {
            ul {
                columns: 1;
            }
            #root {
                width: 95%;
                padding: 15px 5px;
            }
        }
    </style>
</head>

<body>
<div id="root">
    <div id="header">
        <div id="header-title">Computer Interest Floor (CIF)</div>
    </div>

<article class="post">
    <h1>CIF User Webpages (Roundtable User Webpages)</h1>
    <center><p>Explore personal webpages hosted by members of the CIF community!</p></center>
    <center><p>The views, opinions and material expressed on these webpages are those of the author and have not been reviewed or approved by the University of Rochester, or by the Computer Interest Floor.</p></center>
EOF
    generate_section "cif_board" "CIF Board"
    generate_section "cif_members" "CIF Members"
    generate_section "ipausers" "CIF Lab Members"
    cat <<'EOF'
</article>
</div>
</body>
</html>
EOF
} > "$OUTPUT"

echo "Generated $OUTPUT"
