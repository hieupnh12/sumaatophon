const { PayOS } = require('@payos/node');

const DEFAULT_PUBLIC_BASE_URL = 'https://maclenin.io.vn/mobile';

let payosClient;

function getPublicBaseUrl() {
  return (process.env.PUBLIC_API_BASE_URL || DEFAULT_PUBLIC_BASE_URL).replace(/\/$/, '');
}

function isPayOsConfigured() {
  return Boolean(
    process.env.PHONESHOP_PAYOS_CLIENT_ID &&
      process.env.PHONESHOP_PAYOS_API_KEY &&
      process.env.PHONESHOP_PAYOS_CHECKSUM_KEY,
  );
}

function getPayOsClient() {
  if (!isPayOsConfigured()) {
    return null;
  }

  if (!payosClient) {
    payosClient = new PayOS({
      clientId: process.env.PHONESHOP_PAYOS_CLIENT_ID,
      apiKey: process.env.PHONESHOP_PAYOS_API_KEY,
      checksumKey: process.env.PHONESHOP_PAYOS_CHECKSUM_KEY,
    });
  }

  return payosClient;
}

function buildReturnUrl(orderId) {
  const base = process.env.PAYOS_RETURN_URL || `${getPublicBaseUrl()}/payment/success`;
  const separator = base.includes('?') ? '&' : '?';
  return `${base}${separator}orderId=${orderId}`;
}

function buildCancelUrl(orderId) {
  const base = process.env.PAYOS_CANCEL_URL || `${getPublicBaseUrl()}/payment/cancel`;
  const separator = base.includes('?') ? '&' : '?';
  return `${base}${separator}orderId=${orderId}`;
}

function getPayOsWebhookUrl() {
  return `${getPublicBaseUrl()}/api/payments/payos/webhook`;
}

async function createPaymentLink({ orderId, amount, description }) {
  const payos = getPayOsClient();
  if (!payos) {
    const error = new Error('PayOS is not configured on server');
    error.code = 'PAYOS_NOT_CONFIGURED';
    throw error;
  }

  const orderCode = Number(orderId);
  if (!Number.isInteger(orderCode) || orderCode <= 0) {
    throw new Error('Invalid PayOS orderCode');
  }

  const safeDescription = String(description || `Don hang ${orderId}`)
    .replace(/[^\w\sÀ-ỹ]/gi, '')
    .trim()
    .slice(0, 25) || `DH ${orderId}`;

  const paymentLink = await payos.paymentRequests.create({
    orderCode,
    amount: Number(amount),
    description: safeDescription,
    returnUrl: buildReturnUrl(orderId),
    cancelUrl: buildCancelUrl(orderId),
  });

  return {
    checkoutUrl: paymentLink.checkoutUrl,
    qrCode: paymentLink.qrCode ?? null,
    paymentLinkId: String(paymentLink.paymentLinkId ?? orderCode),
    orderCode,
  };
}

async function verifyWebhook(body) {
  const payos = getPayOsClient();
  if (!payos) {
    return { valid: false, data: null };
  }

  try {
    const verified = await payos.webhooks.verify(body);
    return { valid: true, data: verified };
  } catch (_) {
    return { valid: false, data: null };
  }
}

async function fetchPaymentRequest(orderId) {
  const payos = getPayOsClient();
  if (!payos) {
    return null;
  }

  return payos.paymentRequests.get(Number(orderId));
}

module.exports = {
  isPayOsConfigured,
  getPayOsClient,
  createPaymentLink,
  verifyWebhook,
  fetchPaymentRequest,
  buildReturnUrl,
  buildCancelUrl,
  getPublicBaseUrl,
  getPayOsWebhookUrl,
};
