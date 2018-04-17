#!/bin/bash

#   BAREOS® - Backup Archiving REcovery Open Sourced
#
#   Copyright (C) 2017-2017 Bareos GmbH & Co. KG
#
#   This program is Free Software; you can redistribute it and/or
#   modify it under the terms of version three of the GNU Affero General Public
#   License as published by the Free Software Foundation and included
#   in the file LICENSE.
#
#   This program is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
#   Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
#   02110-1301, USA.


DATABASES="sqlite postgresql mysql"
QUERY_NAMES_FILE="../bdb_query_names.inc"
QUERY_ENUM_FILE="../bdb_query_enum_class.h"

#DATE=`date '+%F %T'`
NOTE="/* autogenerated file by $0 */"

upper()
{
    tr "a-z" "A-Z" <<< "$1"
}

get_query_include_filename()
{
    printf "../%s_queries.inc" "$1"
}

#
# file header
#
> $QUERY_NAMES_FILE
printf "%s\n\n" "$NOTE" >> $QUERY_NAMES_FILE
printf "const char *BareosDb::query_names[] = {\n" >> $QUERY_NAMES_FILE

> $QUERY_ENUM_FILE
printf "%s\n\n" "$NOTE" >> $QUERY_ENUM_FILE
cat >> $QUERY_ENUM_FILE << EOF
class BareosDbQueryEnum {
public:
   typedef enum {
EOF


for db in $DATABASES; do
    DB=`upper $db`
    queryincludefile=`get_query_include_filename $db`
    > $queryincludefile
    printf "%s\n\n" "$NOTE" >> $queryincludefile
    printf "const char *B_DB_%s::query_definitions[] = {\n" "$DB" >> $queryincludefile
done

#
# file data
#
let i=0
for query in `ls ????_* | sed 's#\..*##g' | sort | uniq`; do
    queryname=`sed 's/[0-9]*_//' <<< $query`
    printf '"%s",\n' "$queryname" >> $QUERY_NAMES_FILE
    printf "      SQL_QUERY_%s = %s,\n" "$queryname" "$i" >> $QUERY_ENUM_FILE
    let i++

    for db in $DATABASES; do
        queryincludefile=`get_query_include_filename $db`
        queryfile="$query"
        if  [ -e "$query.$db" ]; then
            queryfile="$query.$db"
        fi
        printf "/* %s */\n" "$queryfile" >> $queryincludefile
        # remove comments and empty lines, add quotes on each line
        cat "$queryfile" | sed -r -e "/^#/d" -e "/^$/d" -e 's/^(\s*)/\1"/' -e 's/\s*$/ "/' >> $queryincludefile
        printf ',\n\n' >> $queryincludefile
    done
done

#
# file footer
#
printf "NULL\n};\n" >> $QUERY_NAMES_FILE

cat >> $QUERY_ENUM_FILE << EOF
      SQL_QUERY_NUMBER = $i
   } SQL_QUERY_ENUM;
};
EOF

for db in $DATABASES; do
    queryincludefile=`get_query_include_filename $db`
    printf "NULL\n};\n" >> $queryincludefile
done
