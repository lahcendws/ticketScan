import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const supabase = createClient(supabaseUrl, supabaseAnonKey);

// SendGrid configuration – set SENDGRID_API_KEY and SENDGRID_FROM_EMAIL in Supabase env vars
const sendGridApiKey = Deno.env.get("SENDGRID_API_KEY")!;
const fromEmail = Deno.env.get("SENDGRID_FROM_EMAIL")!; // verified sender in SendGrid

serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { "Access-Control-Allow-Origin": "*" } });
  }

  try {
    const { name, email, subject, message } = await req.json();

    // Basic validation
    if (!name || !email || !subject || !message) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const personalizations = [{ to: [{ email: fromEmail }] }]; // send to support inbox
    const content = [
      {
        type: "text/plain",
        value: `Name: ${name}\nE-mail: ${email}\n\nMessage:\n${message}`,
      },
    ];

    const data = {
      personalizations,
      from: { email: fromEmail, name: "TicketScan Contact" },
      subject: `[TicketScan Contact] ${subject}`,
      content,
    };

    const response = await fetch("https://api.sendgrid.com/v3/mail/send", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${sendGridApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(data),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("SendGrid error:", errorText);
      return new Response(
        JSON.stringify({ error: `SendGrid error: ${response.status}` }),
        { status: 502, headers: { "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Error sending contact e‑mail:", err);
    return new Response(
      JSON.stringify({ error: (err as Error).message ?? String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
