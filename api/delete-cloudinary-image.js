const cloudinary = require('cloudinary').v2;

// Configure Cloudinary with environment variables
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { public_id } = req.body;

  if (!public_id) {
    return res.status(400).json({ error: 'Missing public_id in request body' });
  }

  try {
    const result = await cloudinary.uploader.destroy(public_id);
    if (result.result === 'ok') {
      res.status(200).json({ success: true, message: `Image ${public_id} deleted successfully.` });
    } else {
      res.status(500).json({ success: false, message: `Failed to delete image ${public_id}: ${result.result}` });
    }
  } catch (error) {
    console.error('Error deleting image from Cloudinary:', error);
    res.status(500).json({ success: false, message: 'Internal server error during image deletion.', error: error.message });
  }
};
