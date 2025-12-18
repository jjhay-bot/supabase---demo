import { createClient } from "npm:@supabase/supabase-js@2.34.0";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY environment variables");
}
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: {
    persistSession: false
  }
});
const STORAGE_BUCKET_NAME = "Buckets";

function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json"
    }
  });
}

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") return jsonResponse({
      error: "Method not allowed"
    }, 405);
    
    const ct = req.headers.get("content-type") || "";
    if (!ct.includes("application/json")) return jsonResponse({
      error: "Expected application/json"
    }, 400);
    
    const body = await req.json().catch(() => null);
    if (!body) return jsonResponse({
      error: "Invalid JSON body"
    }, 400);
    
    const { bucket_id, image_url, storage_path, file_name } = body;
    
    if (!bucket_id || !Number.isInteger(bucket_id)) {
      return jsonResponse({
        error: "bucket_id is required and must be an integer"
      }, 400);
    }
    
    if (!image_url || typeof image_url !== "string") {
      return jsonResponse({
        error: "image_url is required and must be a string"
      }, 400);
    }
    
    const { data: existingBucket, error: bucketErr } = await supabase.from("buckets").select("id, uid, display_picture_url").eq("id", bucket_id).single();
    if (bucketErr) {
      return jsonResponse({
        error: "Bucket not found or DB error",
        details: bucketErr.message
      }, 404);
    }

    let imageResp;
    try {
      imageResp = await fetch(image_url);
    } catch (e) {
      return jsonResponse({
        error: "Failed to fetch image_url",
        details: String(e)
      }, 400);
    }
    
    if (!imageResp.ok) {
      return jsonResponse({
        error: "Failed to download image",
        status: imageResp.status,
        statusText: imageResp.statusText
      }, 400);
    }
    
    const contentType = imageResp.headers.get("content-type") || "";
    let ext = "";
    if (contentType.includes("/")) {
      const mime = contentType.split("/")[1].split(";")[0].trim();
      if (mime === "jpeg") ext = ".jpg";
      else if (mime === "png") ext = ".png";
      else if (mime === "gif") ext = ".gif";
      else if (mime === "webp") ext = ".webp";
      else if (mime === "svg+xml") ext = ".svg";
      else ext = "." + mime;
    } else {
      try {
        const urlPath = new URL(image_url).pathname;
        const lastDot = urlPath.lastIndexOf(".");
        ext = lastDot !== -1 ? urlPath.substring(lastDot) : "";
      } catch {
        ext = ".jpg";
      }
    }
    
    const arrayBuffer = await imageResp.arrayBuffer();
    const fileBytes = new Uint8Array(arrayBuffer);
    
    const pathPrefix = storage_path && typeof storage_path === "string" ? storage_path.replace(/^\/+|\/+$/g, "") : `buckets/${bucket_id}`;
    const generatedName = file_name && typeof file_name === "string" ? file_name : `${crypto.randomUUID()}${ext || ".jpg"}`;
    const finalPath = `${pathPrefix}/${generatedName}`;
    
    // Upload the image to Supabase storage
    const { data: uploadData, error: uploadError } = await supabase.storage.from(STORAGE_BUCKET_NAME).upload(finalPath, fileBytes, {
      contentType: contentType || undefined,
      upsert: false
    });
    
    if (uploadError) {
      console.error("Storage upload error:", uploadError);
      return jsonResponse({
        error: "Failed to upload to storage",
        details: uploadError.message
      }, 500);
    }
    
    // Use the public URL (do not use signed URL, this is permanent)
    const uploadedUrl = `${supabase.storage.from(STORAGE_BUCKET_NAME).getPublicUrl(finalPath).publicURL}`;
    
    // Update the bucket record in the database with the new image URL
    const { data: updatedBucket, error: updateErr } = await supabase.from("buckets").update({
      display_picture_url: uploadedUrl
    }).eq("id", bucket_id).select("*").single();
    
    if (updateErr) {
      console.error("DB update error:", updateErr);
      return jsonResponse({
        error: "Failed to update bucket record",
        details: updateErr.message
      }, 500);
    }
    
    return jsonResponse({
      bucket: updatedBucket,
      storage: {
        bucket: STORAGE_BUCKET_NAME,
        path: finalPath,
        public_url: uploadedUrl
      }
    }, 200);
  } catch (err) {
    console.error("Unhandled error:", err);
    return jsonResponse({
      error: "Internal server error",
      details: String(err)
    }, 500);
  }
});