// Internal signature primitive. Pass the exact raw request body and a server-selected endpoint secret. Never expose secret as API input.
function "supplier/production/verify_stripe_signature" {
 input {
 text raw_body
 text signature
 text endpoint_secret
 }
 stack {
  api.lambda {
   code = """
const body=$input.raw_body,header=$input.signature,secret=$input.endpoint_secret;
const deny=()=>({valid:false});
if(typeof body!=='string'||body.length===0||body.length>1048576||typeof header!=='string'||header.length>4096||typeof secret!=='string'||!secret.startsWith('whsec_')||secret.length<20)return deny();
const parts=header.split(',').map(s=>s.trim()),ts=parts.filter(s=>s.startsWith('t=')).map(s=>s.slice(2)),sigs=parts.filter(s=>s.startsWith('v1=')).map(s=>s.slice(3));
if(ts.length!==1||!/^[0-9]{10}$/.test(ts[0])||sigs.length===0||sigs.length>16||sigs.some(s=>!/^[a-f0-9]{64}$/.test(s)))return deny();
if(Math.abs(Math.floor(Date.now()/1000)-Number(ts[0]))>300)return deny();
return {valid:true,payload:ts[0]+'.'+body,signatures:sigs};
"""
   timeout = 5
  } as $parsed
  precondition ($parsed.valid) { error_type = "accessdenied"
 error = "Invalid webhook signature" }
  var $expected { value = $parsed.payload|hmac_sha256:$input.endpoint_secret:false }
  api.lambda {
   code = """
const expected=$var.expected,sigs=$var.parsed.signatures;
if(typeof expected!=='string'||expected.length!==64)return {verified:false};
let matched=0;
for(const sig of sigs){let diff=0;for(let i=0;i<64;i++)diff|=expected.charCodeAt(i)^sig.charCodeAt(i);matched|=Number(diff===0);}
if(matched!==1)return {verified:false};
let event;try{event=JSON.parse($input.raw_body);}catch(_){return {verified:false};}
if(!event||event.object!=='event'||!/^evt_[A-Za-z0-9]{8,100}$/.test(event.id||''))return {verified:false};
return {verified:true,event};
"""
   timeout = 5
  } as $checked
  precondition ($checked.verified) { error_type = "accessdenied"
 error = "Invalid webhook signature" }
 }
 response = $checked
 history = "disabled"
}

