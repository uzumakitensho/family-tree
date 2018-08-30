
$envs = Get-Content .env

foreach ($env in $envs) {
  $line = $env.Trim()
  $pos = $line.IndexOf("=")

  if ($pos -eq -1) {
    continue
  }

  $key = $line.Substring(0, $pos)
  $val = $line.Substring($pos+1)

  [Environment]::SetEnvironmentVariable($key, $val, "Process")
}

$project = [Environment]::GetEnvironmentVariable("COMPOSE_PROJECT_NAME", "Process")
$image = [Environment]::GetEnvironmentVariable("LARAVEL_CLI_IMAGE", "Process")
$pwd = (Get-Location).Path

docker run -ti --rm `
  -v "${pwd}/src:/srv/web" `
  -v "${project}_node_modules:/srv/web/node_modules" `
  -w "/srv/web" `
  --link "${project}_database_1:database" `
  --net "${project}_default" `
  "${image}" bash
