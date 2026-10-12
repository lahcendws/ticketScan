import { createClient } from "npm:@supabase/supabase-js@2";

// ---------- Configuration ----------
const BUCKET = "tickets";
const TIMEZONE = "Europe/Paris";
const BATCH_SIZE = 100;        // tickets traités par lot
const REMOVE_CHUNK = 50;       // fichiers supprimés par appel Storage
const MAX_RUNTIME_MS = 90_000; // garde-fou : on s'arrête avant la limite de durée
const GRACE_DAYS = Number(Deno.env.get("GRACE_DAYS") ?? "0"); // délai de grâce optionnel

// ---------- Helpers ----------
function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// Comparaison en temps constant pour éviter les attaques par timing
function safeEqual(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const x = enc.encode(a);
  const y = enc.encode(b);
  if (x.length !== y.length) return false;
  let diff = 0;
  for (let i = 0; i < x.length; i++) diff |= x[i] ^ y[i];
  return diff === 0;
}

// Date seule (YYYY-MM-DD) : aujourd'hui à Paris, moins le délai de grâce.
// Un ticket est expiré uniquement si warranty_end_date est STRICTEMENT avant cette date,
// donc le dernier jour de garantie, le ticket est conservé.
function expirationCutoff(): string {
  const today = new Intl.DateTimeFormat("en-CA", { timeZone: TIMEZONE }).format(new Date());
  const d = new Date(`${today}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() - GRACE_DAYS);
  return d.toISOString().slice(0, 10);
}

// Accepte un chemin ("user/abc.jpg") ou une URL Supabase complète, renvoie un chemin
function toStoragePath(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const v = value.trim();
  if (!v) return null;

  if (/^https?:\/\//i.test(v)) {
    const m = v.match(
      new RegExp(`/storage/v1/object/(?:public|sign|authenticated)/${BUCKET}/([^?#]+)`),
    );
    if (!m) return null;
    try {
      return decodeURIComponent(m[1]);
    } catch {
      return m[1];
    }
  }
  return v.replace(/^\/+/, "");
}

// image_urls peut être un tableau, une chaîne JSON ou null
function extractPaths(raw: unknown): string[] {
  let list: unknown = raw;
  if (typeof raw === "string" && raw.trim().startsWith("[")) {
    try {
      list = JSON.parse(raw);
    } catch {
      list = [raw];
    }
  }
  if (typeof list === "string") list = [list];
  if (!Array.isArray(list)) return [];
  return list.map(toStoragePath).filter((p): p is string => !!p);
}

// ---------- Handler ----------
Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  // Authentification par secret partagé
  const cronSecret = Deno.env.get("CRON_SECRET");
  if (!cronSecret) {
    console.error("CRON_SECRET non défini");
    return json({ error: "Server misconfigured" }, 500);
  }
  const auth = req.headers.get("authorization") ?? "";
  if (!safeEqual(auth, `Bearer ${cronSecret}`)) {
    return json({ error: "Unauthorized" }, 401);
  }

  const dryRun = new URL(req.url).searchParams.get("dry_run") === "true";

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false, autoRefreshToken: false } },
  );

  const cutoff = expirationCutoff();
  const startedAt = Date.now();

  let ticketsDeleted = 0;
  let filesDeleted = 0;
  let batches = 0;
  const orphanPaths: string[] = [];  // fichiers dont la suppression a échoué
  const missingPaths: string[] = []; // chemins demandés mais introuvables dans le bucket
  let status: "done" | "timeout" | "storage_error" | "error" = "done";
  let errorMessage: string | undefined;

  try {
    while (true) {
      if (Date.now() - startedAt > MAX_RUNTIME_MS) {
        status = "timeout"; // le reste sera traité au prochain passage
        break;
      }

      // 1. Candidats : tickets dont la garantie s'est terminée avant aujourd'hui
      const { data: candidates, error: fetchError } = await supabase
        .from("tickets")
        .select("id, image_urls")
        .lt("warranty_end_date", cutoff)
        .order("warranty_end_date", { ascending: true })
        .limit(BATCH_SIZE);

      if (fetchError) throw fetchError;
      if (!candidates || candidates.length === 0) break;

      batches++;

      if (dryRun) {
        const paths = [...new Set(candidates.flatMap((t) => extractPaths(t.image_urls)))];
        return json({
          dryRun: true,
          cutoff,
          sampleBatch: { tickets: candidates.length, files: paths.length, paths: paths.slice(0, 20) },
        });
      }

      // 2. Suppression des LIGNES d'abord, avec le garde-fou, en récupérant ce qui a
      //    réellement été supprimé. Un ticket prolongé entre-temps n'est pas supprimé
      //    et n'apparaît donc pas dans `deleted` : ses photos ne seront pas touchées.
      const { data: deleted, error: deleteError } = await supabase
        .from("tickets")
        .delete()
        .in("id", candidates.map((t) => t.id))
        .lt("warranty_end_date", cutoff)
        .select("id, image_urls");

      if (deleteError) throw deleteError;
      ticketsDeleted += deleted?.length ?? 0;

      // 3. Suppression des FICHIERS uniquement pour les lignes réellement supprimées.
      //    Pire cas en cas d'échec : un fichier orphelin, jamais une photo perdue.
      const paths = [...new Set((deleted ?? []).flatMap((t) => extractPaths(t.image_urls)))];
      let storageFailed = false;

      for (let i = 0; i < paths.length; i += REMOVE_CHUNK) {
        const chunk = paths.slice(i, i + REMOVE_CHUNK);
        const { data: removed, error: removeError } = await supabase.storage
          .from(BUCKET)
          .remove(chunk);

        if (removeError) {
          storageFailed = true;
          orphanPaths.push(...chunk);
          console.error(`Storage remove failed: ${removeError.message}`);
        } else {
          const removedNames = new Set((removed ?? []).map((o) => o.name));
          filesDeleted += removedNames.size;
          missingPaths.push(...chunk.filter((p) => !removedNames.has(p)));
        }
      }

      // Si le Storage est en panne, on s'arrête pour ne pas créer d'orphelins en masse
      if (storageFailed) {
        status = "storage_error";
        break;
      }
    }
  } catch (err) {
    status = "error";
    errorMessage = err instanceof Error ? err.message : String(err);
    console.error("Purge interrompue:", errorMessage);
  }

  if (orphanPaths.length) {
    console.error("Fichiers orphelins à nettoyer:", JSON.stringify(orphanPaths));
  }
  if (missingPaths.length) {
    console.warn("Fichiers introuvables dans le bucket:", JSON.stringify(missingPaths));
  }

  const result = {
    status,
    cutoff,
    batches,
    ticketsDeleted,
    filesDeleted,
    missingFiles: missingPaths.length,
    missingPaths: missingPaths.slice(0, 100),
    orphanFiles: orphanPaths.length,
    orphanPaths: orphanPaths.slice(0, 100),
    durationMs: Date.now() - startedAt,
    ...(errorMessage ? { error: errorMessage } : {}),
  };

  console.log(JSON.stringify(result));
  return json(result, status === "error" || status === "storage_error" ? 500 : 200);
});