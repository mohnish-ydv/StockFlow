import { createClient } from 'npm:@supabase/supabase-js@2.57.4'

const FALLBACK_ORIGIN = 'https://mohnish-ydv.github.io'
const EXTRA_ORIGINS = (Deno.env.get('STOCKFLOW_ALLOWED_ORIGINS') ?? '').split(',').map((x) => x.trim()).filter(Boolean)
async function sha256(value: string) { const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(value)); return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, '0')).join('') }
function cors(req: Request) { const origin=req.headers.get('origin')??''; const local=/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i.test(origin); const ok=origin===FALLBACK_ORIGIN||EXTRA_ORIGINS.includes(origin)||local; return {'Access-Control-Allow-Origin':origin&&ok?origin:FALLBACK_ORIGIN,'Access-Control-Allow-Headers':'authorization, apikey, content-type, x-stockflow-session','Access-Control-Allow-Methods':'POST, OPTIONS','Access-Control-Max-Age':'600','Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store','Vary':'Origin','X-Content-Type-Options':'nosniff'} }

Deno.serve(async (req) => {
  const headers=cors(req), json=(data:unknown,status=200)=>new Response(JSON.stringify(data),{status,headers})
  if(req.method==='OPTIONS')return new Response('ok',{headers}); if(req.method!=='POST')return json({error:'Method not allowed'},405)
  try {
    const url=Deno.env.get('SUPABASE_URL')!, secrets=JSON.parse(Deno.env.get('SUPABASE_SECRET_KEYS')??'{}'), secret=secrets.default??Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    if(!url||!secret)return json({error:'Server configuration unavailable'},500)
    const db=createClient(url,secret,{auth:{persistSession:false}}), token=req.headers.get('x-stockflow-session')??''
    if(!token)return json({error:'Sign in required'},401)
    const {data:session}=await db.from('staging_sessions').select('user_id,expires_at').eq('token_hash',await sha256(token)).maybeSingle()
    if(!session||new Date(session.expires_at).getTime()<=Date.now())return json({error:'Session expired'},401)
    const {data:user}=await db.from('staging_users').select('seller_status,account_status').eq('id',session.user_id).single()
    if(!user||user.account_status!=='active')return json({error:'Active account required'},403)
    if(user.seller_status!=='approved')return json({error:'Approved seller access required'},403)

    const body=await req.json(), action=String(body.action??'prepare'), mime=String(body.mime??'image/jpeg').toLowerCase(), size=Number(body.sizeBytes??0), duration=body.durationSeconds==null?null:Number(body.durationSeconds)
    const imageMimes=['image/jpeg','image/png','image/webp'], videoMimes=['video/mp4','video/quicktime']
    const isImage=imageMimes.includes(mime), isVideo=videoMimes.includes(mime)
    if(!isImage&&!isVideo)return json({error:'Unsupported media type'},400)
    if(!Number.isFinite(size)||size<=0)return json({error:'Invalid media size'},400)
    if(isImage&&size>5*1024*1024)return json({error:'Maximum image size is 5 MB'},400)
    if(isVideo&&size>10*1024*1024)return json({error:'Maximum video size is 10 MB'},400)
    if(isVideo&&(!Number.isFinite(duration)||duration!<=0||duration!>30))return json({error:'Video must be 30 seconds or shorter'},400)
    if(action!=='prepare')return json({error:'Unknown upload action'},404)

    const ext=mime==='image/png'?'png':mime==='image/webp'?'webp':mime==='video/quicktime'?'mov':mime==='video/mp4'?'mp4':'jpg'
    const mediaType=isVideo?'video':'image', path=`${session.user_id}/${mediaType}/${crypto.randomUUID()}.${ext}`
    const signed=await db.storage.from('staging-listings').createSignedUploadUrl(path)
    if(signed.error||!signed.data?.signedUrl||!signed.data?.token)throw signed.error??new Error('Could not prepare upload')
    const publicUrl=db.storage.from('staging-listings').getPublicUrl(path).data.publicUrl
    return json({
      signedUrl:signed.data.signedUrl,
      token:signed.data.token,
      path,
      storagePath:path,
      url:publicUrl,
      mediaType,
      mimeType:mime,
      sizeBytes:size,
      durationSeconds:isVideo?duration:null,
      limits:{maxItems:8,maxVideos:2,maxVideoSeconds:30,maxImageBytes:5*1024*1024,maxVideoBytes:10*1024*1024},
    })
  } catch(error){console.error(error);return json({error:error instanceof Error?error.message:'Upload preparation failed'},500)}
})
