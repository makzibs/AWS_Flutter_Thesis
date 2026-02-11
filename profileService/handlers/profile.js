'use strict';
const ProfileModel = require('../models/profileModel');
const { S3Client, PutObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const crypto = require('crypto');

const s3Client = new S3Client({ region: 'eu-north-1' });
const BUCKET_NAME = process.env.BUCKET_NAME || 'myapp-user-media-eu-north-1';

const getUserIdFromJwt = (event) => {
  return event?.requestContext?.authorizer?.jwt?.claims?.sub || null;
};

const signGetUrl = async (key) => {
  if (!key) return '';
  const cmd = new GetObjectCommand({ Bucket: BUCKET_NAME, Key: key });
  return await getSignedUrl(s3Client, cmd, { expiresIn: 3600 });
};

module.exports.create = async (event) => {
  try {
    const userId = getUserIdFromJwt(event);
    if (!userId) {
      return { statusCode: 401, body: JSON.stringify({ error: 'Unauthorized' }) };
    }

    const { fullName, bio, hobbies, profilePictureKey, carouselImageKeys } = JSON.parse(event.body || '{}');

    const profile = new ProfileModel(
      userId,
      fullName,
      bio,
      hobbies,
      profilePictureKey,
      carouselImageKeys
    );
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
      const profilePictureKey = profile.profilePictureKey || '';
      const carouselImageKeys = Array.isArray(profile.carouselImageKeys) ? profile.carouselImageKeys : [];
      const profilePictureUrl = profilePictureKey ? await signGetUrl(profilePictureKey) : '';
      const carouselImageUrls = await Promise.all(carouselImageKeys.map(signGetUrl));
      return {
        statusCode: 200,
        body: JSON.stringify({
          ...profile,
          profilePictureUrl,
          carouselImageUrls,
        }),
      };
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

module.exports.getUploadUrl = async (event) => {
  try {
    const userId = getUserIdFromJwt(event);
    if (!userId) {
      return { statusCode: 401, body: JSON.stringify({ error: 'Unauthorized' }) };
    }

    const { type, contentType } = JSON.parse(event.body || '{}');

    if (!type || !['avatar', 'carousel'].includes(type)) {
      return { statusCode: 400, body: JSON.stringify({ error: 'Invalid type' }) };
    }

    const safeContentType = (contentType && contentType.startsWith('image/'))
      ? contentType
      : 'image/jpeg';

    const ext = safeContentType.split('/')[1] || 'jpg';
    const fileId = crypto.randomUUID();

    const key = `users/${userId}/${type}/${fileId}.${ext}`;

    const cmd = new PutObjectCommand({
      Bucket: BUCKET_NAME,
      Key: key,
      ContentType: safeContentType,
    });

    const uploadUrl = await getSignedUrl(s3Client, cmd, { expiresIn: 300 });

    return {
      statusCode: 200,
      body: JSON.stringify({ uploadUrl, key, contentType: safeContentType }),
    };
  } catch (error) {
    return { statusCode: 500, body: JSON.stringify({ error: error.message }) };
  }
};