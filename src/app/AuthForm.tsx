"use client";

import { FormEvent, useState } from "react";
import { supabase } from "@/lib/supabaseClient";

export function AuthForm() {
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setMessage(null);
    setError(null);

    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: {
        emailRedirectTo:
          typeof window !== "undefined"
            ? `${window.location.origin}/`
            : undefined,
      },
    });

    setLoading(false);

    if (error) {
      setError(error.message);
    } else {
      setMessage("Check your email for a magic link to sign in.");
      setEmail("");
    }
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="flex w-full max-w-sm flex-col gap-3"
    >
      <label className="flex flex-col gap-1 text-sm">
        <span className="font-medium">Email</span>
        <input
          type="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-black focus:outline-none"
          placeholder="you@example.com"
        />
      </label>
      <button
        type="submit"
        disabled={loading}
        className="mt-1 inline-flex items-center justify-center rounded-md bg-black px-4 py-2 text-sm font-medium text-white disabled:opacity-60"
      >
        {loading ? "Sending magic link..." : "Send magic link"}
      </button>
      {message && <p className="text-xs text-green-600">{message}</p>}
      {error && <p className="text-xs text-red-600">{error}</p>}
    </form>
  );
}
