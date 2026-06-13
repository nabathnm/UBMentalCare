import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

// Pengaturan CORS agar bisa diakses dari aplikasi (Flutter/Web)
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests (biasanya dipanggil sebelum POST request)
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Ambil data (prompt/pesan) yang dikirim dari aplikasi Flutter
    const { prompt } = await req.json()

    if (!prompt) {
      throw new Error('Prompt (pesan) tidak boleh kosong')
    }

    // 2. (Opsional tapi disarankan) Validasi bahwa yang memanggil ini adalah user yang sudah login di Supabase
    // const authHeader = req.headers.get('Authorization')
    // if (!authHeader) {
    //   throw new Error('Unauthorized: Anda harus login terlebih dahulu')
    // }

    // 3. Ambil Gemini API Key dari Supabase Secrets (yang disimpan dengan aman)
    const geminiApiKey = Deno.env.get('GEMINI_API_KEY')
    if (!geminiApiKey) {
      throw new Error('GEMINI_API_KEY belum disetel di Supabase Secrets')
    }

    // 4. Lakukan request ke Google Gemini API (Menggunakan model Gemini 1.5 Flash yang lebih cepat & murah)
    const geminiApiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey}`;

    const geminiResponse = await fetch(geminiApiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        contents: [
          {
            parts: [{ text: prompt }]
          }
        ],
      }),
    });

    if (!geminiResponse.ok) {
      const errorData = await geminiResponse.json();
      console.error('Gemini API Error:', errorData);
      throw new Error('Gagal mendapatkan respon dari Gemini API');
    }

    const data = await geminiResponse.json();

    // Ambil hasil teks balasan dari Gemini
    const textResponse = data.candidates?.[0]?.content?.parts?.[0]?.text || '';

    // 5. Kembalikan hasilnya ke aplikasi Flutter
    return new Response(
      JSON.stringify({ result: textResponse }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      },
    )
  } catch (error) {
    // Tangkap dan kembalikan error jika terjadi kesalahan
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      },
    )
  }
})
