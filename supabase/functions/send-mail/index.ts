import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import nodemailer from "https://cdn.skypack.dev/nodemailer@6.9.1";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const supabase = createClient(supabaseUrl, supabaseAnonKey);

// SMTP configuration – reuse the same you already have for verification e‑mail
const smtpHost = Deno.env.get("SMTP_HOST")!;
const smtpPort = Number(Deno.env.get("SMTP_PORT")!);
const smtpUser = Deno.env.get("SMTP_USER")!;
const smtpPass = Deno.env.get("SMTP_PASS")!;
const FROM_EMAIL = Deno.env.get("CONTACT_FROM_EMAIL") ?? smtpUser;

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

    const mailOptions = {
      from: `"TicketScan Contact" <${FROM_EMAIL}>`,
      to: smtpUser, // send to your support inbox (same as verification e‑mail)
      replyTo: `"${name}" <${email}>`,
      subject: `[TicketScan Contact] ${subject}`,
      text: `Name: ${name}\nE‑mail: ${email}\n\nMessage:\n${message}`,
    };

    const transporter = nodemailer.createTransport({
      host: smtpHost,
      port: smtpPort,
      secure: smtpPort === 465, // true for 465, false for other ports
      auth: {
        user: smtpUser,
        pass: smtpPass,
      },
    });

    await transporter.sendMail(mailOptions);

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
