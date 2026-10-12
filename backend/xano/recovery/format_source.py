from pathlib import Path
import re,sys
for name in sys.argv[1:]:
 p=Path(name);s=p.read_text();parts=s.split('"""')
 for k in range(0,len(parts),2):
  # Keep string literals intact while placing statement braces on separate lines.
  src=parts[k];out='';quote=False;escape=False
  for c in src:
   if quote:
    out+=c
    if c=='"' and not escape:quote=False
    escape=(c=='\\' and not escape)
   elif c=='"':quote=True;out+=c
   elif c=='{':out+='{\n'
   elif c=='}':out+='\n}\n'
   else:out+=c
  out=re.sub(r'}\s*as\s+','} as ',out)
  parts[k]=out
 p.write_text('"""'.join(parts))
