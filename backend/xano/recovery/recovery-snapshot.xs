// Read-only authoritative sandbox recovery evidence. Never submits a booking.
function "supplier/checkout/recovery_snapshot" {
 input { int intent_id }
 stack {
 db.get supplier_checkout_intents {field_name="id"
 field_value=$input.intent_id} as $intent
 precondition ($intent != null && $intent.provider_slug == "nuitee" && $intent.environment == "sandbox") {error_type="inputerror"
 error="Nuitee sandbox checkout required"}
 db.get orders {field_name="id"
 field_value=$intent.order_id} as $order
 precondition ($order != null && $intent.stripe_checkout_session_id != null) {error="Order and checkout required"}
 api.request {
 url="https://api.stripe.com/v1/checkout/sessions/" ~ ($intent.stripe_checkout_session_id|url_encode)
 method="GET"
 headers=["Authorization: Bearer " ~ $env.STRIPE_SECRET_KEY_test]
 timeout=15
 } as $session
 var $pi {value=null}
 var $refunds {value=null}
 conditional {if ($session.response.status == 200 && $session.response.result.payment_intent != null) {
 api.request {
 url="https://api.stripe.com/v1/payment_intents/" ~ ($session.response.result.payment_intent|url_encode) ~ "?expand[]=latest_charge.balance_transaction"
 method="GET"
 headers=["Authorization: Bearer " ~ $env.STRIPE_SECRET_KEY_test]
 timeout=15
 } as $payment_response
 var.update $pi {value=$payment_response}
 api.request {
 url="https://api.stripe.com/v1/refunds?limit=100&payment_intent=" ~ ($session.response.result.payment_intent|url_encode)
 method="GET"
 headers=["Authorization: Bearer " ~ $env.STRIPE_SECRET_KEY_test]
 timeout=15
 } as $refund_response
 var.update $refunds {value=$refund_response}
 }}
 var $booking {value=null}
 var $lookup {value=null}
 var $booking_id {value=$order.external_booking_id}
 conditional {if ($booking_id == null || $booking_id == "") {
 api.request {
 url="https://book.liteapi.travel/v3.0/bookings?clientReference=" ~ ($intent.client_reference|url_encode) ~ "&timeout=15"
 method="GET"
 headers=["Accept: application/json","X-API-Key: " ~ $env.NUITEE_SANDBOX_API_KEY]
 timeout=20
 } as $reference_response
 var.update $lookup {value=$reference_response}
 api.lambda {code="""
const a=$var.lookup.response?.result?.data;
if($var.lookup.response?.status!==200||!Array.isArray(a)||a.length!==1)return null;
const b=a[0];return (b.clientReference||b.client_reference)===$var.intent.client_reference?b.bookingId||null:null;
"""
 timeout=5} as $found_id
 var.update $booking_id {value=$found_id}
 }}
 conditional {if ($booking_id != null && $booking_id != "") {
 function.run "connector/adapters/nuitee/get_booking" {input={booking_id:$booking_id}} as $retrieved
 var.update $booking {value=$retrieved}
 }}
 api.lambda {code="""
'use strict';
// This module is embedded verbatim in the Xano snapshot lambda.
function recoveryEvidence(i,o,session,pi,refunds,lookup,booking,now) {
 const minor=v=>Math.round(Number(v)*100), c=i.checkout_context||{};
 const s=session?.response?.result,p=pi?.response?.result,rs=refunds?.response?.result;
 const fail=message=>({valid:false,message,allowed:[],checked_at:now});
 if(i.provider_slug!=='nuitee'||i.environment!=='sandbox'||i.currency!=='EUR'||!o||o.id!==i.order_id) return fail('Alleen gekoppelde Nuitée-sandboxorders.');
 if(session?.response?.status!==200||s?.object!=='checkout.session'||s.livemode!==false||s.id!==i.stripe_checkout_session_id||o.stripe_checkout_session_id!==s.id||s.currency!=='eur'||s.amount_total!==minor(i.selling_price)||minor(o.total_amount)!==s.amount_total||String(s.metadata?.supplier_checkout_intent_id)!==String(i.id)||String(s.metadata?.supplier_order_id)!==String(o.id)||s.metadata?.supplier_fulfillment!=='nuitee')return fail('Betaalsessie niet betrouwbaar gekoppeld.');
 if(!p||pi?.response?.status!==200||p.id!==s.payment_intent||p.livemode!==false||p.currency!=='eur'||p.amount!==s.amount_total||p.status!=='succeeded'||s.payment_status!=='paid'||(i.stripe_payment_intent_id&&i.stripe_payment_intent_id!==p.id))return fail('Geen volledig geverifieerde geslaagde testbetaling.');
 const charge=p.latest_charge;
 if(!charge||typeof charge!=='object'||charge.payment_intent!==p.id||charge.paid!==true||charge.currency!=='eur'||charge.amount!==p.amount||charge.livemode!==false||charge.disputed===true)return fail('Betaling onvolledig of betwist.');
 if(refunds?.response?.status!==200||!Array.isArray(rs?.data)||rs.has_more!==false||rs.data.some(r=>r.payment_intent!==p.id||r.currency!=='eur'||!Number.isSafeInteger(r.amount)||r.amount<0||!['succeeded','pending','requires_action','failed','canceled'].includes(r.status)))return fail('Terugbetalingen niet volledig te controleren.');
 const refunded=rs.data.filter(r=>r.status==='succeeded').reduce((a,r)=>a+r.amount,0),pending=rs.data.filter(r=>['pending','requires_action'].includes(r.status)).reduce((a,r)=>a+r.amount,0);
 if(refunded!==charge.amount_refunded||refunded+pending>p.amount)return fail('Terugbetalingen nog niet consistent; later opnieuw controleren.');
 let remote=null,absent=false;
 if(booking?.success===true){remote=booking.data;}else if(lookup?.response?.status===200&&Array.isArray(lookup.response.result?.data)&&lookup.response.result.data.length===0&&!o.external_booking_id){absent=true;}
 if(remote&&(Number(remote.sandbox)!==1||remote.clientReference!==i.client_reference||remote.currency!=='EUR'||typeof remote.bookingId!=='string'||!remote.bookingId||(o.external_booking_id&&o.external_booking_id!==remote.bookingId)))return fail('Leveranciersboeking hoort niet aantoonbaar bij deze testorder.');
 const status=String(remote?.status||'UNKNOWN').toUpperCase(),confirmed=status==='CONFIRMED',cancelled=['CANCELLED','CANCELLED_WITH_CHARGES','CANCELED','CANCELED_WITH_CHARGES'].includes(status);
 const response=c.booking_response, errorCode=String(response?.error?.upstream_error?.error?.code??response?.error?.upstream_error?.code??'');
 const neverSubmitted=!c.booking_submission_at&&!c.booking_response&&(i.booking_attempts||0)===0;
 const definitiveFailure=response?.success===false&&errorCode==='4002';
 const age=now-Number(c.booking_response_at||c.booking_submission_at||i.updated_at||now);
 const noBooking=absent&&(neverSubmitted||(definitiveFailure&&age>=300000));
 if(!remote&&!noBooking)return fail('Geen zekere leveranciersuitkomst. Lege zoekresultaten of time-out zijn geen bewijs dat er nooit geboekt is.');
 if(!confirmed&&!cancelled&&!noBooking)return fail('Leveranciersstatus nog niet definitief.');
 const op=c.recovery?.operation||null, matched=op?.key?rs.data.filter(r=>r.metadata?.seasondeals_recovery_key===op.key):[];
 if(matched.length>1)return fail('Meerdere refunds op dezelfde herstelsleutel; handmatige controle vereist.');
 const refund=matched[0]||null;
 if(refund&&refund.amount!==op.amount_minor)return fail('Refundbedrag wijkt af van opgeslagen herstelopdracht.');
 const unresolvedRefund=op?.action==='refund'&&!refund;
 const refundRetry=unresolvedRefund&&now-op.started_at<82800000&&now-op.started_at>=60000;
 const allowed=['reconcile'];
 if(confirmed&&!op&&refunded===0&&pending===0)allowed.push('cancel');
 if((cancelled||noBooking)&&!op&&pending===0&&refunded<p.amount)allowed.push('refund');
 if((cancelled||noBooking)&&refundRetry&&pending===0)allowed.push('retry_refund');
 const savedCancel=c.recovery?.cancellation;
 const saved=cancelled&&savedCancel?.booking_id===remote?.bookingId?savedCancel:null;
 const fee=remote?.cancellation_fee??remote?.cancellationFee??saved?.fee??null, supplierRefund=remote?.refund_amount??remote?.refundAmount??saved?.refund??null;
 const balance=charge.balance_transaction,feesKnown=balance?.object==='balance_transaction'&&balance.currency==='eur'&&balance.amount===p.amount&&Number.isSafeInteger(balance.fee)&&balance.fee>=0;
 const version=JSON.stringify([i.updated_at,o.updated_at,status,remote?.bookingId||null,refunded,pending,op?.key||null]);
 return {valid:true,allowed,message:unresolvedRefund&&!refundRetry?'Onzekere refund; eerst Stripe-status controleren.':cancelled?'Hotelannulering bevestigd.':noBooking?'Definitief afgewezen boeking, geen leveranciersreservering gevonden.':'Hotelboeking bevestigd.',checked_at:now,version,order_id:o.id,intent_id:i.id,environment:'sandbox',supplier_status:noBooking?'NOT_BOOKED':status,booking_id:remote?.bookingId||null,client_reference:i.client_reference,paid_minor:p.amount,refunded_minor:refunded,pending_refund_minor:pending,remaining_minor:p.amount-refunded-pending,currency:'EUR',cancellation_terms:c.quote?.cancellation_policies||null,cancellation_fee:fee,supplier_refund:supplierRefund,refund_status:refund?.status||null,operation:op?{action:op.action,started_at:op.started_at,amount_minor:op.amount_minor}:null,confirmed,cancelled,no_booking:noBooking,payment_intent_id:p.id,charge_id:charge.id,refund_id:refund?.id||null,stripe_fee:feesKnown?balance.fee/100:null,supplier_amount:Number.isFinite(remote?.price)?remote.price:null,processing_fee:Number.isFinite(remote?.processingFee)?remote.processingFee:null,booking:remote,refunds:rs.data};
}

return recoveryEvidence($var.intent,$var.order,$var.session,$var.pi,$var.refunds,$var.lookup,$var.booking,Date.now());
"""
 timeout=10} as $evidence
 }
 response=$evidence
}
