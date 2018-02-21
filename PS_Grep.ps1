$dir = "SourceDir\*.*"
$string = 'yourStringHere'

$fileList = gci -Recurse -Path $dir -ErrorAction SilentlyContinue


foreach ($file in $fileList)
{
    Select-String -Path $file -Pattern $string -ErrorAction SilentlyContinue
}