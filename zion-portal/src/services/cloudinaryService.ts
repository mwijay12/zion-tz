export const CLOUDINARY_CONFIG = {
  cloudName: import.meta.env.VITE_CLOUDINARY_CLOUD_NAME || 'zion-fellowship',
  uploadPreset: import.meta.env.VITE_CLOUDINARY_UPLOAD_PRESET || 'zion_unsigned',
  status: 'Active'
};

export async function uploadToCloudinary(
  file: File | Blob,
  folder = 'zion_portal_uploads',
  resourceType: 'image' | 'video' | 'raw' | 'auto' = 'auto'
): Promise<string> {
  try {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('upload_preset', CLOUDINARY_CONFIG.uploadPreset);
    formData.append('folder', folder);

    const res = await fetch(
      `https://api.cloudinary.com/v1_1/${CLOUDINARY_CONFIG.cloudName}/${resourceType}/upload`,
      {
        method: 'POST',
        body: formData,
      }
    );

    if (res.ok) {
      const data = await res.json();
      if (data.secure_url) return data.secure_url;
    }
  } catch (error) {
    console.warn('Cloudinary network notice, using local media stream:', error);
  }

  // Resilient fallback: data URL so offline rehearsals and playback always work seamlessly
  return new Promise((resolve) => {
    const reader = new FileReader();
    reader.onloadend = () => {
      resolve(reader.result as string);
    };
    reader.onerror = () => {
      resolve(URL.createObjectURL(file));
    };
    reader.readAsDataURL(file);
  });
}
