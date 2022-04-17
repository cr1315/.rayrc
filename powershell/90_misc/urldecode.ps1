


Add-Type -AssemblyName System.Web
function get-urldecode {
  $decoded = switch($args.length) {
    1 { [System.Web.HttpUtility]::UrlDecode($args[0]) }
    2 { [System.Web.HttpUtility]::UrlDecode($args[0], $args[1]) }
    4 { [System.Web.HttpUtility]::UrlDecode($args[0], $args[1], $args[2], $args[3]) }
    default { "parameter invalid.." }
  }

  $url = [String]::new($args[0])

  $uri = [System.URI]::new($decoded)
  if ($uri.AbsolutePath -like "/sites/*/AllItems.aspx") {
    if ($uri.Query -match 'id=/sites/([^&]*)&?') {
      $matched = $true
    }
  } elseif ($uri.AbsolutePath -like '*/sites/*') {
    if ($uri.AbsolutePath -match '/sites/(.*)$') {
      $matched = $true
    }
  } elseif ($uri.AbsolutePath -like '*/personal/*/Documents/*') {
    if ($uri.AbsolutePath -match '/personal/(.*)$') {
      $matched = $true
    }
  }
  if ($matched -eq $True) {
    $filePath = [System.Web.HttpUtility]::UrlDecode($matches[1])
    $filePath = $filePath -replace 'Shared Documents/|Documents/', ''
    $filePath = $filePath -replace '/', ' > '

    $copyToClipboard = $false
    do {
      try {
        set-clipboard "[$filePath]($url"
        $copyToClipboard = $true
      } catch {
        Start-Sleep -Milliseconds 100
      }
    } until ($copyToClipboard -eq $true)

    return "[$filePath]($url"
  }

  return $decoded
}
sal urldecode get-urldecode
