const AppError = require("../utils/AppError");
const addressModel = require("../models/address.model");

async function listAddresses(userId) {
  const addresses = await addressModel.findAddressesByUser(userId);
  return { addresses };
}

async function getAddress(userId, addressId) {
  const address = await addressModel.findAddressById(addressId);
  if (!address || address.user_id !== userId) {
    throw new AppError("Address not found", 404, "NOT_FOUND");
  }
  return { address };
}

async function createAddress(userId, body) {
  if (body.is_default) {
    await addressModel.setDefaultAddress(userId, "00000000-0000-0000-0000-000000000000"); // unset all
  }

  const address = await addressModel.insertAddress({
    userId,
    label: body.label,
    fullName: body.full_name,
    phone: body.phone,
    addressLine1: body.address_line1,
    addressLine2: body.address_line2,
    city: body.city,
    district: body.district,
    postalCode: body.postal_code,
    country: body.country,
    isDefault: body.is_default || false,
  });

  return { address };
}

async function updateAddress(userId, addressId, body) {
  const existing = await addressModel.findAddressById(addressId);
  if (!existing || existing.user_id !== userId) {
    throw new AppError("Address not found", 404, "NOT_FOUND");
  }

  const updated = await addressModel.updateAddress(addressId, body);
  if (!updated) {
    throw new AppError("No fields to update", 400, "VALIDATION_ERROR");
  }

  if (body.is_default) {
    await addressModel.setDefaultAddress(userId, addressId);
  }

  return { address: updated };
}

async function deleteAddress(userId, addressId) {
  const existing = await addressModel.findAddressById(addressId);
  if (!existing || existing.user_id !== userId) {
    throw new AppError("Address not found", 404, "NOT_FOUND");
  }
  await addressModel.deleteAddress(addressId);
}

module.exports = {
  listAddresses,
  getAddress,
  createAddress,
  updateAddress,
  deleteAddress,
};
