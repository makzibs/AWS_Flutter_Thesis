'use strict';
const ProfileModel = require('../models/profileModel');

const getUserIdFromJwt = (event) => {
  return event?.requestContext?.authorizer?.jwt?.claims?.sub || null;
};

module.exports.create = async (event) => {
  try {
    const userId = getUserIdFromJwt(event);
    if (!userId) {
      return { statusCode: 401, body: JSON.stringify({ error: 'Unauthorized' }) };
    }

    const { fullName, bio, hobbies } = JSON.parse(event.body || '{}');
    const profile = new ProfileModel(userId, fullName, bio, hobbies);
    const newProfile = await profile.create();

    return { statusCode: 201, body: JSON.stringify(newProfile) };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Could not create the profile.', details: error.message }),
    };
  }
};

module.exports.get = async (event) => {
  try {
    const userId = getUserIdFromJwt(event);
    if (!userId) {
      return { statusCode: 401, body: JSON.stringify({ error: 'Unauthorized' }) };
    }

    const profile = await ProfileModel.get(userId);

    if (profile) {
      return { statusCode: 200, body: JSON.stringify(profile) };
    } else {
      return { statusCode: 404, body: JSON.stringify({ error: 'Profile not found.' }) };
    }
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Could not retrieve the profile.', details: error.message }),
    };
  }
};

module.exports.update = async (event) => {
  try {
    const userId = getUserIdFromJwt(event);
    if (!userId) {
      return { statusCode: 401, body: JSON.stringify({ error: 'Unauthorized' }) };
    }

    const dataToUpdate = JSON.parse(event.body || '{}');
    const updatedProfile = await ProfileModel.update(userId, dataToUpdate);

    return { statusCode: 200, body: JSON.stringify(updatedProfile) };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Could not update the profile.', details: error.message }),
    };
  }
};