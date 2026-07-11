// FreeNewsApi settings (set these as Edge Function secrets/env vars)
const NEWS_API_URL = Deno.env.get("https://api.freenewsapi.io/v1/news");
const NEWS_API_KEY = Deno.env.get("3af3b3a9d3fc0d3b6545b8e4422fe07b047d3390447528d6d5fa8fbd3c095fc5");

// Supabase credentials (provided to Edge Functions)
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

function requireEnv(name: string, value: string | undefined) {
  if (!value) {
    throw new Error(`Missing env var: ${name}`);
  }
  return value;
}

const newsApiUrl = requireEnv("NEWS_API_URL", NEWS_API_URL);
requireEnv("NEWS_API_KEY", NEWS_API_KEY);
requireEnv("SUPABASE_URL", SUPABASE_URL);
requireEnv("SUPABASE_SERVICE_ROLE_KEY", SUPABASE_SERVICE_ROLE_KEY);

const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!, {
  auth: { persistSession: false },
});

type FreeNewsArticle = {
  title: string;
  description?: string;
  url: string;
  source?: string;
  published_at?: string;
};

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "GET") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const url = new URL(newsApiUrl);

    url.searchParams.set("country", "pt");
    url.searchParams.set("language", "pt");
    url.searchParams.set(
      "q",
      "combustíveis OR gasolina OR gasóleo OR energia",
    );
    url.searchParams.set("page_size", "20");

    const externalRes = await fetch(url.toString(), {
      headers: {
        "x-api-key": requireEnv("NEWS_API_KEY", NEWS_API_KEY),
        Accept: "application/json",
      },
    });

    if (!externalRes.ok) {
      console.error(
        "FreeNewsApi error",
        externalRes.status,
        await externalRes.text(),
      );
      return new Response("Erro ao obter notícias externas", { status: 502 });
    }

    const externalJson: any = await externalRes.json();
    const rawArticles: any[] = externalJson.news ?? externalJson.articles ?? [];

    const articles: FreeNewsArticle[] = rawArticles.map((a: any) => ({
      title: a.title,
      description: a.description,
      url: a.url,
      source: a.source ?? a.source_name ?? "Desconhecido",
      published_at: a.published_at ?? a.publishedAt ?? a.date,
    }));

    const rows = articles
      .filter((a) => a.title && a.url)
      .map((a) => ({
        title: a.title,
        source: a.source ?? "Desconhecido",
        url: a.url,
        published_at: a.published_at
          ? new Date(a.published_at).toISOString()
          : new Date().toISOString(),
        country: "pt",
        tags: ["combustiveis", "energia"],
      }));

    if (rows.length > 0) {
      const { error: upsertError } = await supabase
        .from("news_cache")
        .upsert(rows, { onConflict: "url" });

      if (upsertError) {
        console.error("Erro ao upsert news_cache", upsertError);
      }
    }

    const { data, error } = await supabase
      .from("news_cache")
      .select("title, source, url, published_at")
      .eq("country", "pt")
      .order("published_at", { ascending: false })
      .limit(10);

    if (error) {
      console.error("Erro ao ler news_cache", error);
      return new Response("Erro ao ler cache de notícias", { status: 500 });
    }

    const responseBody = (data ?? []).map((row: any) => ({
      title: row.title,
      source: row.source,
      url: row.url,
      published_at: row.published_at,
    }));

    return new Response(JSON.stringify(responseBody), {
      status: 200,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (e) {
    console.error("Unhandled error in fuel-news function", e);
    return new Response("Erro interno na função fuel-news", { status: 500 });
  }
});
