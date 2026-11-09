#include <metal_stdlib>
using namespace metal;

// Layouts must match Renderer.swift.
struct Uniforms {
    float time, aspect, focal, camY, horizon, fogK, fade, seed;
    float2 viewport;
    float2 worldHalf;
};

struct Sprite {
    float4 pos;   // world x, y, z, rotation
    float4 size;  // half w, half h, x scale (signed), anchor (0 center, 1 base)
    float4 uv;    // u0, v0, u1, v1
    float4 anim;  // mode, phase, amp, lod bias
    float4 look;  // alpha, caustic amount, depth test (0/1), wave param
    float4 tint;  // rgb multiply, shade strength
};

constexpr sampler linearRepeat(address::repeat, filter::linear, mip_filter::linear);
constexpr sampler linearClamp(address::clamp_to_edge, filter::linear, mip_filter::linear);
constexpr sampler nearestClamp(address::clamp_to_edge, filter::nearest);

// ---- shared helpers ----

static float hash21(float2 p) {
    uint2 q = uint2(int2(floor(p)) + int2(32768));
    q = q * uint2(1597334673u, 3812015801u);
    uint n = (q.x ^ q.y) * 1597334673u;
    return float(n) * (1.0 / 4294967295.0);
}

static float2 hash22(float2 p) {
    return float2(hash21(p), hash21(p + float2(37.0, 17.0)));
}

static float vnoise(float2 p) {
    float2 i = floor(p), f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + float2(1, 0)), u.x),
               mix(hash21(i + float2(0, 1)), hash21(i + float2(1, 1)), u.x), u.y);
}

static float fbm(float2 p, int oct) {
    float a = 0.5, s = 0.0, n = 0.0;
    for (int i = 0; i < oct; i++) {
        s += a * vnoise(p);
        n += a;
        a *= 0.5;
        p = float2(p.x * 1.6 - p.y * 1.2, p.x * 1.2 + p.y * 1.6) + 11.3;
    }
    return s / n;
}

static float3 waterColor(float y) {
    float t = saturate(y * 0.5 + 0.5);
    const float3 deep = float3(0.016, 0.100, 0.150);
    const float3 mid  = float3(0.045, 0.245, 0.310);
    const float3 top  = float3(0.235, 0.560, 0.590);
    if (t < 0.55) return mix(deep, mid, smoothstep(0.0, 0.55, t));
    return mix(mid, top, pow((t - 0.55) / 0.45, 1.5));
}

static float3 applyWater(float3 c, float z, float ndcY, float fogK) {
    c *= exp(-z * float3(0.055, 0.014, 0.010));
    return mix(c, waterColor(ndcY), 1.0 - exp(-z * fogK));
}

// ---- fullscreen triangle ----

struct FSOut { float4 position [[position]]; float2 ndc; };

vertex FSOut fullscreenVS(uint vid [[vertex_id]]) {
    float2 p = float2((vid << 1) & 2, vid & 2) * 2.0 - 1.0;
    FSOut o;
    o.position = float4(p, 0, 1);
    o.ndc = p;
    return o;
}

// ---- terrain bake ----

static float2 terrainAt(texture2d<float, access::read> tex, float2 world, float2 extent) {
    float2 size = float2(tex.get_width(), tex.get_height());
    float2 g = float2((world.x + extent.x) / (2.0 * extent.x), world.y / extent.y) * (size - 1.0);
    g = clamp(g, float2(0.0), size - 1.001);
    uint2 i = uint2(g);
    float2 f = g - float2(i);
    float2 a = tex.read(i).rg;
    float2 b = tex.read(i + uint2(1, 0)).rg;
    float2 c = tex.read(i + uint2(0, 1)).rg;
    float2 d = tex.read(i + uint2(1, 1)).rg;
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

static float detailCoarse(float2 p, float rock) {
    return rock * ((fbm(p * 1.4, 4) - 0.5) * 1.15);
}

static float detailFine(float2 p, float rock, float z) {
    float fine = rock * (fbm(p * 6.0, 3) - 0.5) * 0.07;
    float lod = saturate(1.0 - z / 22.0);
    float warp = fbm(p * 0.7, 2) * 9.0;
    float ripple = (1.0 - rock) * (sin(p.y * 15.0 + warp) * 0.007 + (fbm(p * 22.0, 2) - 0.5) * 0.008);
    return fine + ripple * lod;
}

static float fullHeight(texture2d<float, access::read> tex, float2 q, float2 extent, float z) {
    float2 t = terrainAt(tex, q, extent);
    return t.x + detailCoarse(q, t.y) + detailFine(q, t.y, z);
}

struct BakeOut {
    float4 color [[color(0)]];
    float depth [[color(1)]];
};

fragment BakeOut bakeFS(FSOut in [[stage_in]],
                        constant Uniforms &U [[buffer(0)]],
                        texture2d<float, access::read> height [[texture(0)]]) {
    BakeOut out;
    float2 ndc = in.ndc;
    float dx = ndc.x * U.aspect / U.focal;
    float dy = (ndc.y - U.horizon) / U.focal;
    float2 worldHalf = U.worldHalf;

    float hitZ = -1.0;
    float z = 1.8, prevZ = z;
    for (int i = 0; i < 120 && z < worldHalf.y * 0.98; i++) {
        float2 p = float2(dx * z, z);
        float2 tr = terrainAt(height, p, worldHalf);
        float y = U.camY + dy * z;
        float h = tr.x + detailCoarse(p, tr.y);
        if (y < h) {
            float lo = prevZ, hi = z;
            for (int k = 0; k < 7; k++) {
                float m = 0.5 * (lo + hi);
                float2 q = float2(dx * m, m);
                float2 t2 = terrainAt(height, q, worldHalf);
                float hm = t2.x + detailCoarse(q, t2.y);
                if (U.camY + dy * m < hm) hi = m; else lo = m;
            }
            hitZ = hi;
            break;
        }
        prevZ = z;
        z *= 1.033;
    }

    float dither = (hash21(in.position.xy) - 0.5) / 255.0;
    if (hitZ < 0.0) {
        float3 w = waterColor(ndc.y);
        w *= 0.97 + 0.06 * fbm(float2(ndc.x * 1.5, ndc.y * 2.5) + U.seed, 3);
        out.color = float4(w + dither, 0.0);
        out.depth = 1.0e4;
        return out;
    }

    float2 p = float2(dx * hitZ, hitZ);
    float2 tr = terrainAt(height, p, worldHalf);
    float rock = tr.y;

    float e = max(0.012, hitZ * 0.0022);
    float h0 = fullHeight(height, p, worldHalf, hitZ);
    float hx = fullHeight(height, p + float2(e, 0), worldHalf, hitZ);
    float hz = fullHeight(height, p + float2(0, e), worldHalf, hitZ);
    float3 n = normalize(float3(h0 - hx, e, h0 - hz));

    // Offsetting by height stops rock textures stretching down steep faces.
    float2 rp = float2(p.x, p.y + h0 * 1.6);

    // Rock relief as a normal perturbation in that domain. Displacing the height
    // instead makes the noise frequency grow with slope, which reads as contour bands.
    float bumpE = max(0.01, hitZ * 0.0016);
    float b0 = fbm(rp * 4.0, 5);
    float bu = fbm((rp + float2(bumpE, 0.0)) * 4.0, 5);
    float bv = fbm((rp + float2(0.0, bumpE)) * 4.0, 5);
    float2 slope = float2(b0 - bu, b0 - bv) / bumpE;
    float rockAmt = smoothstep(0.25, 0.7, rock);
    n = normalize(n + rockAmt * 0.13 * float3(slope.x, slope.y * (1.0 - n.y), slope.y * n.y));

    // Albedo: rock with coralline crust and algae film, sand with shell grit, mud far out.
    float g = fbm(rp * 3.2, 5);
    float3 rockCol = mix(float3(0.27, 0.27, 0.27), float3(0.58, 0.57, 0.53), g);
    float crust = smoothstep(0.46, 0.60, fbm(rp * 1.1 + 7.0, 4));
    float3 coralline = mix(float3(0.62, 0.36, 0.42), float3(0.78, 0.55, 0.57), fbm(rp * 14.0, 2));
    rockCol = mix(rockCol, coralline, crust * 0.85);
    float film = smoothstep(0.52, 0.70, fbm(rp * 2.3 + 31.0, 3));
    rockCol = mix(rockCol, float3(0.20, 0.17, 0.09), film * (1.0 - crust) * 0.75);
    float pale = smoothstep(0.62, 0.74, fbm(rp * 18.0 + 3.0, 2));
    rockCol += pale * 0.05;

    float grain = fbm(p * 26.0, 3);
    float3 sandCol = mix(float3(0.50, 0.46, 0.37), float3(0.72, 0.67, 0.56), grain);
    sandCol *= 0.86 + 0.28 * fbm(p * 0.8 + 5.0, 3);
    float2 cell = floor(p * 16.0);
    float2 r = hash22(cell);
    float size = 0.05 + 0.15 * hash21(cell + 5.0) * hash21(cell + 6.0) * 2.0;
    float dot1 = 1.0 - smoothstep(size * 0.5, size, length(fract(p * 16.0) - 0.2 - r * 0.6));
    // Patchy, not an even speckle: shell hash collects in low drifts.
    float drift = smoothstep(0.42, 0.68, fbm(p * 0.9 + 21.0, 3));
    float keep = step(0.90 - drift * 0.22, hash21(cell + 91.0));
    float tone = hash21(cell + 13.0);
    float3 grit = tone > 0.5 ? float3(0.88, 0.85, 0.76) : float3(0.27, 0.25, 0.23);
    sandCol = mix(sandCol, grit, dot1 * keep * saturate(1.0 - hitZ / 12.0) * 0.62);
    float2 stoneCell = floor(p * 2.7);
    float2 sr = hash22(stoneCell + 3.0);
    float stoneR = 0.04 + 0.12 * hash21(stoneCell + 8.0);
    float stone = 1.0 - smoothstep(stoneR * 0.7, stoneR, length((fract(p * 2.7) - 0.15 - sr * 0.7) * float2(1.0, 1.3)));
    float stoneKeep = step(0.74, hash21(stoneCell + 44.0));
    float3 stoneCol = mix(float3(0.26, 0.26, 0.27), float3(0.56, 0.52, 0.47), hash21(stoneCell + 2.0));
    sandCol = mix(sandCol, stoneCol, stone * stoneKeep * saturate(1.0 - hitZ / 16.0));
    sandCol = mix(sandCol, float3(0.34, 0.33, 0.28), smoothstep(10.0, 30.0, hitZ));

    // Cracks and fissures read better than smooth shading on the boulders.
    float crack = smoothstep(0.016, 0.0, abs(fbm(rp * 3.1 + 51.0, 5) - 0.5));
    rockCol *= 1.0 - crack * 0.22;
    rockCol *= 0.82 + 0.36 * fbm(rp * 9.0 + 77.0, 4);

    float3 albedo = mix(sandCol, rockCol, smoothstep(0.25, 0.7, rock));

    float3 L = normalize(float3(0.25, 0.92, 0.22));
    float ndl = saturate(dot(n, L));

    // Short shadow march along the sun.
    float shadow = 1.0;
    float3 sp = float3(p.x, h0 + 0.03, p.y);
    float st = 0.12;
    for (int i = 0; i < 9; i++) {
        float3 q = sp + L * st;
        float2 t = terrainAt(height, q.xz, worldHalf);
        float hq = t.x + detailCoarse(q.xz, t.y);
        shadow = min(shadow, saturate(1.0 + 7.0 * (q.y - hq) / st * 0.2));
        st *= 1.5;
    }

    // Ambient occlusion from surrounding height.
    float ao = 0.0;
    const float2 dirs[6] = { float2(1, 0), float2(0.5, 0.87), float2(-0.5, 0.87),
                             float2(-1, 0), float2(-0.5, -0.87), float2(0.5, -0.87) };
    for (int i = 0; i < 6; i++) {
        float2 t = terrainAt(height, p + dirs[i] * 0.55, worldHalf);
        ao += saturate((t.x + detailCoarse(p + dirs[i] * 0.55, t.y) - h0) / 0.55);
    }
    ao = saturate(1.0 - ao / 6.0 * 1.2);

    float3 lit = albedo * (float3(0.46, 0.60, 0.64) * (0.55 + 0.45 * n.y) * ao
                           + float3(0.86, 0.98, 0.98) * ndl * shadow);
    float3 col = applyWater(lit, hitZ, ndc.y, U.fogK);

    // Caustics focus near the viewer and on open floor; on far rock they read as noise.
    float mask = saturate(n.y) * shadow * (1.0 - smoothstep(9.0, 22.0, hitZ)) * (1.0 - 0.55 * smoothstep(0.25, 0.7, rock));
    out.color = float4(col + dither, mask);
    out.depth = hitZ;
    return out;
}

// ---- caustics: drifting Voronoi edges, tiling ----

static float cellEdge(float2 uv, float cells, float t) {
    float2 p = uv * cells;
    float2 c = floor(p), f = p - c;
    float f1 = 8.0, f2 = 8.0;
    for (int y = -1; y <= 1; y++) for (int x = -1; x <= 1; x++) {
        float2 o = float2(x, y);
        float2 g = c + o;
        float2 wrapped = g - cells * floor(g / cells);
        float2 r = hash22(wrapped + cells * 7.0);
        float2 pt = 0.5 + 0.42 * sin(t * (0.45 + r.yx * 0.5) + 6.2831 * r);
        float d = length(o + pt - f);
        if (d < f1) { f2 = f1; f1 = d; } else if (d < f2) { f2 = d; }
    }
    return f2 - f1;
}

fragment float4 causticFS(FSOut in [[stage_in]], constant Uniforms &U [[buffer(0)]]) {
    float2 uv = in.ndc * 0.5 + 0.5;
    float t = U.time;
    const float tau = 6.2831853;
    float2 w = uv + 0.035 * float2(sin(tau * (2.0 * uv.y) + t * 0.31), sin(tau * (2.0 * uv.x) - t * 0.27))
                  + 0.012 * float2(sin(tau * (5.0 * uv.y) - t * 0.53), sin(tau * (5.0 * uv.x) + t * 0.47));
    float a = cellEdge(w, 5.0, t * 0.9);
    float b = cellEdge(w.yx + 0.37, 8.0, t * 1.2);
    float c = pow(1.0 - smoothstep(0.0, 0.17, a), 2.4) + 0.55 * pow(1.0 - smoothstep(0.0, 0.13, b), 2.2);
    return float4(saturate(c));
}

// ---- runtime backdrop ----

static float causticAt(texture2d<float> tex, float2 xz, float t) {
    float a = tex.sample(linearRepeat, xz * 0.21 + float2(t * 0.004, t * 0.006)).r;
    float b = tex.sample(linearRepeat, xz * 0.087 + float2(-t * 0.003, t * 0.002)).r;
    return a * (0.45 + b * 1.2);
}

fragment float4 backdropFS(FSOut in [[stage_in]],
                           constant Uniforms &U [[buffer(0)]],
                           texture2d<float> color [[texture(0)]],
                           texture2d<float> depth [[texture(1)]],
                           texture2d<float> caustic [[texture(2)]]) {
    float2 uv = float2(in.ndc.x * 0.5 + 0.5, 0.5 - in.ndc.y * 0.5);
    float4 c = color.sample(linearClamp, uv);
    float z = depth.sample(nearestClamp, uv).r;
    float3 rgb = c.rgb;
    if (z < 1000.0 && c.a > 0.001) {
        float2 xz = float2(in.ndc.x * U.aspect / U.focal * z, z);
        float k = causticAt(caustic, xz, U.time);
        rgb += c.a * k * float3(0.24, 0.36, 0.34);
    }
    return float4(rgb, 1.0);
}

// ---- sprites ----

struct SpriteOut {
    float4 position [[position]];
    float2 uv;
    float2 cell;
    float3 world;
    float2 ndc;
    float shade;
    float lod;
    float alpha;
    float causticAmt;
    float depthTest;
    float3 tint;
    float isFlat;
};

vertex SpriteOut spriteVS(uint vid [[vertex_id]],
                          uint iid [[instance_id]],
                          constant packed_float2 *grid [[buffer(0)]],
                          constant Sprite *sprites [[buffer(1)]],
                          constant Uniforms &U [[buffer(2)]]) {
    Sprite s = sprites[iid];
    float2 g = float2(grid[vid]);
    float hw = s.size.x, hh = s.size.y;
    float2 p = float2((g.x - 0.5) * 2.0 * hw, (0.5 - g.y) * 2.0 * hh);
    int mode = int(s.anim.x + 0.5);
    float phase = s.anim.y, amp = s.anim.z;
    float shade = 1.0;

    if (mode == 1) {            // fish, head at +x
        float t = 1.0 - g.x;
        float k = s.look.w > 0.0 ? s.look.w : 6.5;
        float ph = k * t - phase;
        float A = amp * (0.035 + t * t * 0.95);
        float w = sin(ph);
        float lateral = A * w;
        p.x += 2.0 * hw * (lateral * 0.16 + t * t * 0.16 * amp * w * w);
        p.y += 2.0 * hw * lateral * 0.075;
        shade = 1.0 + clamp(amp * (0.3 + t * 1.6) * cos(ph) * 0.45, -0.30, 0.30);
    } else if (mode == 2) {     // plant, anchored at base
        float t = 1.0 - g.y;
        float bend = amp * pow(t, 1.5) * (sin(phase + t * 2.4) + 0.4 * sin(phase * 1.7 + t * 6.0 + s.pos.x));
        p.x += bend * 2.0 * hh;
        p.x += s.look.w * sin(g.y * 16.0 + phase * 1.6) * t * hw;
        shade = 1.0 + 0.14 * sin(phase + t * 5.0 + g.x * 3.0);
    } else if (mode == 3) {     // ray or flatfish wing ripple
        float t = 1.0 - g.x;
        float wing = abs(2.0 * g.y - 1.0);
        float ph = 5.0 * t - phase;
        float k = amp * pow(wing, 1.2);
        p.y += sin(ph) * k * 2.0 * hh * 0.30;
        shade = 1.0 + clamp(cos(ph) * k * (g.y < 0.5 ? 1.0 : -1.0) * 0.8, -0.3, 0.3);
    } else if (mode == 4) {     // jellyfish
        float bell = 1.0 - smoothstep(0.28, 0.5, g.y);
        float pulse = sin(phase) * amp;
        p.x *= 1.0 - pulse * bell * 0.20;
        p.y += hh * pulse * bell * 0.10;
        float w = saturate((g.y - 0.3) / 0.7);
        p.x += sin(g.y * 9.0 - phase * 0.8 + g.x * 5.0) * w * w * hw * 0.28;
        p.y *= 1.0 - 0.07 * pulse * w;
    } else if (mode == 5) {     // anemone or soft crown
        float t = 1.0 - g.y;
        p.x += amp * pow(t, 1.8) * sin(phase * 0.6 + s.pos.x) * 2.0 * hh;
        float crown = smoothstep(0.5, 0.0, g.y);
        p.x += sin(g.x * 22.0 + phase * 1.9) * crown * hw * 0.035;
        p.y += cos(g.x * 17.0 + phase * 1.4) * crown * hh * 0.022;
    }

    SpriteOut o;
    float2 ndc;
    if (mode == 9) {            // screen space, pos.xy in ndc
        ndc = s.pos.xy + float2(p.x / U.aspect, p.y);
        o.world = float3(0, 0, 0);
        o.isFlat = 1.0;
    } else {
        if (s.size.w > 0.5) p.y += hh;
        float cr = cos(s.pos.w), sr = sin(s.pos.w);
        p = float2(p.x * cr - p.y * sr, p.x * sr + p.y * cr);
        p.x *= s.size.z;
        float3 world = float3(s.pos.x + p.x, s.pos.y + p.y, s.pos.z);
        o.world = world;
        ndc = float2(world.x * U.focal / (world.z * U.aspect),
                     U.horizon + (world.y - U.camY) * U.focal / world.z);
        o.isFlat = 0.0;
    }
    o.position = float4(ndc, 0, 1);
    o.ndc = ndc;
    o.uv = float2(mix(s.uv.x, s.uv.z, g.x), mix(s.uv.y, s.uv.w, g.y));
    o.cell = g;
    o.shade = mix(1.0, shade, s.tint.w);
    o.lod = s.anim.w;
    o.alpha = s.look.x;
    o.causticAmt = s.look.y;
    o.depthTest = s.look.z;
    o.tint = s.tint.rgb;
    return o;
}

fragment float4 spriteFS(SpriteOut in [[stage_in]],
                         constant Uniforms &U [[buffer(0)]],
                         texture2d<float> atlas [[texture(0)]],
                         texture2d<float> depth [[texture(1)]],
                         texture2d<float> caustic [[texture(2)]]) {
    float4 c = atlas.sample(linearClamp, in.uv, bias(in.lod));
    if (c.a < 0.003) discard_fragment();
    if (in.isFlat > 0.5) return c * in.alpha;

    float z = in.world.z;
    float vis = 1.0;
    if (in.depthTest > 0.5) {
        float2 suv = float2(in.ndc.x * 0.5 + 0.5, 0.5 - in.ndc.y * 0.5);
        float tz = depth.sample(nearestClamp, suv).r;
        vis = smoothstep(-0.40, 0.05, tz - z);
    }
    if (vis <= 0.0) discard_fragment();

    // Blurred mips spread to the cell border, so fade there rather than cut.
    if (in.lod > 0.4) {
        float w = 0.02 + in.lod * 0.035;
        c *= smoothstep(0.0, w, in.cell.x) * smoothstep(0.0, w, 1.0 - in.cell.x) * smoothstep(0.0, w, in.cell.y);
    }

    float3 rgb = c.rgb * in.tint * in.shade;
    if (in.causticAmt > 0.0) {
        float k = causticAt(caustic, float2(in.world.x + in.world.y * 0.3, z + in.world.y * 0.5), U.time);
        rgb += c.a * k * in.causticAmt * float3(0.34, 0.50, 0.47);
    }
    float a = c.a;
    float3 unpremul = a > 0.0 ? rgb / a : rgb;
    float3 fogged = applyWater(unpremul, z, in.ndc.y, U.fogK);
    return float4(fogged * a, a) * vis * in.alpha;
}

// ---- marine snow ----

struct SnowOut {
    float4 position [[position]];
    float size [[point_size]];
    float2 ndc;
    float z;
    float alpha;
    float soft;
};

vertex SnowOut snowVS(uint vid [[vertex_id]], constant Uniforms &U [[buffer(0)]]) {
    float id = float(vid);
    float2 r1 = hash22(float2(id, 3.0));
    float2 r2 = hash22(float2(id, 19.0));
    float2 r3 = hash22(float2(id, 57.0));
    float z = mix(2.0, 28.0, r2.x * r2.x);
    float t = U.time;
    float fx = fract(r1.x + t * (0.0035 + 0.003 * r3.x) / (0.3 + z * 0.06) + 0.012 * sin(t * 0.25 + id));
    float fy = fract(r1.y - t * (0.006 + 0.008 * r3.y) / (0.4 + z * 0.07) + 0.006 * sin(t * 0.33 + id * 1.7));
    float2 ndc = float2(fx, fy) * 2.2 - 1.1;
    SnowOut o;
    o.position = float4(ndc, 0, 1);
    o.ndc = ndc;
    o.z = z;
    float radius = (0.004 + 0.010 * r3.x * r3.x) * U.focal / z * U.viewport.y * 0.5;
    float blur = z < 4.0 ? (4.0 - z) * 1.4 : 0.0;
    o.size = clamp(radius * 2.0 + blur * U.viewport.y / 1400.0 * 2.0, 1.4, 40.0);
    o.soft = saturate(blur / 3.0);
    o.alpha = (0.14 + 0.36 * r2.y) * exp(-z * 0.075) * mix(1.0, 0.45, o.soft);
    return o;
}

fragment float4 snowFS(SnowOut in [[stage_in]],
                       float2 pc [[point_coord]],
                       constant Uniforms &U [[buffer(0)]],
                       texture2d<float> depth [[texture(1)]]) {
    float d = length(pc - 0.5) * 2.0;
    float a = (1.0 - smoothstep(mix(0.45, 0.0, in.soft), 1.0, d)) * in.alpha;
    if (a < 0.002) discard_fragment();
    float2 suv = float2(in.ndc.x * 0.5 + 0.5, 0.5 - in.ndc.y * 0.5);
    if (depth.sample(nearestClamp, suv).r < in.z) discard_fragment();
    return float4(float3(0.78, 0.88, 0.84) * a, a);
}

// ---- overlay: god rays, vignette, fade ----

static float rayNoise(float x, float t) {
    float a = vnoise(float2(x, t));
    return a * a;
}

fragment float4 overlayFS(FSOut in [[stage_in]], constant Uniforms &U [[buffer(0)]]) {
    float2 p = in.ndc;
    float t = U.time;
    float sx = 0.25 * U.aspect + 0.12 * sin(t * 0.021);
    float sy = 2.4;
    float a = (p.x * U.aspect - sx) / (sy - p.y);
    float r = rayNoise(a * 7.0 + U.seed, t * 0.055) * 0.65
            + rayNoise(a * 17.0 - 4.0, t * 0.085) * 0.35
            + rayNoise(a * 37.0 + 9.0, t * 0.13) * 0.14;
    float fall = pow(saturate(p.y * 0.55 + 0.72), 1.7);
    float3 rays = float3(0.50, 0.78, 0.76) * smoothstep(0.08, 0.75, r) * fall * 0.26;

    float2 v = float2(p.x, p.y * 1.05);
    float vig = smoothstep(0.75, 1.65, length(v)) * 0.42;
    float noise = hash21(in.position.xy + fract(t) * 311.0) * 1.6 / 255.0;
    float alpha = 1.0 - (1.0 - vig) * U.fade;
    return float4((rays + noise) * U.fade, alpha);
}
