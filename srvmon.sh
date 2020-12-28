#!/bin/bash
# author: Remy van Elst - https://raymii.org
# license: gnu gpl v3

# Start of configuration.

#array names must not contain spaces, only a-ZA-Z.
declare -A urls # do not remove this line
urls[dilbert.com]="https://dilbert.com"
urls[gist.github.com]="https://gist.github.com"
urls[github.com]="https://github.com"
urls[lobste.rs]="https://lobste.rs"
urls[raymii.org]="https://raymii.org"
urls[treesforlife.org.uk]="https://treesforlife.org.uk"
urls[tweakers.net]="https://tweakers.net"
urls[www.buienradar.nl]="https://www.buienradar.nl"
urls[www.google.com]="https://www.google.com"
urls[www.smbc-comics.com]="https://www.smbc-comics.com"
urls[xkcd.com]="https://xkcd.com"

# The default status code. Can be overridden per URL lower in the script.
defaultExpectedStatusCode=200

# Expected code for url, key must match urls[]. Only for URL's you consider UP, but for example require authentication
declare -A statuscode # do not remove this line
statuscode[gist.github.com]=302

# How many curl checks to run at the same time
maxConcurrentCurls=12

# Max timeout of a check in seconds
defaultTimeOut=10

# Start of script. Do not edit below
# Exit immediately if a command exits with a non-zero status.
set -e
# patterns which match no files expand to a null string, otherwise later on we'd have *.status as a file...
shopt -s nullglob

# start of the function definitions

# This function allows the script to execute all the curl calls in paralell. 
# Otherwise, if one would timeout or take long, the rest after that would be
# slower. We're writing the status code to a file, reading that later on. Why? 
# Because an array cannot be filled via a subprocess (curl ... &)
doRequest() {
  name="${1}"
  url="${2}"
  checkStartTimeMs="$(date +%s%3N)" # epoch in microseconds, but last chars stripped so it's milliseconds
  set +e # curl errors don't count for early exit, turn off e
  checkStatusCode="$(curl --max-time "${defaultTimeOut}" --silent --show-error --insecure --output /dev/null --write-out "%{http_code}" "$url" --stderr "${tempfolder}/FAIL/${name}.error")"
  set -e # turn e back on
  checkEndTimeMs="$(date +%s%3N)"
  timeCheckTook="$((checkEndTimeMs-checkStartTimeMs))"

  expectedStatusCode=${defaultExpectedStatusCode}
  # check if there is a specific status code for this domain
  if [[ -n "${statuscode[${name}]}" ]]; then
    expectedStatusCode="${statuscode[${name}]}"
  fi 

  if [[ ${expectedStatusCode} -eq ${checkStatusCode} ]]; then
    echo "${timeCheckTook}" > "${tempfolder}/OK/${name}.duration"
  else
    echo "${checkStatusCode}" > "${tempfolder}/FAIL/${name}.status"
  fi

  # if the error file is empty, remove it.
  if [[ ! -s "${tempfolder}/FAIL/${name}.error" ]]; then
    rm "${tempfolder}/FAIL/${name}.error" 
  fi
}

writeOkayChecks() {
  echo "</div></div>"
  echo "<div class=row><div class=col>"
  echo "<h2>Checks</h2>"
  pushd "${tempfolder}/OK" >/dev/null 2>&1
  okFiles=(*.duration)
  okCount=${#okFiles[@]}
  if [[ okCount -gt 0 ]]; then
    for filename in "${okFiles[@]}"; do
      if [[ -r $filename ]]; then
        value="$(cat $filename)"
        filenameWithoutExt=${filename%.*}
        echo '<a href="#" class="btn btn-success disabled" tabindex="-1" role="button" aria-disabled="true" style="margin-top: 10px; padding: 10px;">'
        echo "${filenameWithoutExt}"
        echo "<font color=LightGray> ("
        echo ${value}
        echo " ms)</font>"
        echo "</a> &nbsp;"
      fi
    done
  fi
  popd >/dev/null 2>&1
}

writeFailedChecks() {
  pushd "${tempfolder}/FAIL" >/dev/null 2>&1
  failFiles=(*.status)
  failCount=${#failFiles[@]}
  if [[ failCount -gt 0 ]]; then
    echo '<div class="alert alert-danger" role="alert">'
    echo "Errors occured! ${failCount} check(s) have failed."
    echo "</div>"
    echo '<table class="table">'
    echo '<thead><tr>'
    echo '<th>Name</th>'
    echo '<th>HTTP Status/Expected</th>'
    echo '<th>Error</th>'
    echo '</tr></thead><tbody>'
    for filename in "${failFiles[@]}"; do
      if [[ -r $filename ]]; then
        filenameWithoutExt=${filename%.*}
        if [[ -r "${filenameWithoutExt}.error" ]]; then
          curlError="$(cat "${filenameWithoutExt}.error" 2>/dev/null)"
        else
          curlError="Status code does not match expected code"
        fi
        status="$(cat ${filename})"
        echo "<tr class='table-danger'><td>"
        echo "${filenameWithoutExt}"
        echo "</td><td>"
        echo "${status} / "
        if [[ -z "${statuscode[${filenameWithoutExt}]}" ]]; then
          echo "${defaultExpectedStatusCode}"
        else
          echo "${statuscode[${filenameWithoutExt}]}"
        fi
        echo "</td><td>"
        echo "${curlError}"
        echo "</td></tr>"
      fi
    done
    echo "</tbody></table>"
  else 
    echo '<div class="alert alert-success" role="alert">'
    echo "All is well, all services are up."
    echo "</div>"
  fi
  popd >/dev/null 2>&1
}

cleanupFailedCheckFiles() {
  pushd "${tempfolder}/FAIL" >/dev/null 2>&1
  errorFiles=(*.error)
  errorCount=${#errorFiles[@]}
  for filename in "${errorFiles[@]}"; do
    if [[ -r $filename ]]; then
      rm "${filename}"
    fi
  done

  statusFiles=(*.status)
  statusCount=${#statusFiles[@]}
  for filename in "${statusFiles[@]}"; do
    if [[ -r $filename ]]; then
      rm "${filename}"
    fi
  done
  popd >/dev/null 2>&1
  rmdir "${tempfolder}/FAIL"
}

cleanupOKCheckFiles() {
  pushd "${tempfolder}/OK" >/dev/null 2>&1
  okFiles=(*.duration)
  okCount=${#okFiles[@]}
  for filename in "${okFiles[@]}"; do
    if [[ -r $filename ]]; then
      rm "${filename}"
    fi
  done
  popd >/dev/null 2>&1
  rmdir "${tempfolder}/OK"
}


writeHeader() {
  echo '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">'
  echo '<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@4.5.3/dist/css/bootstrap.min.css" integrity="sha384-TX8t27EcRE3e/ihU7zmQxVncDAy5uIKz4rEkgIXeMed4M0jlfIDPvg6uqKI2xXr2" crossorigin="anonymous">'
  echo "<title>Monitoring</title>"
  echo "</head><body>"
  echo "<div class=container><div class=row><div class=col>"
  echo "<h1>Monitoring</h1>"
  echo "</div></div>"
  echo "<div class=row><div class=col>"
}

writeFooter() {
  echo "</div></div>"
  echo "<div class=row><div class=col>"
  echo "<h2>Info</h2>"
  echo "<p>Last check: "
  date

  echo "<br>Total duration: ${runtime} ms"
  echo "<br>Monitoring script by <a href='https://raymii.org/'>Remy van Elst</a>. License: GNU AGPLv3. "
  echo "<a href='https://github.com/raymiiorg/bash-http-monitoring'>Source code</a>"
  echo "</p>"
  echo "</div></div></div>"
  echo "</body></html>"
}


# script start 

# Total script duration timer
start=$(date +%s%3N)

tmpdir=$(mktemp -d)
tempfolder=${tmpdir:-/tmp/statusmon/}

# try to create folders, if it fails, stop the script.
mkdir -p "${tempfolder}/OK" || exit 1
mkdir -p "${tempfolder}/FAIL" || exit 1

pushd "${tempfolder}" >/dev/null 2>&1

# Do the checks parallel
for key in "${!urls[@]}"
do
  value=${urls[$key]}
  if [[ "$(jobs | wc -l)" -ge ${maxConcurrentCurls} ]] ; then # run 12 curl commands at max parallel
      wait -n
  fi
  doRequest "$key" "$value" &
done
wait 

writeHeader

# Failed checks, if any, go on top
writeFailedChecks

# Okay checks go below the failed checks
writeOkayChecks

# Cleanup the status files
cleanupFailedCheckFiles
cleanupOKCheckFiles

# stop the total timer
end=$(date +%s%3N)
runtime=$((end-start))

writeFooter

popd >/dev/null 2>&1

rmdir "${tempfolder}"
