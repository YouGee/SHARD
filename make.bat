@ECHO ON
del SHARD.love
set path="C:\Program Files\WinRAR"
winrar a -afzip -x.git* -x*\.git -x*\.git\* -r SHARD.love *.*
SHARD.love