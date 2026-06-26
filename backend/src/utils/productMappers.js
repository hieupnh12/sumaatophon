function splitPipe(value) {
  if (!value) return [];
  return String(value)
    .split('|')
    .map((item) => item.trim())
    .filter((item) => item && item !== '/');
}

function mergeUniqueImages(mainImage, extraImages = []) {
  const images = [];
  const add = (url) => {
    const trimmed = String(url ?? '').trim();
    if (trimmed && !images.includes(trimmed)) images.push(trimmed);
  };

  add(mainImage);
  const extras = Array.isArray(extraImages) ? extraImages : [];
  for (const image of extras) add(image);
  return images;
}

function mapProductRow(row, galleryImages = null) {
  const minPrice = Number(row.min_price ?? 0);
  const maxImport = Number(row.max_import_price ?? minPrice);
  const originalPrice = maxImport > minPrice ? maxImport : minPrice;

  const specifications = {};
  if (row.screen_size) specifications.Display = `${row.screen_size}"`;
  if (row.screen_tech) specifications['Screen tech'] = row.screen_tech;
  if (row.chipset) specifications.Chipset = row.chipset;
  if (row.battery) specifications.Battery = row.battery;
  if (row.rear_camera) specifications['Rear camera'] = row.rear_camera;
  if (row.front_camera) specifications['Front camera'] = row.front_camera;
  if (row.operating_system_name) specifications.OS = row.operating_system_name;
  if (row.warranty_period) specifications.Warranty = `${row.warranty_period} months`;

  const images = mergeUniqueImages(row.picture, galleryImages);

  return {
    id: String(row.product_id),
    name: row.product_name,
    brand: row.brand_name ?? 'Unknown',
    price: minPrice,
    originalPrice,
    imageUrl: images[0] ?? '',
    galleryImages: images,
    rating: Number(row.avg_rating ?? 0),
    reviewCount: Number(row.review_count ?? 0),
    ramRomOptions: splitPipe(row.ram_rom_options),
    colors: splitPipe(row.color_names),
    specifications,
    isNew: row.status === 1,
    stockQuantity: Number(row.stock_quantity ?? 0),
    versions: [],
    feedbacks: [],
  };
}

function mapProductVersionRow(row, versionImages = []) {
  const ram = row.ram_size ? String(row.ram_size).trim() : '';
  const rom = row.rom_size ? String(row.rom_size).trim() : '';
  const ramRom = [ram, rom].filter(Boolean).join('/');

  return {
    id: String(row.product_version_id),
    color: row.color_name ? String(row.color_name).trim() : '',
    ram,
    rom,
    ramRom,
    price: Number(row.export_price ?? 0),
    stockQuantity: Number(row.stock_quantity ?? 0),
    imageUrl: versionImages[0] ?? '',
    galleryImages: versionImages,
  };
}

function mapFeedbackRow(row) {
  return {
    id: String(row.feedback_id),
    customerName: row.full_name || 'Customer',
    rate: Number(row.rate ?? 0),
    content: row.content || '',
    createdAt: row.date ? new Date(row.date).toISOString() : null,
  };
}

module.exports = {
  splitPipe,
  mergeUniqueImages,
  mapProductRow,
  mapProductVersionRow,
  mapFeedbackRow,
};
