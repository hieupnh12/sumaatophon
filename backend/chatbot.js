const fs = require('fs');
const path = require('path');

function splitPipe(value) {
  if (!value) return [];
  return String(value)
    .split('|')
    .map((item) => item.trim())
    .filter((item) => item && item !== '/');
}

function formatVnd(amount) {
  const n = Number(amount ?? 0);
  if (!n) return 'Liên hệ';
  return `${Math.round(n).toLocaleString('vi-VN')}đ`;
}

function mapProductRow(row) {
  const minPrice = Number(row.min_price ?? 0);
  const specs = [];
  if (row.screen_size) specs.push(`Màn hình ${row.screen_size}"`);
  if (row.chipset) specs.push(`Chip ${row.chipset}`);
  if (row.battery) specs.push(`Pin ${row.battery}`);
  if (row.rear_camera) specs.push(`Camera sau ${row.rear_camera}`);
  if (row.operating_system_name) specs.push(`HĐH ${row.operating_system_name}`);

  return {
    id: String(row.product_id),
    name: row.product_name,
    brand: row.brand_name ?? 'Unknown',
    price: minPrice,
    ramRom: splitPipe(row.ram_rom_options),
    colors: splitPipe(row.color_names),
    stockQuantity: Number(row.stock_quantity ?? 0),
    rating: Number(row.avg_rating ?? 0),
    specsText: specs.join(' · '),
  };
}

async function loadProducts(pool) {
  const [rows] = await pool.query(`
    SELECT
      p.product_id,
      p.product_name,
      p.battery,
      p.screen_size,
      p.chipset,
      p.rear_camera,
      os.operating_system_name,
      b.brand_name,
      MIN(pv.export_price) AS min_price,
      GROUP_CONCAT(
        DISTINCT CONCAT(COALESCE(r.ram_size, ''), '/', COALESCE(ro.rom_size, ''))
        SEPARATOR '|'
      ) AS ram_rom_options,
      GROUP_CONCAT(DISTINCT c.color_name SEPARATOR '|') AS color_names,
      COALESCE(AVG(f.rate), 0) AS avg_rating,
      COUNT(DISTINCT CASE
        WHEN pi.status = 'IN_STOCK' AND pi.order_detail_id IS NULL THEN pi.imei
      END) AS stock_quantity
    FROM products p
    LEFT JOIN brands b ON p.brand_id = b.brand_id
    LEFT JOIN operating_systems os ON p.operating_system_id = os.operating_system_id
    LEFT JOIN product_versions pv ON p.product_id = pv.product_id AND pv.status = 1
    LEFT JOIN rams r ON pv.ram_id = r.ram_id
    LEFT JOIN roms ro ON pv.rom_id = ro.rom_id
    LEFT JOIN colors c ON pv.color_id = c.color_id
    LEFT JOIN feedbacks f ON f.product_id = p.product_id
    LEFT JOIN product_items pi ON pi.product_version_id = pv.product_version_id
    WHERE p.status = 1
    GROUP BY
      p.product_id, p.product_name, p.battery, p.screen_size, p.chipset,
      p.rear_camera, os.operating_system_name, b.brand_name
    ORDER BY p.product_id DESC
  `);

  return rows.map(mapProductRow);
}

function normalize(text) {
  return String(text ?? '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim();
}

function productSummary(p) {
  const stock = p.stockQuantity > 0 ? `Còn ${p.stockQuantity} máy` : 'Hết hàng';
  const ramRom = p.ramRom.length ? ` · ${p.ramRom.join(', ')}` : '';
  return `• **${p.name}** (${p.brand}) — ${formatVnd(p.price)} · ${stock}${ramRom}\n  ${p.specsText || 'Đang cập nhật thông số'}`;
}

const STOP_TOKENS = new Set(['pro', 'max', 'plus', 'mini', 'lite', 'ultra', 'gb', 'may', 'dien', 'thoai', 'phone']);
const BRAND_ALIASES = [
  { re: /\b(iphone|ip\b|apple|ios)\b/, brand: 'apple' },
  { re: /\b(xiaomi|mi\b|redmi|poco)\b/, brand: 'xiaomi' },
  { re: /\b(samsung|galaxy)\b/, brand: 'samsung' },
  { re: /\b(oppo)\b/, brand: 'oppo' },
  { re: /\b(vivo)\b/, brand: 'vivo' },
  { re: /\b(realme)\b/, brand: 'realme' },
  { re: /\b(huawei)\b/, brand: 'huawei' },
  { re: /\b(nokia)\b/, brand: 'nokia' },
  { re: /\b(sony|xperia)\b/, brand: 'sony' },
];

function expandSearchQuery(message) {
  let q = normalize(message);
  q = q.replace(/\bip(\d)/g, 'iphone $1');
  q = q.replace(/\bip\b/g, 'iphone');
  q = q.replace(/\biphone(\d+)/g, 'iphone $1');
  q = q.replace(/promax/g, 'pro max');
  q = q.replace(/\s+/g, ' ').trim();
  return q;
}

function detectRequestedBrands(q) {
  return BRAND_ALIASES.filter(({ re }) => re.test(q)).map(({ brand }) => brand);
}

function extractModelNumbers(q) {
  return [...new Set((q.match(/\b(1[0-9]|[2-9][0-9])\b/g) || []).map(Number))];
}

function productMatchesBrand(p, requestedBrands) {
  if (!requestedBrands.length) return true;
  const nameNorm = normalize(p.name);
  const brandNorm = normalize(p.brand);
  return requestedBrands.some(
    (b) => brandNorm.includes(b) || (b === 'apple' && nameNorm.includes('iphone')),
  );
}

function scoreProduct(p, q, requestedBrands, modelNums) {
  if (!productMatchesBrand(p, requestedBrands)) return 0;

  const nameNorm = normalize(p.name);
  const brandNorm = normalize(p.brand);
  const haystack = `${nameNorm} ${brandNorm}`;
  let score = 0;

  const qCompact = q.replace(/\s/g, '');
  const nameCompact = nameNorm.replace(/\s/g, '');
  if (nameCompact.includes(qCompact)) score += 50;
  else if (qCompact.length >= 6 && nameCompact.includes(qCompact.slice(0, Math.min(qCompact.length, 12)))) {
    score += 30;
  }

  if (modelNums.length > 0) {
    const nameNums = extractModelNumbers(nameNorm);
    const numMatch = modelNums.some((n) => nameNums.includes(n));
    if (numMatch) score += 30;
    else return 0;
  }

  const tokens = q.split(/\s+/).filter((t) => t.length > 1 && !STOP_TOKENS.has(t));
  for (const token of tokens) {
    if (nameNorm.includes(token)) score += 6;
    else if (haystack.includes(token)) score += 2;
  }

  if (q.includes('pro max') && nameNorm.includes('pro max')) score += 18;
  if (q.includes('pro') && nameNorm.includes('pro')) score += 4;
  if (q.includes('max') && nameNorm.includes('max')) score += 4;

  return score;
}

function tightenSearchResults(scored) {
  if (!scored.length) return [];

  const [top, second] = scored;
  if (!second || top.score >= second.score * 1.6 || top.score >= 40) {
    return [top.p];
  }

  const close = scored.filter((item) => item.score >= top.score * 0.75).slice(0, 2);
  return close.map((item) => item.p);
}

function searchProducts(products, message, minScore = 6) {
  const q = expandSearchQuery(message);
  const requestedBrands = detectRequestedBrands(q);
  const modelNums = extractModelNumbers(q);

  const scored = products
    .map((p) => ({ p, score: scoreProduct(p, q, requestedBrands, modelNums) }))
    .filter((item) => item.score >= minScore)
    .sort((a, b) => b.score - a.score);

  return tightenSearchResults(scored);
}

const INTENT_LABELS = ['phone_product', 'store_policy', 'greeting', 'staff', 'off_topic', 'unclear'];

function classifyIntentRule(message, products) {
  const q = normalize(message);

  if (!message?.trim()) return 'empty';
  if (/^(xin chao|chao|hello|hi)\b/.test(q)) return 'greeting';
  if (/nhan vien|ho tro|tu van|gap nguoi|staff|human/.test(q)) return 'staff';
  if (/bao hanh|doi tra|giao hang|thanh toan|tra gop|ship|doi hang/.test(q)) return 'store_policy';

  const offTopicRe = [
    /\b(mua|ban|co|shop)\s+(ao|quan|vay|giay|dep|mu|tui|balo)\b/,
    /\b(ao|quan|vay|giay|dep)\b.*\b(mua|ban|size|mau|thoi trang)\b/,
    /\b(laptop|may tinh|tu lanh|ti vi|noi com|may giat|xe may|oto)\b/,
    /\b(thoi tiet|bong da|lam bai|viet code|python|javascript)\b/,
    /\b(thuoc|benh|tri benh|nau an|mon an)\b/,
  ];
  if (offTopicRe.some((re) => re.test(q))) return 'off_topic';

  const phoneRe =
    /dien thoai|smartphone|iphone|\bip\b|ip\d|ipad|samsung|xiaomi|oppo|vivo|realme|huawei|nokia|sony|pin|man hinh|chip|camera|ram|rom|android|ios|con hang|het hang|ton kho|thong so/;
  const listRe = /co nhung|danh sach|shop co|nhung may|san pham nao|may nao/;
  const matches = searchProducts(products, message, 6);
  const brands = [...new Set(products.map((p) => normalize(p.brand)).filter(Boolean))];
  const hasBrand = brands.some((b) => q.includes(b));

  if (phoneRe.test(q) || listRe.test(q) || hasBrand || matches.length > 0) {
    return 'phone_product';
  }

  if (/goi y|nen mua|re nhat|tot nhat|recommend/.test(q)) return 'phone_product';
  if (/mua|ban|gia|shop|san pham|hang hoa/.test(q)) return 'unclear';

  return 'off_topic';
}

function buildIntentPrompt() {
  return trainingSection('INTENT') || `Bạn phân loại ý định tin nhắn. phoneShop CHỈ bán điện thoại.
Trả về 1 nhãn: phone_product | store_policy | greeting | staff | off_topic | unclear`;
}

async function classifyIntentAi(message, provider) {
  const raw = await callAiText({
    provider,
    systemPrompt: buildIntentPrompt(),
    userMessage: `Tin nhắn khách: "${message}"\nNhãn:`,
    history: [],
    maxOutputTokens: 32,
    temperature: 0,
  });

  const cleaned = raw.toLowerCase();
  for (const label of INTENT_LABELS) {
    if (cleaned.includes(label)) return label;
  }
  return 'unclear';
}

async function resolveIntent(message, products, provider) {
  const ruleIntent = classifyIntentRule(message, products);
  if (provider === 'rule') return ruleIntent;
  if (ruleIntent === 'off_topic' || ruleIntent === 'empty') return ruleIntent;

  const useAiIntent = String(process.env.CHATBOT_INTENT_AI ?? 'true').toLowerCase() !== 'false';
  if (!useAiIntent) {
    return ruleIntent === 'unclear' ? 'unclear' : ruleIntent;
  }

  try {
    const aiIntent = await classifyIntentAi(message, provider);
    if (ruleIntent === 'greeting' || ruleIntent === 'staff' || ruleIntent === 'store_policy') {
      return ruleIntent;
    }
    return aiIntent;
  } catch (err) {
    console.warn('[chatbot] intent AI fallback:', err.message.slice(0, 120));
    return ruleIntent;
  }
}

function answerForIntent(intent, message, products) {
  switch (intent) {
    case 'empty':
      return {
        reply: 'Bạn muốn hỏi về điện thoại nào? Ví dụ: "Giá iPhone 15", "Xiaomi pin bao nhiêu", "Gợi ý điện thoại".',
        suggestStaff: false,
        productIds: [],
      };
    case 'greeting':
      return {
        reply:
          'Xin chào! Tôi là trợ lý phoneShop — chỉ tư vấn điện thoại (giá, thông số, gợi ý máy).\n\n' +
          'Thử hỏi:\n• "Shop có những máy gì?"\n• "Giá Samsung S24"\n• "Gợi ý điện thoại rẻ"\n\n' +
          'Cần hỗ trợ khác, chuyển tab Nhân viên nhé.',
        suggestStaff: false,
        productIds: [],
      };
    case 'staff':
      return {
        reply: 'Bạn có thể chuyển sang tab Nhân viên để chat realtime 1-1 với nhân viên phoneShop.',
        suggestStaff: true,
        productIds: [],
      };
    case 'store_policy': {
      const policy = loadStorePolicy();
      return {
        reply: policy
          ? `Chính sách phoneShop:\n${policy}\n\nCần tư vấn chi tiết, chuyển tab Nhân viên.`
          : 'Vui lòng chuyển sang tab Nhân viên để được tư vấn bảo hành, đổi trả và giao hàng.',
        suggestStaff: true,
        productIds: [],
      };
    }
    case 'off_topic':
      return {
        reply:
          'phoneShop chỉ tư vấn điện thoại trong cửa hàng — không bán quần áo hay mặt hàng khác.\n\n' +
          'Bạn có thể hỏi về giá, thông số, tồn kho smartphone, hoặc chuyển tab Nhân viên.',
        suggestStaff: true,
        productIds: [],
      };
    case 'unclear':
      return {
        reply:
          'Mình chưa hiểu bạn cần tư vấn điện thoại gì. phoneShop chỉ hỗ trợ smartphone.\n\n' +
          'Thử: "Giá iPhone 12", "Còn Samsung không", "Gợi ý máy pin trâu".',
        suggestStaff: false,
        productIds: [],
      };
    case 'phone_product':
    default:
      return answerFromProducts(message, products);
  }
}

async function maybeRewriteNonProductReply(baseResult, message, history, provider) {
  const rewritePrompt = `Bạn là trợ lý phoneShop. Viết lại câu trả lời ngắn gọn, thân thiện.
KHÔNG đề xuất sản phẩm điện thoại. KHÔNG bịa giá hay tên máy. Giữ nguyên ý chính.
Nếu cần nhân viên, thêm [SUGGEST_STAFF] ở cuối.`;

  const rawText = await callAiText({
    provider,
    systemPrompt: rewritePrompt,
    userMessage: buildRewriteUserMessage(message, baseResult.reply),
    history: history.slice(-4),
  });

  return {
    reply: rawText.replace(/\[SUGGEST_STAFF\]/gi, '').trim(),
    suggestStaff: baseResult.suggestStaff || /\[SUGGEST_STAFF\]/i.test(rawText),
    productIds: [],
  };
}

function answerFromProducts(message, products) {
  const q = normalize(message);

  if (!message?.trim()) {
    return {
      reply: 'Bạn muốn hỏi về sản phẩm nào? Ví dụ: "Giá iPhone 15", "Xiaomi pin bao nhiêu", "Gợi ý điện thoại".',
      suggestStaff: false,
    };
  }

  if (/^(xin chao|chao|hello|hi)\b/.test(q)) {
    return {
      reply:
        'Xin chào! Tôi là trợ lý phoneShop — có thể tư vấn giá, thông số và gợi ý điện thoại.\n\n' +
        'Thử hỏi:\n• "Shop có những máy gì?"\n• "Giá Samsung S24"\n• "So sánh iPhone và Xiaomi"\n\n' +
        'Cần hỗ trợ chi tiết hơn, chuyển sang tab **Nhân viên** nhé.',
      suggestStaff: false,
    };
  }

  if (/nhan vien|ho tro|tu van|gap nguoi|staff|human/.test(q)) {
    return {
      reply: 'Bạn có thể chuyển sang tab **Nhân viên** để chat realtime 1-1 với nhân viên phoneShop.',
      suggestStaff: true,
    };
  }

  if (/co nhung|danh sach|shop co|nhung may|san pham nao|list/.test(q)) {
    const top = products.slice(0, 8);
    if (!top.length) {
      return { reply: 'Hiện chưa có sản phẩm trong hệ thống.', suggestStaff: false };
    }
    return {
      reply: `phoneShop đang có ${products.length} mẫu. Một số sản phẩm nổi bật:\n\n${top.map(productSummary).join('\n\n')}`,
      suggestStaff: false,
      productIds: top.map((p) => p.id),
    };
  }

  if (/goi y|nen mua|re nhat|tot nhat|recommend/.test(q)) {
    const inStock = products.filter((p) => p.stockQuantity > 0);
    const pick = [...inStock].sort((a, b) => a.price - b.price).slice(0, 3);
    if (!pick.length) {
      return { reply: 'Hiện chưa có máy còn hàng. Bạn thử hỏi nhân viên kiểm tra tồn kho nhé.', suggestStaff: true };
    }
    return {
      reply: `Gợi ý một vài mẫu đang có hàng:\n\n${pick.map(productSummary).join('\n\n')}`,
      suggestStaff: false,
      productIds: pick.map((p) => p.id),
    };
  }

  const matches = searchProducts(products, message);
  const top = matches.slice(0, 3);

  if (!top.length) {
    return {
      reply:
        'Tôi chưa tìm thấy sản phẩm phù hợp. Bạn thử gõ đúng tên máy (vd: "iPhone 17 Pro Max", "Samsung S24").\n\n' +
        'Hoặc chuyển tab **Nhân viên** để được hỗ trợ trực tiếp.',
      suggestStaff: true,
    };
  }

  const formatProductReply = (title, items) => ({
    reply: `${title}\n\n${items.map(productSummary).join('\n\n')}`,
    suggestStaff: false,
    productIds: items.map((p) => p.id),
  });

  if (/gia|bao nhieu|price|cost/.test(q)) {
    return formatProductReply('Giá tham khảo:', top);
  }

  if (/pin|battery|man hinh|chip|camera|thong so|spec/.test(q)) {
    return formatProductReply('Thông số liên quan:', top);
  }

  if (/con hang|het hang|ton kho|stock/.test(q)) {
    const lines = top.map((p) => {
      const stock = p.stockQuantity > 0 ? `Còn ${p.stockQuantity} máy` : 'Hết hàng';
      return `• **${p.name}**: ${stock}`;
    });
    return { reply: lines.join('\n'), suggestStaff: false, productIds: top.map((p) => p.id) };
  }

  if (top.length === 1) {
    return formatProductReply(`Thông tin ${top[0].name}:`, top);
  }

  const multi = formatProductReply('Tôi tìm thấy các mẫu gần đúng:', top);
  return {
    ...multi,
    reply: `${multi.reply}\n\nBạn muốn biết giá, thông số hay tồn kho của mẫu nào?`,
  };
}

function loadTrainingSections() {
  const rel = process.env.CHATBOT_TRAINING_FILE || 'chatbot-training.txt';
  const filePath = path.isAbsolute(rel) ? rel : path.join(__dirname, rel);
  try {
    if (!fs.existsSync(filePath)) return {};
    const raw = fs.readFileSync(filePath, 'utf8');
    const sections = {};
    const parts = raw.split(/^===\s*([A-Z_]+)\s*===\s*$/m);
    for (let i = 1; i < parts.length; i += 2) {
      sections[parts[i].trim()] = (parts[i + 1] || '').trim();
    }
    return sections;
  } catch {
    return {};
  }
}

function trainingSection(name) {
  return loadTrainingSections()[name] || '';
}

function loadStorePolicy() {
  return trainingSection('POLICY');
}

function loadSuggestions() {
  const raw = trainingSection('SUGGESTIONS');
  const fromFile = raw
    .split('\n')
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith('#'));
  if (fromFile.length) return fromFile;
  return [
    'Shop có những máy gì?',
    'Gợi ý điện thoại giá rẻ còn hàng',
    'Gợi ý máy chơi game pin trâu',
    'Điện thoại dưới 10 triệu còn hàng',
    'Giá iPhone 17 Pro Max bao nhiêu?',
    'iPhone 17 Pro Max còn hàng không?',
    'Giá Samsung Galaxy S24',
    'So sánh iPhone và Samsung',
    'Xiaomi nào đáng mua hiện nay?',
    'Máy nào pin tốt shop đang có?',
    'Shop có trả góp không?',
    'Chính sách bảo hành đổi trả',
    'Giao hàng mất bao lâu?',
  ];
}

function renderPrompt(template, vars) {
  return template.replace(/\{\{([A-Z_]+)\}\}/g, (_, key) => {
    const val = vars[key];
    return val == null ? '' : String(val);
  });
}

function formatPolicyBlock(policy, prefix = 'Chính sách cửa hàng') {
  if (!policy?.trim()) return '';
  return `\n\n${prefix}:\n${policy.trim()}`;
}

function selectRelevantProducts(message, products, history = []) {
  const contextText = [message, ...history.slice(-4).map((h) => h.text)].join(' ');
  const q = normalize(contextText);

  if (/co nhung|danh sach|shop co|nhung may|san pham nao|list/.test(q)) {
    return products.slice(0, 8);
  }

  if (/goi y|nen mua|re nhat|tot nhat|recommend/.test(q)) {
    const inStock = products.filter((p) => p.stockQuantity > 0);
    return (inStock.length ? inStock : products).slice(0, 6);
  }

  const matches = searchProducts(products, contextText);
  if (matches.length) return matches.slice(0, 6);

  if (/^(xin chao|chao|hello|hi)\b/.test(normalize(message))) {
    return products.slice(0, 3);
  }

  return products.filter((p) => p.stockQuantity > 0).slice(0, 5);
}

function buildProductContext(products) {
  return products
    .map((p) => {
      const stock = p.stockQuantity > 0 ? `còn ${p.stockQuantity} máy` : 'hết hàng';
      const ramRom = p.ramRom.length ? `, RAM/ROM: ${p.ramRom.join(', ')}` : '';
      const colors = p.colors.length ? `, màu: ${p.colors.join(', ')}` : '';
      const rating = p.rating > 0 ? `, đánh giá ${p.rating.toFixed(1)}/5` : '';
      return `- [id:${p.id}] ${p.name} (${p.brand}) — ${formatVnd(p.price)}, ${stock}${ramRom}${colors}${rating}. ${p.specsText || ''}`;
    })
    .join('\n');
}

function buildSystemPrompt(relevantProducts, totalInShop) {
  const catalog = buildProductContext(relevantProducts);
  const policy = loadStorePolicy();
  const vars = {
    CATALOG: catalog,
    POLICY: formatPolicyBlock(policy, 'Chính sách cửa hàng'),
    TOTAL_PRODUCTS: String(totalInShop),
    RELEVANT_COUNT: String(relevantProducts.length),
  };

  const template = trainingSection('FULL');
  if (template) return renderPrompt(template, vars);

  return `Bạn là trợ lý phoneShop. CHỈ dùng sản phẩm trong danh sách.
${catalog}${formatPolicyBlock(policy)}`;
}

function buildRewritePrompt() {
  const policy = loadStorePolicy();
  const template = trainingSection('REWRITE');
  const vars = {
    POLICY: policy ? formatPolicyBlock(policy, 'Chính sách (khi khách hỏi)') : '',
  };
  if (template) return renderPrompt(template, vars);

  return `Viết lại dữ liệu chính xác cho tự nhiên. Không sửa giá/tên máy.${vars.POLICY}`;
}

function buildRewriteUserMessage(message, factualAnswer) {
  const template = trainingSection('USER');
  const vars = { USER_MESSAGE: message, FACTUAL_ANSWER: factualAnswer };
  if (template) return renderPrompt(template, vars);

  return `Câu hỏi: ${message}\n\nDữ liệu:\n${factualAnswer}\n\nViết lại:`;
}

function buildPromptPreview(message, products, history = []) {
  const chatMode = resolveChatbotMode();
  const intent = classifyIntentRule(message, products);
  const baseResult = answerForIntent(intent, message, products);
  const relevant = selectRelevantProducts(message, products, history);
  const trainingFile = process.env.CHATBOT_TRAINING_FILE || 'chatbot-training.txt';

  return {
    mode: chatMode,
    provider: resolveAiProvider(),
    intent,
    trainingFile,
    sections: Object.keys(loadTrainingSections()),
    intentPrompt: buildIntentPrompt(),
    hybrid: {
      systemPrompt: buildRewritePrompt(),
      userPrompt: buildRewriteUserMessage(message, baseResult.reply),
      factualFromDb: baseResult.reply,
    },
    full: {
      systemPrompt: buildSystemPrompt(relevant, products.length),
      userPrompt: message,
    },
    placeholders: {
      '{{USER_MESSAGE}}': 'Câu hỏi khách',
      '{{FACTUAL_ANSWER}}': 'Dữ liệu từ database',
      '{{CATALOG}}': 'Danh sách SP liên quan',
      '{{POLICY}}': 'Khối === POLICY ===',
      '{{TOTAL_PRODUCTS}}': 'Tổng SP trong shop',
      '{{RELEVANT_COUNT}}': 'Số SP trong context',
    },
  };
}

function aiTemperature() {
  const t = Number(process.env.CHATBOT_TEMPERATURE);
  return Number.isFinite(t) && t >= 0 && t <= 1 ? t : 0.2;
}

function resolveChatbotMode() {
  const mode = String(process.env.CHATBOT_MODE ?? 'hybrid').toLowerCase();
  return mode === 'full' ? 'full' : mode === 'rule' ? 'rule' : 'hybrid';
}

function validateRewrite(factualReply, rewritten, products, productIds = []) {
  if (!rewritten?.trim() || rewritten.length > 900) return false;
  if (!productIds.length) return rewritten.length >= 10;

  const rewriteNorm = normalize(rewritten);
  for (const id of productIds) {
    const p = products.find((x) => x.id === String(id));
    if (!p) continue;

    const nameNorm = normalize(p.name);
    if (nameNorm && !rewriteNorm.includes(nameNorm)) return false;

    const priceNum = String(Math.round(p.price));
    if (p.price > 0 && !rewriteNorm.includes(priceNum)) return false;

    if (p.stockQuantity > 0) {
      const stockNorm = normalize(`còn ${p.stockQuantity} máy`);
      if (!rewriteNorm.includes(stockNorm) && !rewriteNorm.includes(String(p.stockQuantity))) {
        return false;
      }
    }
  }

  const factualPrices = factualReply.match(/[\d.,]+đ/g) || [];
  for (const price of factualPrices) {
    const digits = price.replace(/\D/g, '');
    if (digits.length >= 3 && !rewriteNorm.includes(digits)) return false;
  }

  return true;
}

function parseAiReply(rawText, relevantProducts, message, baseResult = null) {
  const suggestStaff = baseResult?.suggestStaff ?? /\[SUGGEST_STAFF\]/i.test(rawText);
  let reply = rawText.replace(/\[SUGGEST_STAFF\]/gi, '').trim();

  const productIds = baseResult?.productIds?.length
    ? baseResult.productIds
    : searchProducts(relevantProducts, `${message} ${reply}`)
        .slice(0, 5)
        .map((p) => p.id);

  return { reply, suggestStaff, productIds };
}

async function callAiText({ provider, systemPrompt, userMessage, history = [], maxOutputTokens = 400, temperature }) {
  const temp = temperature ?? aiTemperature();
  if (provider === 'gemini') {
    return callGemini({
      apiKey: process.env.GEMINI_API_KEY,
      model: process.env.GEMINI_MODEL || 'gemini-2.0-flash',
      systemPrompt,
      history,
      message: userMessage,
      maxOutputTokens,
      temperature: temp,
    });
  }
  if (provider === 'openai') {
    return callOpenAI({
      apiKey: process.env.OPENAI_API_KEY,
      model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
      systemPrompt,
      history,
      message: userMessage,
      maxOutputTokens,
      temperature: temp,
    });
  }
  throw new Error('No AI provider');
}

async function callGemini({ apiKey, model, systemPrompt, history, message, maxOutputTokens = 400, temperature }) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${encodeURIComponent(apiKey)}`;

  const contents = [
    ...history.slice(-10).map((h) => ({
      role: h.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: h.text }],
    })),
    { role: 'user', parts: [{ text: message }] },
  ];

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      systemInstruction: { parts: [{ text: systemPrompt }] },
      contents,
      generationConfig: {
        temperature: temperature ?? aiTemperature(),
        maxOutputTokens,
      },
    }),
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Gemini ${res.status}: ${errText.slice(0, 300)}`);
  }

  const data = await res.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text?.trim()) throw new Error('Gemini returned empty response');
  return text.trim();
}

async function callOpenAI({ apiKey, model, systemPrompt, history, message, maxOutputTokens = 400, temperature }) {
  const messages = [
    { role: 'system', content: systemPrompt },
    ...history.slice(-10).map((h) => ({
      role: h.role === 'assistant' ? 'assistant' : 'user',
      content: h.text,
    })),
    { role: 'user', content: message },
  ];

  const res = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      messages,
      temperature: temperature ?? aiTemperature(),
      max_tokens: maxOutputTokens,
    }),
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`OpenAI ${res.status}: ${errText.slice(0, 300)}`);
  }

  const data = await res.json();
  const text = data?.choices?.[0]?.message?.content;
  if (!text?.trim()) throw new Error('OpenAI returned empty response');
  return text.trim();
}

function classifyAiError(err) {
  const msg = String(err?.message ?? '');
  if (msg.includes('429')) return 'QUOTA_EXCEEDED';
  if (msg.includes('401') || msg.includes('403') || /API key not valid/i.test(msg)) return 'INVALID_API_KEY';
  return 'AI_ERROR';
}

function aiErrorHint(code) {
  switch (code) {
    case 'QUOTA_EXCEEDED':
      return 'Gemini hết quota. Tạo key mới tại https://aistudio.google.com/apikey hoặc bật billing.';
    case 'INVALID_API_KEY':
      return 'API key không hợp lệ. Kiểm tra GEMINI_API_KEY trong backend/.env (không phải .env.example).';
    default:
      return 'AI tạm lỗi, đang dùng chế độ rule-based.';
  }
}

function resolveAiProvider() {
  const explicit = String(process.env.CHATBOT_AI_PROVIDER ?? '').toLowerCase();
  if (explicit === 'rule' || explicit === 'off') return 'rule';
  if (explicit === 'openai' && process.env.OPENAI_API_KEY) return 'openai';
  if (explicit === 'gemini' && process.env.GEMINI_API_KEY) return 'gemini';
  if (process.env.GEMINI_API_KEY) return 'gemini';
  if (process.env.OPENAI_API_KEY) return 'openai';
  return 'rule';
}

async function answerHybrid(message, products, history) {
  const provider = resolveAiProvider();
  const chatMode = resolveChatbotMode();
  const intent = await resolveIntent(message, products, provider);
  let baseResult = answerForIntent(intent, message, products);

  if (chatMode === 'rule' || provider === 'rule') {
    return { ...baseResult, mode: 'rule', intent };
  }

  if (intent !== 'phone_product') {
    try {
      const polished = await maybeRewriteNonProductReply(baseResult, message, history, provider);
      return { ...polished, mode: 'intent-ai', intent };
    } catch {
      return { ...baseResult, mode: 'intent', intent };
    }
  }

  if (chatMode === 'full') {
    const relevant = selectRelevantProducts(message, products, history);
    const systemPrompt = buildSystemPrompt(relevant, products.length);
    const rawText = await callAiText({
      provider,
      systemPrompt,
      userMessage: message,
      history,
    });
    const parsed = parseAiReply(rawText, relevant, message);
    return { ...parsed, mode: 'full', intent };
  }

  const rewritePrompt = buildRewritePrompt();
  const userMessage = buildRewriteUserMessage(message, baseResult.reply);
  const rawText = await callAiText({
    provider,
    systemPrompt: rewritePrompt,
    userMessage,
    history: history.slice(-4),
  });

  const cleaned = rawText.replace(/\[SUGGEST_STAFF\]/gi, '').trim();
  if (!validateRewrite(baseResult.reply, cleaned, products, baseResult.productIds ?? [])) {
    console.warn('[chatbot] hybrid: AI lệch fact → dùng rule-based');
    return { ...baseResult, mode: 'hybrid-safe', intent };
  }

  return {
    reply: cleaned,
    suggestStaff: Boolean(baseResult.suggestStaff),
    productIds: baseResult.productIds ?? [],
    mode: 'hybrid',
    intent,
  };
}

function setupChatbot(app, pool) {
  const provider = resolveAiProvider();
  const chatMode = resolveChatbotMode();
  if (provider === 'rule' || chatMode === 'rule') {
    console.log('[chatbot] rule-based — thêm GEMINI_API_KEY vào backend/.env (không phải .env.example)');
  } else {
    const keyName = provider === 'openai' ? 'OPENAI_API_KEY' : 'GEMINI_API_KEY';
    const key = process.env[keyName];
    if (!key?.trim()) {
      console.warn(`[chatbot] ${keyName} trống trong backend/.env`);
    } else {
      console.log(
        `[chatbot] ${chatMode === 'hybrid' ? 'hybrid' : 'full'} AI: ${provider} (model: ${process.env[provider === 'openai' ? 'OPENAI_MODEL' : 'GEMINI_MODEL'] || 'default'})`,
      );
    }
  }
  const trainingFile = process.env.CHATBOT_TRAINING_FILE || 'chatbot-training.txt';
  const sections = Object.keys(loadTrainingSections());
  console.log(`[chatbot] training: ${trainingFile} (${sections.length ? sections.join(', ') : 'no sections'})`);

  app.get('/chatbot/suggestions', (_req, res) => {
    res.json({ suggestions: loadSuggestions() });
  });

  app.get('/chatbot/prompt-preview', async (req, res) => {
    try {
      const message = String(req.query.message ?? 'giá iphone').trim();
      const products = await loadProducts(pool);
      res.json(buildPromptPreview(message, products));
    } catch (err) {
      console.error('chatbot prompt-preview:', err);
      res.status(500).json({ message: err.message, code: 'CHATBOT_PREVIEW_ERROR' });
    }
  });

  app.post('/chatbot/ask', async (req, res) => {
    try {
      const message = String(req.body?.message ?? '').trim();
      const history = Array.isArray(req.body?.history)
        ? req.body.history
            .filter((item) => item && typeof item.text === 'string')
            .map((item) => ({
              role: item.role === 'assistant' ? 'assistant' : 'user',
              text: String(item.text).trim(),
            }))
            .filter((item) => item.text)
        : [];

      const products = await loadProducts(pool);
      let result;
      let mode = 'rule';
      let aiWarning;

      try {
        result = await answerHybrid(message, products, history);
        mode = result.mode ?? mode;
      } catch (aiErr) {
        const code = classifyAiError(aiErr);
        console.error(`[chatbot] AI lỗi (${code}):`, aiErr.message.slice(0, 400));
        console.error(`[chatbot] ${aiErrorHint(code)}`);
        result = answerForIntent(classifyIntentRule(message, products), message, products);
        mode = 'rule-fallback';
        aiWarning = aiErrorHint(code);
      }

      res.json({
        reply: result.reply.replace(/\*\*/g, ''),
        suggestStaff: Boolean(result.suggestStaff),
        productIds: result.productIds ?? [],
        mode,
        intent: result.intent ?? classifyIntentRule(message, products),
        ...(aiWarning ? { aiWarning } : {}),
      });
    } catch (err) {
      console.error('chatbot error:', err);
      res.status(500).json({ message: err.message, code: 'CHATBOT_ERROR' });
    }
  });
}

module.exports = { setupChatbot };
