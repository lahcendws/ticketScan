const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");

const BREVO_API_KEY = Deno.env.get("BREVO_API_KEY");
const BREVO_FROM_EMAIL = Deno.env.get("BREVO_FROM_EMAIL");
const SUPPORT_TO_EMAIL = Deno.env.get("SUPPORT_TO_EMAIL");

const ALLOWED_ORIGINS = (Deno.env.get("ALLOWED_ORIGINS") ?? "")
  .split(",")
  .map((value) => value.trim())
  .filter(Boolean);

const MAX_BODY_BYTES = 10_000;
const MAX_NAME_LENGTH = 100;
const MAX_SUBJECT_LENGTH = 150;
const MAX_MESSAGE_LENGTH = 5_000;
const REQUEST_TIMEOUT_MS = 10_000;

const EMAIL_REGEX = /^[^\s@<>]+@[^\s@<>]+\.[^\s@<>]+$/;

function jsonResponse(
  status: number,
  body: Record<string, unknown>,
  headers: Record<string, string>,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...headers,
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
    },
  });
}

Deno.serve(async (req: Request) => {
  const origin = req.headers.get("origin");
  const originAllowed = Boolean(
    origin && ALLOWED_ORIGINS.includes(origin),
  );

  const corsHeaders: Record<string, string> = {
    "Vary": "Origin",
    ...(originAllowed && origin
      ? { "Access-Control-Allow-Origin": origin }
      : {}),
  };

  // CORS preflight
  if (req.method === "OPTIONS") {
    if (origin && !originAllowed) {
      return new Response(null, { status: 403 });
    }

    return new Response(null, {
      status: 204,
      headers: {
        ...corsHeaders,
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers":
          "authorization, apikey, content-type, x-client-info",
        "Access-Control-Max-Age": "86400",
      },
    });
  }

  if (req.method !== "POST") {
    return jsonResponse(
      405,
      { error: "Méthode non autorisée." },
      { ...corsHeaders, "Allow": "POST, OPTIONS" },
    );
  }

  // CORS n'est pas un mécanisme d'authentification.
  // Les clients mobiles sans Origin restent soumis à l'authentification.
  if (origin && !originAllowed) {
    return jsonResponse(
      403,
      { error: "Origine non autorisée." },
      corsHeaders,
    );
  }

  // Vérification de la configuration serveur
  if (
    !SUPABASE_URL ||
    !SUPABASE_ANON_KEY ||
    !BREVO_API_KEY ||
    !BREVO_FROM_EMAIL ||
    !SUPPORT_TO_EMAIL
  ) {
    console.error("send-mail: configuration serveur incomplète.");

    return jsonResponse(
      500,
      { error: "Le service de contact est indisponible." },
      corsHeaders,
    );
  }

  // Vérification du jeton Supabase de l'utilisateur
  const authorization = req.headers.get("Authorization");
  const tokenMatch = authorization?.match(/^Bearer\s+(\S+)$/i);

  if (!tokenMatch) {
    return jsonResponse(
      401,
      { error: "Authentification requise." },
      corsHeaders,
    );
  }

  let user: { id: string; email?: string };

  const authController = new AbortController();
  const authTimeout = setTimeout(
    () => authController.abort(),
    REQUEST_TIMEOUT_MS,
  );

  try {
    const authResponse = await fetch(
      `${SUPABASE_URL}/auth/v1/user`,
      {
        method: "GET",
        headers: {
          apikey: SUPABASE_ANON_KEY,
          Authorization: `Bearer ${tokenMatch[1]}`,
        },
        signal: authController.signal,
      },
    );

    if (authResponse.status === 401 ||
        authResponse.status === 403) {
      return jsonResponse(
        401,
        { error: "Session invalide ou expirée." },
        corsHeaders,
      );
    }

    if (!authResponse.ok) {
      console.error("send-mail: vérification utilisateur indisponible.");

      return jsonResponse(
        503,
        { error: "Service temporairement indisponible." },
        corsHeaders,
      );
    }

    const authUser = await authResponse.json();

    if (
      typeof authUser.id !== "string" ||
      typeof authUser.email !== "string" ||
      !EMAIL_REGEX.test(authUser.email)
    ) {
      return jsonResponse(
        401,
        { error: "Compte utilisateur invalide." },
        corsHeaders,
      );
    }

    user = {
      id: authUser.id,
      email: authUser.email,
    };
  } catch {
    console.error("send-mail: échec de vérification de session.");

    return jsonResponse(
      503,
      { error: "Service temporairement indisponible." },
      corsHeaders,
    );
  } finally {
    clearTimeout(authTimeout);
  }

  // Accepter uniquement du JSON
  const contentType = req.headers.get("content-type") ?? "";

  if (!contentType.toLowerCase().includes("application/json")) {
    return jsonResponse(
      415,
      { error: "Le format attendu est application/json." },
      corsHeaders,
    );
  }

  const contentLength = req.headers.get("content-length");

  if (
    contentLength &&
    (!/^\d+$/.test(contentLength) ||
      Number(contentLength) > MAX_BODY_BYTES)
  ) {
    return jsonResponse(
      413,
      { error: "La demande est trop volumineuse." },
      corsHeaders,
    );
  }

  let rawBody: string;

  try {
    rawBody = await req.text();
  } catch {
    return jsonResponse(
      400,
      { error: "Corps de requête invalide." },
      corsHeaders,
    );
  }

  if (new TextEncoder().encode(rawBody).byteLength > MAX_BODY_BYTES) {
    return jsonResponse(
      413,
      { error: "La demande est trop volumineuse." },
      corsHeaders,
    );
  }

  let payload: unknown;

  try {
    payload = JSON.parse(rawBody);
  } catch {
    return jsonResponse(
      400,
      { error: "JSON invalide." },
      corsHeaders,
    );
  }

  if (
    !payload ||
    typeof payload !== "object" ||
    Array.isArray(payload)
  ) {
    return jsonResponse(
      400,
      { error: "Données de contact invalides." },
      corsHeaders,
    );
  }

  const input = payload as Record<string, unknown>;

  if (
    typeof input.name !== "string" ||
    typeof input.subject !== "string" ||
    typeof input.message !== "string"
  ) {
    return jsonResponse(
      400,
      { error: "Nom, sujet et message sont obligatoires." },
      corsHeaders,
    );
  }

  const name = input.name.trim().replace(/\s+/g, " ");
  const subject = input.subject.trim().replace(/\s+/g, " ");
  const message = input.message.trim();

  if (
    !name ||
    !subject ||
    !message ||
    name.length > MAX_NAME_LENGTH ||
    subject.length > MAX_SUBJECT_LENGTH ||
    message.length > MAX_MESSAGE_LENGTH
  ) {
    return jsonResponse(
      400,
      { error: "Vérifiez les champs et leurs longueurs." },
      corsHeaders,
    );
  }

  // Éviter l'injection de caractères de contrôle dans les en-têtes.
  const hasControlCharacters = (value: string) =>
    /[\u0000-\u001F\u007F]/.test(value);

  if (
    hasControlCharacters(name) ||
    hasControlCharacters(subject)
  ) {
    return jsonResponse(
      400,
      { error: "Certains caractères ne sont pas autorisés." },
      corsHeaders,
    );
  }

  // L'adresse de réponse provient du compte authentifié,
  // jamais d'une adresse arbitraire envoyée par le client.
  const emailPayload = {
    sender: {
      name: "TicketScan - Support",
      email: BREVO_FROM_EMAIL,
    },
    to: [
      {
        email: SUPPORT_TO_EMAIL,
      },
    ],
    replyTo: {
      email: user.email,
      name,
    },
    subject: `[TicketScan Support] ${subject}`,
    textContent: [
      "Nouveau message depuis le support TicketScan",
      "",
      `Nom : ${name}`,
      `E-mail du compte : ${user.email}`,
      `Identifiant utilisateur : ${user.id}`,
      "",
      "Message :",
      message,
    ].join("\n"),
  };

  const mailController = new AbortController();
  const mailTimeout = setTimeout(
    () => mailController.abort(),
    REQUEST_TIMEOUT_MS,
  );

  try {
    const response = await fetch(
      "https://api.brevo.com/v3/smtp/email",
      {
        method: "POST",
        headers: {
          "api-key": BREVO_API_KEY,
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: JSON.stringify(emailPayload),
        signal: mailController.signal,
      },
    );

    if (!response.ok) {
      // Ne jamais journaliser la clé API ou le contenu du message.
      const errorText = await response.text();
      console.error("send-mail: erreur du fournisseur Brevo.", {
        status: response.status,
        body: errorText.substring(0, 200), // truncate to avoid logging too much
      });

      return jsonResponse(
        502,
        { error: "Envoi impossible. Réessayez ultérieurement." },
        corsHeaders,
      );
    }

    console.info("send-mail: demande acceptée par Brevo.");

    return jsonResponse(
      200,
      {
        success: true,
        message: "Votre message a été transmis au support.",
      },
      corsHeaders,
    );
  } catch (error) {
    const timedOut =
      error instanceof DOMException &&
      error.name === "AbortError";

    console.error(
      timedOut
        ? "send-mail: délai de réponse de Brevo dépassé."
        : "send-mail: erreur de communication avec Brevo.",
    );

    return jsonResponse(
      502,
      {
        error: "Service d'envoi temporairement indisponible.",
      },
      corsHeaders,
    );
  } finally {
    clearTimeout(mailTimeout);
  }
});
