import { createClient } from 'npm:@supabase/supabase-js@2.57.4'

const fallbackOrigin = 'https://mohnish-ydv.github.io'
const configuredOrigins = (Deno.env.get('STOCKFLOW_ALLOWED_ORIGINS') ?? '')
  .split(',').map((x) => x.trim()).filter(Boolean)

const allowedActions = new Set([
  'health','login','logout','me','categories','feed','listing','marketplaceConfig',
  'applySeller','sellerStatus','sellerDashboard','myListings','createListing','saveListingLocation','resubmitListing','reportListing',
  'startConversation','conversations','messages','sendMessage','makeOffer','counterOffer','respondOffer','myOffers',
  'cart','addCart','updateCart','removeCart','addresses','saveAddress','checkout','orders','order','sellerUpdateOrder',
  'adminDashboard','adminApplications','adminReviewSeller','adminListings','adminSetListingStatus','adminOrders',
  'adminUsers','adminSetUserStatus','adminApplicationsV2','adminReviewSellerV2','adminListingsV2','adminListingDetail','adminReviewListing',
  'adminReports','adminResolveReport',
])
const writeActions = new Set([
  'login','logout','applySeller','createListing','saveListingLocation','resubmitListing','reportListing',
  'startConversation','sendMessage','makeOffer','counterOffer','respondOffer','addCart','updateCart','removeCart','saveAddress','checkout','sellerUpdateOrder',
  'adminReviewSeller','adminSetListingStatus','adminSetUserStatus','adminReviewSellerV2','adminReviewListing','adminResolveReport',
])
const chatActions = new Set(['startConversation','sendMessage','makeOffer','counterOffer','respondOffer'])

const publicListingSelect = [
  'id','seller_id','category_slug','title','description','brand','condition','original_price','selling_price','negotiable',
  'inventory_type','available_qty','unit','minimum_order_quantity','pickup_enabled','shipping_enabled','cod_enabled',
  'city','state','image_url','status','is_featured','created_at','updated_at',
  'seller:staging_users!staging_listings_seller_id_fkey(id,full_name,city,state,seller_status,created_at)',
].join(',')

function cors(req: Request) {
  const origin = req.headers.get('origin') ?? ''
  const local = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i.test(origin)
  const allowed = origin === fallbackOrigin || configuredOrigins.includes(origin) || local
  return {
    'Access-Control-Allow-Origin': origin && allowed ? origin : fallbackOrigin,
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-stockflow-session, x-stockflow-client',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Max-Age': '600',
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    'Vary': 'Origin',
    'X-Content-Type-Options': 'nosniff',
    'Referrer-Policy': 'no-referrer',
  }
}

async function sha256(value: string) {
  const bytes = new TextEncoder().encode(value)
  const digest = await crypto.subtle.digest('SHA-256', bytes)
  return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, '0')).join('')
}
const clean = (value: unknown, max = 2000) => String(value ?? '').trim().slice(0, max)
const phone10 = (value: unknown) => String(value ?? '').replace(/\D/g, '').slice(-10)
const asInt = (value: unknown, fallback = 0) => {
  const n = Number(value)
  return Number.isInteger(n) ? n : fallback
}
const asNum = (value: unknown, fallback = 0) => {
  const n = Number(value)
  return Number.isFinite(n) ? n : fallback
}

function adminPage(body: Record<string, unknown>, fallbackSize = 25) {
  const page = Math.max(1, Math.min(100000, asInt(body.page, 1)))
  const pageSize = Math.max(10, Math.min(100, asInt(body.pageSize, fallbackSize)))
  const from = (page - 1) * pageSize
  return { page, pageSize, from, to: from + pageSize - 1 }
}

function adminPagination(total: number | null, page: number, pageSize: number) {
  const safeTotal = Math.max(0, Number(total ?? 0))
  const pageCount = Math.max(1, Math.ceil(safeTotal / pageSize))
  return {
    page, pageSize, total: safeTotal, pageCount,
    hasPrevious: page > 1,
    hasNext: page < pageCount,
  }
}

function containsContactExchange(text: string) {
  const lowered = text.toLowerCase()
  return /[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}/i.test(lowered)
    || /(https?:\/\/|www\.|wa\.me|t\.me|telegram\.me|instagram\.com|facebook\.com)/i.test(lowered)
    || /(^|[^a-z])(whatsapp|telegram|instagram|snapchat)([^a-z]|$)/i.test(lowered)
    || /(^|[^a-z])(call|contact|text|message|dm|ping)\s+(me|us)([^a-z]|$)/i.test(lowered)
    || /(?:^|[^0-9])(?:\+?91[\s.-]?)?[6-9](?:[\s.-]?[0-9]){9}(?:[^0-9]|$)/.test(lowered)
}

function gstinLooksValid(value: string) {
  return !value || /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$/i.test(value)
}
function panLooksValid(value: string) {
  return !value || /^[A-Z]{5}[0-9]{4}[A-Z]$/i.test(value)
}

function sanitizeMedia(raw: unknown) {
  if (!Array.isArray(raw)) return [] as any[]
  const items = raw.slice(0, 9).map((entry, index) => {
    const x = entry && typeof entry === 'object' ? entry as Record<string, unknown> : {}
    const mediaType = String(x.mediaType ?? x.media_type ?? '')
    const mimeType = clean(x.mimeType ?? x.mime_type, 80)
    const url = clean(x.url, 1600)
    const storagePath = clean(x.storagePath ?? x.storage_path, 600)
    const sizeBytes = Math.max(0, asInt(x.sizeBytes ?? x.size_bytes))
    const duration = x.durationSeconds == null && x.duration_seconds == null
      ? null
      : asNum(x.durationSeconds ?? x.duration_seconds, -1)
    return { mediaType, mimeType, url, storagePath, sizeBytes, durationSeconds: duration, sortOrder: index }
  })
  if (items.length > 8) throw new Error('A listing can contain at most 8 media items.')
  if (!items.length || !items.some((x) => x.mediaType === 'image')) throw new Error('Add at least one product photo.')
  if (items.filter((x) => x.mediaType === 'video').length > 2) throw new Error('A listing can contain at most 2 videos.')
  for (const item of items) {
    if (!item.url || !['image','video'].includes(item.mediaType)) throw new Error('Invalid listing media.')
    if (item.mediaType === 'image') {
      if (!['image/jpeg','image/png','image/webp'].includes(item.mimeType) || item.sizeBytes > 5 * 1024 * 1024) {
        throw new Error('Each image must be JPG, PNG or WebP and no larger than 5 MB.')
      }
    } else {
      if (!['video/mp4','video/quicktime'].includes(item.mimeType) || item.sizeBytes > 10 * 1024 * 1024) {
        throw new Error('Each video must be MP4/MOV and no larger than 10 MB.')
      }
      if (item.durationSeconds == null || item.durationSeconds <= 0 || item.durationSeconds > 30) {
        throw new Error('Videos must be 30 seconds or shorter.')
      }
    }
  }
  return items
}

Deno.serve(async (req) => {
  const headers = cors(req)
  const respond = (data: unknown, status = 200) => new Response(JSON.stringify(data), { status, headers })
  if (req.method === 'OPTIONS') return new Response('ok', { headers })
  if (req.method !== 'POST') return respond({ error: 'Method not allowed' }, 405)
  const traceId = crypto.randomUUID().slice(0, 8).toUpperCase()

  try {
    const raw = await req.text()
    if (raw.length > 96 * 1024) return respond({ error: 'Request is too large.', traceId }, 413)
    const body = raw ? JSON.parse(raw) : {}
    const action = String(body.action ?? '')
    if (!allowedActions.has(action)) return respond({ error: 'Unknown action.', traceId }, 404)

    const url = Deno.env.get('SUPABASE_URL')
    const secretKeys = JSON.parse(Deno.env.get('SUPABASE_SECRET_KEYS') ?? '{}')
    const secret = secretKeys.default ?? Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    const publishable = JSON.parse(Deno.env.get('SUPABASE_PUBLISHABLE_KEYS') ?? '{}').default ?? ''
    if (!url || !secret || !publishable) return respond({ error: 'Server configuration unavailable.', traceId }, 500)
    const db = createClient(url, secret, { auth: { persistSession: false, autoRefreshToken: false } })

    const token = req.headers.get('x-stockflow-session') ?? ''
    const getSessionUser = async () => {
      if (!token) return null
      const tokenHash = await sha256(token)
      const { data: session } = await db.from('staging_sessions').select('user_id,expires_at').eq('token_hash', tokenHash).maybeSingle()
      if (!session || new Date(session.expires_at).getTime() <= Date.now()) return null
      const { data: user } = await db.from('staging_users').select('*').eq('id', session.user_id).maybeSingle()
      return user ?? null
    }
    const requireUser = async () => {
      const user = await getSessionUser()
      if (!user) throw Object.assign(new Error('Session expired. Sign in again.'), { httpStatus: 401 })
      if (user.account_status && user.account_status !== 'active') {
        throw Object.assign(new Error(user.account_status === 'banned' ? 'This account has been banned.' : 'This account is temporarily suspended.'), { httpStatus: 403 })
      }
      return user
    }
    const requireAdmin = async () => {
      const user = await requireUser()
      if (user.role !== 'admin') throw Object.assign(new Error('Admin access required.'), { httpStatus: 403 })
      return user
    }

    const ip = clean((req.headers.get('x-forwarded-for') ?? '').split(',')[0] || req.headers.get('cf-connecting-ip') || 'unknown', 80)
    const identity = await sha256(`${token ? await sha256(token) : 'anon'}|${ip}|${action === 'login' ? phone10(body.phone) : ''}`)
    const group = action === 'login' ? 'login' : chatActions.has(action) ? 'chat' : writeActions.has(action) ? 'write' : 'read'
    const policy = group === 'login' ? [8, 600] : group === 'chat' ? [30, 60] : group === 'write' ? [60, 60] : [180, 60]
    const { data: allowed, error: rateError } = await db.rpc('stockflow_rate_limit', { p_key_hash: identity, p_action_group: `api_v3_${group}`, p_limit: policy[0], p_window_seconds: policy[1] })
    if (rateError) throw rateError
    if (allowed !== true) {
      const user = await getSessionUser()
      await db.from('staging_security_events').insert({ user_id: user?.id ?? null, category: 'rate_limit', action_name: action, key_hash: identity, details: { gateway: 'api-v3', traceId } })
      return respond({ error: 'Too many requests. Please wait and try again.', traceId }, 429)
    }

    if (action === 'health') {
      return respond({ ok: true, service: 'StockFlow API', version: '3.3.0', moderatedListings: true, media: { maxItems: 8, maxVideos: 2, maxVideoSeconds: 30 }, websiteReady: true, strictSignIn: true })
    }

    if (action === 'marketplaceConfig') {
      const { data } = await db.from('app_settings').select('value').eq('key', 'marketplace_home_banner').maybeSingle()
      return respond({ banner: data?.value ?? { enabled: false } })
    }

    if (action === 'categories') {
      const { data, error } = await db.from('categories').select('id,name,slug,icon,sort_order').eq('is_active', true).order('sort_order')
      if (error) throw error
      return respond({ categories: data ?? [] })
    }

    const withMedia = async (rows: any[]) => {
      if (!rows.length) return rows
      const ids = rows.map((x) => x.id)
      const { data: media } = await db.from('staging_listing_media').select('id,listing_id,media_type,url,mime_type,sort_order,size_bytes,duration_seconds').in('listing_id', ids).order('sort_order')
      const map = new Map<string, any[]>()
      for (const item of media ?? []) map.set(item.listing_id, [...(map.get(item.listing_id) ?? []), item])
      return rows.map((x) => ({ ...x, media: map.get(x.id) ?? (x.image_url ? [{ id: `legacy-${x.id}`, listing_id: x.id, media_type: 'image', url: x.image_url, mime_type: 'image/jpeg', sort_order: 0, size_bytes: 0, duration_seconds: null }] : []) }))
    }

    if (action === 'feed') {
      let query = db.from('staging_listings').select(publicListingSelect).eq('status', 'active').order('is_featured', { ascending: false }).order('created_at', { ascending: false }).limit(80)
      if (body.categorySlug) query = query.eq('category_slug', clean(body.categorySlug, 60))
      if (body.search) query = query.ilike('title', `%${clean(body.search, 120).replace(/[%_]/g, '')}%`)
      if (body.shipping === true) query = query.eq('shipping_enabled', true)
      if (body.cod === true) query = query.eq('cod_enabled', true)
      if (body.bulk === true) query = query.eq('inventory_type', 'bulk')
      if (body.negotiable === true) query = query.eq('negotiable', true)
      const { data, error } = await query
      if (error) throw error
      return respond({ listings: await withMedia(data ?? []) })
    }

    if (action === 'listing') {
      const id = String(body.id ?? '')
      const { data, error } = await db.from('staging_listings').select(publicListingSelect).eq('id', id).eq('status', 'active').maybeSingle()
      if (error) throw error
      if (!data) return respond({ error: 'Listing not found.', traceId }, 404)
      const [item] = await withMedia([data])
      const { data: loc } = await db.from('staging_listing_locations').select('latitude,longitude').eq('listing_id', id).maybeSingle()
      const approximateLocation = loc ? {
        latitude: Math.round(Number(loc.latitude) * 10) / 10,
        longitude: Math.round(Number(loc.longitude) * 10) / 10,
        radiusKm: 10,
      } : null
      return respond({ listing: { ...item, approximate_location: approximateLocation } })
    }

    if (action === 'login') {
      const phone = phone10(body.phone)
      if (phone.length !== 10) return respond({ error: 'Enter a valid 10-digit mobile number.', traceId }, 400)
      const mode = String(body.authMode ?? body.auth_mode ?? 'legacy')
      const { data: existing } = await db.from('staging_users').select('id,role,account_status').eq('phone', phone).maybeSingle()
      if (mode === 'signIn' && !existing) return respond({ error: 'No StockFlow account found for this number. Create a new account first.', traceId, actionHint: 'create_account' }, 404)
      if (mode === 'register' && existing) return respond({ error: 'An account already exists for this number. Sign in instead.', traceId, actionHint: 'sign_in' }, 409)
      if (existing?.account_status && existing.account_status !== 'active') return respond({ error: existing.account_status === 'banned' ? 'This account has been banned.' : 'This account is temporarily suspended.', traceId }, 403)
      // OTP verification and session creation remain in the staging core.
      const core = await fetch(`${url}/functions/v1/stockflow-staging-api`, {
        method: 'POST', headers: { 'content-type': 'application/json', 'apikey': publishable }, body: JSON.stringify({ ...body, action: 'login' }),
      })
      const text = await core.text(); let payload: any = {}
      try { payload = text ? JSON.parse(text) : {} } catch { payload = { error: 'Unreadable core response.' } }
      if (core.ok && payload?.user?.id) await db.from('staging_users').update({ last_seen_at: new Date().toISOString() }).eq('id', payload.user.id)
      if (!core.ok && !payload.traceId) payload.traceId = traceId
      return respond(payload, core.status)
    }

    if (action === 'me') {
      const user = await requireUser()
      await db.from('staging_users').update({ last_seen_at: new Date().toISOString() }).eq('id', user.id)
      return respond({ user })
    }

    if (action === 'applySeller') {
      const user = await requireUser()
      if (user.seller_status === 'approved') return respond({ error: 'You are already an approved seller.', traceId }, 409)
      const required = ['businessName','sellerType','address','city','state','pincode']
      for (const key of required) if (!clean(body[key], 300)) return respond({ error: `${key} is required.`, traceId }, 400)
      const gstin = clean(body.gstin, 20).toUpperCase(), pan = clean(body.pan, 12).toUpperCase()
      if (!gstinLooksValid(gstin)) return respond({ error: 'GSTIN format looks invalid. Leave it blank if not applicable.', traceId }, 400)
      if (!panLooksValid(pan)) return respond({ error: 'PAN format looks invalid. Leave it blank if not applicable.', traceId }, 400)
      await db.from('staging_seller_applications').delete().eq('user_id', user.id).eq('status', 'pending')
      const categories = Array.isArray(body.primaryCategories) ? body.primaryCategories.map((x: unknown) => clean(x, 60)).filter(Boolean).slice(0, 12) : []
      const payload = {
        user_id: user.id,
        business_name: clean(body.businessName, 120), legal_name: clean(body.legalName, 140) || null,
        seller_type: clean(body.sellerType, 60), address: clean(body.address, 400), city: clean(body.city, 100), state: clean(body.state, 100), pincode: clean(body.pincode, 10),
        description: clean(body.description, 1200), gstin: gstin || null, pan: pan || null, udyam_number: clean(body.udyamNumber, 40) || null,
        website: clean(body.website, 220) || null, years_in_business: body.yearsInBusiness == null || body.yearsInBusiness === '' ? null : Math.max(0, asInt(body.yearsInBusiness)),
        primary_categories: categories, warehouse_count: body.warehouseCount == null || body.warehouseCount === '' ? null : Math.max(0, asInt(body.warehouseCount)),
        monthly_stock_volume: clean(body.monthlyStockVolume, 100) || null, contact_designation: clean(body.contactDesignation, 100) || null, status: 'pending', review_note: null,
      }
      const { data, error } = await db.from('staging_seller_applications').insert(payload).select('*').single()
      if (error) throw error
      await db.from('staging_users').update({ seller_status: 'pending' }).eq('id', user.id)
      return respond({ application: data, sellerStatus: 'pending' }, 201)
    }

    if (action === 'myListings') {
      const user = await requireUser()
      const { data, error } = await db.from('staging_listings').select('*').eq('seller_id', user.id).order('created_at', { ascending: false })
      if (error) throw error
      const rows = await withMedia(data ?? [])
      return respond({ listings: rows.map((x) => ({ ...x, seller: { id: user.id, full_name: user.full_name, seller_status: user.seller_status } })) })
    }

    if (action === 'createListing') {
      const user = await requireUser()
      if (user.seller_status !== 'approved') return respond({ error: 'Seller approval is required before submitting stock.', traceId }, 403)
      const title = clean(body.title, 140), description = clean(body.description, 4000), brand = clean(body.brand, 100)
      if (title.length < 3) return respond({ error: 'Product title is too short.', traceId }, 400)
      if (containsContactExchange(`${title} ${description} ${brand}`)) return respond({ error: 'Contact details and external links are not allowed in listings.', traceId }, 400)
      let media: any[]
      try { media = sanitizeMedia(body.media) } catch (e) { return respond({ error: e instanceof Error ? e.message : 'Invalid media.', traceId }, 400) }
      const price = asNum(body.sellingPrice, -1), qty = asInt(body.availableQty, -1), moq = Math.max(1, asInt(body.minimumOrderQuantity, 1))
      if (price < 0) return respond({ error: 'Enter a valid selling price.', traceId }, 400)
      if (qty < 1 || moq > qty) return respond({ error: 'Check available quantity and MOQ.', traceId }, 400)
      const city = clean(body.city, 100) || user.city, state = clean(body.state, 100) || user.state, pincode = clean(body.pincode, 10)
      if (!city || !state || !/^[0-9]{6}$/.test(pincode)) return respond({ error: 'Complete the stock city, state and 6-digit pincode.', traceId }, 400)
      const firstImage = media.find((x) => x.mediaType === 'image')
      const insert = {
        seller_id: user.id, category_slug: clean(body.categorySlug, 60) || 'other', title, description, brand: brand || null,
        condition: clean(body.condition, 80) || 'New Dead Stock', original_price: body.originalPrice == null || body.originalPrice === '' ? null : asNum(body.originalPrice),
        selling_price: price, negotiable: body.negotiable !== false, inventory_type: String(body.inventoryType ?? 'single'), available_qty: qty,
        unit: clean(body.unit, 30) || 'piece', minimum_order_quantity: moq, pickup_enabled: body.pickupEnabled !== false,
        shipping_enabled: Boolean(body.shippingEnabled), cod_enabled: Boolean(body.shippingEnabled) && Boolean(body.codEnabled), city, state, pincode,
        image_url: firstImage?.url ?? null, status: 'pending_review', submitted_at: new Date().toISOString(), moderation_note: null,
      }
      const { data: listing, error } = await db.from('staging_listings').insert(insert).select('*').single()
      if (error) throw error
      const mediaRows = media.map((m) => ({ listing_id: listing.id, seller_id: user.id, media_type: m.mediaType, url: m.url, storage_path: m.storagePath || null, mime_type: m.mimeType, sort_order: m.sortOrder, size_bytes: m.sizeBytes, duration_seconds: m.durationSeconds }))
      const mediaInsert = await db.from('staging_listing_media').insert(mediaRows)
      if (mediaInsert.error) { await db.from('staging_listings').delete().eq('id', listing.id); throw mediaInsert.error }
      await db.from('staging_listing_review_history').insert({ listing_id: listing.id, status: 'pending_review', actor_id: user.id, note: 'Submitted by seller for moderation.' })
      const [enriched] = await withMedia([{ ...listing, seller: { id: user.id, full_name: user.full_name, seller_status: user.seller_status } }])
      return respond({ listing: enriched, review: { status: 'pending_review', message: 'Submitted for review. It will become visible after admin approval.' } }, 201)
    }

    if (action === 'resubmitListing') {
      const user = await requireUser()
      const id = String(body.listingId ?? '')
      const { data: old } = await db.from('staging_listings').select('*').eq('id', id).eq('seller_id', user.id).maybeSingle()
      if (!old) return respond({ error: 'Listing not found.', traceId }, 404)
      if (!['rejected','paused','draft'].includes(old.status)) return respond({ error: 'Only rejected, paused or draft stock can be resubmitted.', traceId }, 409)
      const title = clean(body.title, 140) || old.title, description = clean(body.description, 4000) || old.description, brand = body.brand == null ? old.brand : clean(body.brand, 100)
      if (containsContactExchange(`${title} ${description} ${brand ?? ''}`)) return respond({ error: 'Contact details and external links are not allowed in listings.', traceId }, 400)
      let media: any[] | null = null
      if (Array.isArray(body.media)) {
        try { media = sanitizeMedia(body.media) } catch (e) { return respond({ error: e instanceof Error ? e.message : 'Invalid media.', traceId }, 400) }
      }
      const updates: any = {
        title, description, brand: brand || null, category_slug: clean(body.categorySlug, 60) || old.category_slug,
        selling_price: body.sellingPrice == null ? old.selling_price : asNum(body.sellingPrice, old.selling_price),
        original_price: body.originalPrice === '' ? null : (body.originalPrice == null ? old.original_price : asNum(body.originalPrice)),
        available_qty: body.availableQty == null ? old.available_qty : Math.max(1, asInt(body.availableQty, old.available_qty)),
        minimum_order_quantity: body.minimumOrderQuantity == null ? old.minimum_order_quantity : Math.max(1, asInt(body.minimumOrderQuantity, old.minimum_order_quantity)),
        status: 'pending_review', moderation_note: null, moderated_at: null, moderated_by: null, submitted_at: new Date().toISOString(), last_resubmitted_at: new Date().toISOString(), review_round: Number(old.review_round ?? 1) + 1, updated_at: new Date().toISOString(),
      }
      if (media) updates.image_url = media.find((x) => x.mediaType === 'image')?.url ?? old.image_url
      const { data: listing, error } = await db.from('staging_listings').update(updates).eq('id', id).select('*').single()
      if (error) throw error
      if (media) {
        await db.from('staging_listing_media').delete().eq('listing_id', id)
        const rows = media.map((m) => ({ listing_id: id, seller_id: user.id, media_type: m.mediaType, url: m.url, storage_path: m.storagePath || null, mime_type: m.mimeType, sort_order: m.sortOrder, size_bytes: m.sizeBytes, duration_seconds: m.durationSeconds }))
        const inserted = await db.from('staging_listing_media').insert(rows); if (inserted.error) throw inserted.error
      }
      await db.from('staging_listing_review_history').insert({ listing_id: id, status: 'pending_review', actor_id: user.id, note: 'Seller updated and resubmitted the listing.' })
      const [enriched] = await withMedia([{ ...listing, seller: { id: user.id, full_name: user.full_name, seller_status: user.seller_status } }])
      return respond({ listing: enriched })
    }

    if (action === 'saveListingLocation') {
      const user = await requireUser()
      if (user.seller_status !== 'approved') return respond({ error: 'Seller approval is required.', traceId }, 403)
      const listingId = String(body.listingId ?? '')
      const addressLine1 = clean(body.addressLine1, 220), street = clean(body.street, 220), locality = clean(body.locality, 160), district = clean(body.district, 160)
      const city = clean(body.city, 100), state = clean(body.state, 100), pincode = clean(body.pincode, 12), landmark = clean(body.landmark, 180), country = clean(body.country, 80) || 'India'
      if (!addressLine1 || (!street && !locality) || !city || !state || !/^[0-9]{6}$/.test(pincode)) return respond({ error: 'Complete the private pickup/dispatch address.', traceId }, 400)
      const hasLat = body.latitude !== undefined && body.latitude !== null && String(body.latitude) !== '', hasLng = body.longitude !== undefined && body.longitude !== null && String(body.longitude) !== ''
      if (hasLat !== hasLng) return respond({ error: 'Latitude and longitude must be supplied together.', traceId }, 400)
      const latitude = hasLat ? Number(body.latitude) : null, longitude = hasLng ? Number(body.longitude) : null, accuracy = body.accuracyMeters == null ? null : Number(body.accuracyMeters)
      if (hasLat && (!Number.isFinite(latitude) || latitude! < -90 || latitude! > 90 || !Number.isFinite(longitude) || longitude! < -180 || longitude! > 180)) return respond({ error: 'Invalid location coordinates.', traceId }, 400)
      const { data: listing } = await db.from('staging_listings').select('id,seller_id').eq('id', listingId).maybeSingle()
      if (!listing || listing.seller_id !== user.id) return respond({ error: 'Listing not found.', traceId }, 404)
      const now = new Date().toISOString()
      const { error: addressError } = await db.from('staging_listing_addresses').upsert({ listing_id: listingId, seller_id: user.id, address_line1: addressLine1, street: street || null, locality: locality || null, district: district || null, city, state, pincode, landmark: landmark || null, country, latitude, longitude, accuracy_meters: Number.isFinite(accuracy) ? accuracy : null, source: hasLat ? 'device' : 'manual', captured_at: now, updated_at: now }, { onConflict: 'listing_id' })
      if (addressError) throw addressError
      if (hasLat) {
        const { error: locationError } = await db.from('staging_listing_locations').upsert({ listing_id: listingId, seller_id: user.id, latitude, longitude, accuracy_meters: Number.isFinite(accuracy) ? accuracy : null, source: 'device', captured_at: now, updated_at: now }, { onConflict: 'listing_id' })
        if (locationError) throw locationError
      }
      return respond({ ok: true, addressStored: true, coordinatesStored: hasLat })
    }

    if (action === 'reportListing') {
      const user = await requireUser()
      const listingId = String(body.listingId ?? ''), reason = clean(body.reason, 120), details = clean(body.details, 1200)
      if (!reason) return respond({ error: 'Choose a report reason.', traceId }, 400)
      const { data: listing } = await db.from('staging_listings').select('id,seller_id').eq('id', listingId).eq('status','active').maybeSingle()
      if (!listing) return respond({ error: 'Listing not found.', traceId }, 404)
      if (listing.seller_id === user.id) return respond({ error: 'You cannot report your own listing.', traceId }, 400)
      const { data, error } = await db.from('staging_listing_reports').insert({ listing_id: listingId, reporter_id: user.id, reason, details: details || null }).select('id,status').single()
      if (error) throw error
      return respond({ report: data }, 201)
    }

    // Account suspension is enforced at the gateway before delegated actions.
    if (token && !['logout'].includes(action)) await requireUser()

    if (action === 'adminUsers') {
      await requireAdmin()
      const { page, pageSize, from, to } = adminPage(body)
      const queryText = clean(body.query, 80)
      let query = db.from('staging_users')
        .select('id,phone,full_name,city,state,role,seller_status,account_status,admin_note,created_at,last_seen_at', { count: 'exact' })
        .order('created_at', { ascending: false })
        .range(from, to)
      if (queryText) {
        const digits = queryText.replace(/\D/g, '')
        query = digits.length >= 4 && digits.length === queryText.replace(/\s/g, '').length
          ? query.ilike('phone', `%${digits}%`)
          : query.ilike('full_name', `%${queryText}%`)
      }
      const { data: users, count: total, error } = await query
      if (error) throw error
      const ids = (users ?? []).map((x) => x.id)
      const [listingRes, orderBuyerRes, orderSellerRes, dealBuyerRes, dealSellerRes] = await Promise.all([
        ids.length ? db.from('staging_listings').select('seller_id').in('seller_id', ids) : Promise.resolve({data:[] as any[]}),
        ids.length ? db.from('staging_orders').select('buyer_id').in('buyer_id', ids) : Promise.resolve({data:[] as any[]}),
        ids.length ? db.from('staging_orders').select('seller_id').in('seller_id', ids) : Promise.resolve({data:[] as any[]}),
        ids.length ? db.from('staging_deal_requests').select('buyer_id').in('buyer_id', ids) : Promise.resolve({data:[] as any[]}),
        ids.length ? db.from('staging_deal_requests').select('seller_id').in('seller_id', ids) : Promise.resolve({data:[] as any[]}),
      ])
      const count = (rows:any[], key:string) => { const m=new Map<string,number>(); for(const r of rows??[]) m.set(r[key],(m.get(r[key])??0)+1); return m }
      const lm=count(listingRes.data??[],'seller_id'), ob=count(orderBuyerRes.data??[],'buyer_id'), os=count(orderSellerRes.data??[],'seller_id'), dbm=count(dealBuyerRes.data??[],'buyer_id'), dsm=count(dealSellerRes.data??[],'seller_id')
      return respond({
        users:(users??[]).map((u)=>({...u,metrics:{listings:lm.get(u.id)??0,ordersBought:ob.get(u.id)??0,ordersSold:os.get(u.id)??0,deals:(dbm.get(u.id)??0)+(dsm.get(u.id)??0)}})),
        pagination: adminPagination(total, page, pageSize),
      })
    }

    if (action === 'adminSetUserStatus') {
      const admin = await requireAdmin(); const userId=String(body.userId??''), status=String(body.status??''), note=clean(body.note,1000)
      if (!['active','suspended','banned'].includes(status)) return respond({error:'Invalid account status.',traceId},400)
      if (userId === admin.id && status !== 'active') return respond({error:'You cannot suspend your own admin account.',traceId},400)
      const {data:user,error}=await db.from('staging_users').update({account_status:status,admin_note:note||null}).eq('id',userId).select('id,role,seller_status').maybeSingle(); if(error)throw error; if(!user)return respond({error:'User not found.',traceId},404)
      if(status!=='active') { await db.from('staging_sessions').delete().eq('user_id',userId); await db.from('staging_listings').update({status:'paused',moderation_note:`Account ${status}${note?`: ${note}`:''}`,moderated_at:new Date().toISOString(),moderated_by:admin.id}).eq('seller_id',userId).eq('status','active') }
      await db.from('staging_security_events').insert({user_id:userId,category:'admin_account_status',action_name:status,key_hash:null,details:{adminId:admin.id,note}})
      return respond({ok:true,status})
    }

    if (action === 'adminApplicationsV2') {
      await requireAdmin()
      const { page, pageSize, from, to } = adminPage(body)
      const { data, count: total, error } = await db.from('staging_seller_applications')
        .select('*,user:staging_users!staging_seller_applications_user_id_fkey(id,phone,full_name,city,state,seller_status,account_status,created_at)', { count: 'exact' })
        .order('created_at', { ascending: false })
        .range(from, to)
      if (error) throw error
      return respond({ applications: data ?? [], pagination: adminPagination(total, page, pageSize) })
    }

    if (action === 'adminReviewSellerV2') {
      const admin=await requireAdmin(), id=String(body.applicationId??''), decision=String(body.decision??''), note=clean(body.note,1000)
      if(!['approved','rejected'].includes(decision))return respond({error:'Invalid seller decision.',traceId},400)
      if(decision==='rejected' && note.length<5)return respond({error:'Add a clear rejection reason for the seller.',traceId},400)
      const {data:app}=await db.from('staging_seller_applications').select('*').eq('id',id).maybeSingle();if(!app)return respond({error:'Application not found.',traceId},404)
      const now=new Date().toISOString(); const {error}=await db.from('staging_seller_applications').update({status:decision,review_note:note||null,updated_at:now}).eq('id',id);if(error)throw error
      await db.from('staging_users').update({seller_status:decision,seller_approved_at:decision==='approved'?now:null}).eq('id',app.user_id)
      await db.from('staging_security_events').insert({user_id:app.user_id,category:'seller_review',action_name:decision,key_hash:null,details:{adminId:admin.id,note}})
      return respond({ok:true,sellerStatus:decision})
    }

    if (action === 'adminListingsV2') {
      await requireAdmin()
      const { page, pageSize, from, to } = adminPage(body)
      const statusFilter = clean(body.status, 40)
      const queryText = clean(body.query, 100)
      let query = db.from('staging_listings')
        .select('*,seller:staging_users!staging_listings_seller_id_fkey(id,full_name,phone,seller_status,account_status,created_at)', { count: 'exact' })
        .order('submitted_at', { ascending: false })
        .range(from, to)
      if (statusFilter && statusFilter !== 'all') query = query.eq('status', statusFilter)
      if (queryText) query = query.ilike('title', `%${queryText}%`)
      const { data, count: total, error } = await query
      if (error) throw error
      const rows=await withMedia(data??[]); const ids=rows.map((x)=>x.id); const {data:reports}=ids.length?await db.from('staging_listing_reports').select('listing_id,status').in('listing_id',ids):{data:[]};const counts=new Map<string,number>();for(const r of reports??[])if(!['resolved','dismissed'].includes(r.status))counts.set(r.listing_id,(counts.get(r.listing_id)??0)+1)
      return respond({
        listings:rows.map((x)=>({...x,open_report_count:counts.get(x.id)??0})),
        pagination: adminPagination(total, page, pageSize),
      })
    }

    if (action === 'adminListingDetail') {
      await requireAdmin(); const id=String(body.listingId??'')
      const {data:list,error}=await db.from('staging_listings').select('*,seller:staging_users!staging_listings_seller_id_fkey(id,full_name,phone,city,state,seller_status,account_status,created_at)').eq('id',id).maybeSingle();if(error)throw error;if(!list)return respond({error:'Listing not found.',traceId},404)
      const [row]=await withMedia([list]); const [address,location,history,reports]=await Promise.all([
        db.from('staging_listing_addresses').select('*').eq('listing_id',id).maybeSingle(),db.from('staging_listing_locations').select('*').eq('listing_id',id).maybeSingle(),db.from('staging_listing_review_history').select('*').eq('listing_id',id).order('created_at',{ascending:false}),db.from('staging_listing_reports').select('*').eq('listing_id',id).order('created_at',{ascending:false}),
      ]);return respond({listing:row,address:address.data??null,location:location.data??null,reviewHistory:history.data??[],reports:reports.data??[]})
    }

    if (action === 'adminReviewListing') {
      const admin=await requireAdmin(), id=String(body.listingId??''), decision=String(body.decision??''), note=clean(body.note,1200)
      const map:Record<string,string>={approved:'active',rejected:'rejected',paused:'paused',removed:'removed'};const status=map[decision];if(!status)return respond({error:'Invalid listing decision.',traceId},400)
      if(decision==='rejected' && note.length<5)return respond({error:'Add a clear rejection reason so the seller can improve the listing.',traceId},400)
      const now=new Date().toISOString(); const {data:list,error}=await db.from('staging_listings').update({status,moderation_note:note||null,moderated_at:now,moderated_by:admin.id,updated_at:now}).eq('id',id).select('id,seller_id,status').maybeSingle();if(error)throw error;if(!list)return respond({error:'Listing not found.',traceId},404)
      await db.from('staging_listing_review_history').insert({listing_id:id,status,actor_id:admin.id,note:note||`Listing ${decision}.`})
      return respond({ok:true,status})
    }

    if (action === 'adminReports') {
      await requireAdmin()
      const { page, pageSize, from, to } = adminPage(body)
      const { data, count: total, error } = await db.from('staging_listing_reports')
        .select('*,listing:staging_listings!staging_listing_reports_listing_id_fkey(id,title,status,image_url,seller_id),reporter:staging_users!staging_listing_reports_reporter_id_fkey(id,full_name,phone)', { count: 'exact' })
        .order('created_at', { ascending: false })
        .range(from, to)
      if (error) throw error
      return respond({ reports: data ?? [], pagination: adminPagination(total, page, pageSize) })
    }

    if (action === 'adminResolveReport') {
      const admin=await requireAdmin(), id=String(body.reportId??''), status=String(body.status??''), note=clean(body.note,1000)
      if(!['reviewing','resolved','dismissed'].includes(status))return respond({error:'Invalid report status.',traceId},400)
      const updates:any={status,admin_note:note||null};if(['resolved','dismissed'].includes(status)){updates.resolved_by=admin.id;updates.resolved_at=new Date().toISOString()}
      const {data,error}=await db.from('staging_listing_reports').update(updates).eq('id',id).select('id').maybeSingle();if(error)throw error;if(!data)return respond({error:'Report not found.',traceId},404);return respond({ok:true,status})
    }

    // Contact exchange is blocked before legacy/core message and listing actions.
    if (action === 'sendMessage' && containsContactExchange(clean(body.text, 2000))) {
      const user=await getSessionUser();await db.from('staging_security_events').insert({user_id:user?.id??null,category:'contact_exchange_blocked',action_name:action,key_hash:identity,details:{traceId}})
      return respond({error:'Contact details and external links are blocked in StockFlow chat. Keep the deal inside StockFlow.',traceId},400)
    }

    const coreResponse = await fetch(`${url}/functions/v1/stockflow-staging-api`, {
      method: 'POST', headers: { 'content-type': 'application/json', 'apikey': publishable, 'x-stockflow-client': 'gateway-v3', ...(token ? { 'x-stockflow-session': token } : {}) }, body: JSON.stringify(body),
    })
    const text = await coreResponse.text(); let payload:any={}; try{payload=text?JSON.parse(text):{}}catch{payload={error:'Unreadable core response.'}}
    if(!coreResponse.ok&&!payload.traceId)payload.traceId=traceId
    return respond(payload,coreResponse.status)
  } catch (error) {
    console.error('StockFlow API v3 error', traceId, error)
    const status = Number((error as any)?.httpStatus ?? 500)
    return respond({ error: error instanceof Error ? error.message : 'Unexpected server error.', traceId }, status)
  }
})
