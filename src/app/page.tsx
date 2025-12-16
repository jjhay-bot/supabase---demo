"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabaseClient";
import { AuthForm } from "./AuthForm";

export default function Home() {
  const [session, setSession] = useState<
    Awaited<ReturnType<typeof supabase.auth.getSession>>["data"]["session"] | null
  >(null);
  const [loading, setLoading] = useState(true);
  console.log('session', session);

  useEffect(() => {
    let mounted = true;

    async function loadSession() {
      const {
        data: { session },
      } = await supabase.auth.getSession();

      console.log('session', session);

      if (!mounted) return;
      setSession(session);
      setLoading(false);
    }

    loadSession();

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, []);

  if (loading) {
    return (
      <main className="flex min-h-screen flex-col items-center justify-center p-4">
        <p className="text-sm text-gray-600">Loading...</p>
      </main>
    );
  }

  if (!session) {
    return (
      <main className="flex min-h-screen flex-col items-center justify-center p-4">
        <h1 className="mb-4 text-2xl font-bold">Welcome</h1>
        <p className="mb-4 text-sm text-gray-600">
          You are not signed in. Use the form below to sign in.
        </p>
        <AuthForm />
      </main>
    );
  }

  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-4">
      <h1 className="mb-4 text-2xl font-bold">You are signed in2</h1>
      <p className="mb-4 text-sm text-gray-600">
        Signed in as {session.user.email}
      </p>
      <button
        onClick={async () => {
          await supabase.auth.signOut();
        }}
        className="rounded-md bg-black px-4 py-2 text-sm font-medium text-white"
      >
        Sign out
      </button>
    </main>
  );
}
