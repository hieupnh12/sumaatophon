const RECEIPT_TAG = 'receiptEmail:';

/**
 * orders.note lưu nội bộ: address | shippingMethod | deliveryType | paymentMethod | userNote [| receiptEmail:...]
 * Chỉ trả userNote cho UI; metadata giữ trong DB phục vụ email/admin.
 */
function parseStoredOrderNote(rawNote) {
  if (!rawNote || typeof rawNote !== 'string') {
    return {
      address: '',
      shippingMethod: '',
      deliveryType: '',
      paymentMethod: '',
      userNote: '',
    };
  }

  const parts = rawNote
    .split('|')
    .map((part) => part.trim())
    .filter((part) => part && !part.toLowerCase().startsWith(RECEIPT_TAG.toLowerCase()));

  const [
    address = '',
    shippingMethod = '',
    deliveryType = '',
    paymentMethod = '',
    ...rest
  ] = parts;

  return {
    address,
    shippingMethod,
    deliveryType,
    paymentMethod,
    userNote: rest.join(' | ').trim(),
  };
}

/** Địa chỉ hiển thị: giao tận nhà → địa chỉ đã chọn lúc checkout; nhận tại cửa hàng → địa chỉ KH trong DB. */
function resolveOrderCustomerAddress(customerAddressFromDb, parsedNote) {
  if (parsedNote.deliveryType === 'homeDelivery' && parsedNote.address) {
    return parsedNote.address;
  }
  return customerAddressFromDb || '';
}

module.exports = {
  parseStoredOrderNote,
  resolveOrderCustomerAddress,
};
